process AUGUSTUS_AUGUSTUSBATCH {
    tag "$meta.id"
    label 'process_high'
    
    conda (params.enable_conda ? "bioconda::augustus=3.4.0 bioconda::exonerate=2.4.0 bioconda::samtools=1.14" : null)
    container 'ikmb/esga:aug_1.3'

    input:
    tuple val(meta), path(genome)
    path(hints)
    env AUGUSTUS_CONFIG_PATH
    path aug_config
    val aug_chunk_length
    val aug_species

    output:
    tuple val(meta), path(augustus_result), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    chunk_name = genome.getName().tokenize("_")[-1]
    augustus_result = "augustus.${chunk_name}.out.gff"

    """
    samtools faidx $genome
    fastaexplode -f $genome -d .
    augustus_from_chunks.pl --chunk_length $aug_chunk_length --genome_fai ${genome}.fai --model $aug_species --utr false --options '${args}' --aug_conf ${aug_config} --hints $hints > commands.txt
    parallel -j ${task.cpus} < commands.txt
    for i in \$(ls *.out | sort -n); do echo \$i >> files.txt ; done;
    joingenes -f files.txt -o ${augustus_result}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        augustus: \$(echo \$(augustus  | head -n1 | cut -f2 -d " " | sed "s/[)]//" | sed "s/[(]//" ))
    END_VERSIONS
    """
}
