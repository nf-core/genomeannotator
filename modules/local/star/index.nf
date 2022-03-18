process STAR_INDEX {
    tag "$meta.id"
    label 'process_long'
    
    conda (params.enable_conda ? "bioconda::star=2.6.1d bioconda::samtools=1.10 conda-forge::gawk=5.1.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:59cdd445419f14abac76b31dd0d71217994cbcc9-0' :
        'quay.io/biocontainers/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:59cdd445419f14abac76b31dd0d71217994cbcc9-0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path(star_dir), emit: star_index
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    star_dir = meta.id + "_star"
    """
    samtools faidx $fasta
    NUM_BASES=`gawk '{sum = sum + \$2}END{if ((log(sum)/log(2))/2 - 1 > 14) {printf "%.0f", 14} else {printf "%.0f", (log(sum)/log(2))/2 - 1}}' ${fasta}.fai`
	
    mkdir -p $star_dir
    STAR --runThreadN ${task.cpus} \
       --runMode genomeGenerate \
       --genomeDir $star_dir \
       --genomeFastaFiles $fasta \
       --limitGenomeGenerateRAM ${task.memory.toBytes()} \
       --genomeSAindexNbases \$NUM_BASES 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(echo \$(STAR --version | sed -e "s/STAR_//g")
    END_VERSIONS
    """
}
