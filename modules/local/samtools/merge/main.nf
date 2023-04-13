process SAMTOOLS_MERGE {
    tag "$meta.id"
    label 'process_high'
    
    conda (params.enable_conda ? "bioconda::samtools=1.14" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.14--hb421002_0':
        'quay.io/biocontainers/samtools:1.14--hb421002_0' }"

    input:
    tuple val(meta),path(bams)

    output:
    tuple val(meta), path(merged_bam), emit: bam
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    merged_bam = prefix + ".merged.bam"
    """
    samtools merge \
        $args \
        -@ ${task.cpus} \
        -o ${merged_bam} \
        -O BAM \
        $bams

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
