process MINIMAP2_ALIGN {
    tag "$meta_g.id | $meta.id"
    label 'process_high'
    
    conda (params.enable_conda ? "bioconda::nanovar:1.4.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanovar:1.4.1--py39h38f01e4_0':
        'quay.io/biocontainers/nanovar:1.4.1--py39h38f01e4_0' }"

    input:
    tuple val(meta), path(fasta)
    tuple val(meta_g),path(genome)
    val max_intron_size

    output:
    tuple val(meta), path("*.bam"), emit: bam
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def bam = fasta.getBaseName() + ".minimap2.bam"
    """
    samtools faidx $genome
    minimap2 -t ${task.cpus} --split-prefix tmp -ax splice:hq -c -G $max_intron_size $genome $fasta | samtools sort -@ ${task.cpus} -m 2G -O BAM -o $bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(echo \$(minimap2 --version ))
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
