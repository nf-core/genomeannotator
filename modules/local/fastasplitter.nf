process FASTASPLITTER {
    tag "$meta.id - $fasta"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::multiqc:1.12" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.12--pyhdfd78af_0':
        'quay.io/biocontainers/multiqc:1.12--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)
    val(fsize) // size of fasta chunks to produce

    output:
    tuple val(meta), path("*.part-*.*"), emit: chunks
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
       fasta-splitter.pl -part-sequence-size $fsize $fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastasplitter: \$(echo \$(fasta-splitter.pl -v | head -n1 | cut -f3 -d " "))
    END_VERSIONS
    """
}
