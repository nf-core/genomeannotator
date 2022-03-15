process EXONERATE_FASTACLEAN {
    tag "$meta.id"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::exonerate=2.4.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/exonerate:2.4.0--hb9dd440_2':
        'quay.io/biocontainers/exonerate:2.4.0--hb9dd440_2' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path(fasta_clean), emit: fasta
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    fasta_clean = fasta.getBaseName() + ".exclean.fasta"
    """
    fastaclean -f $fasta -p | sed "s/:filter(clean)//" | sed "s/ pep .*//" > $fasta_clean
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastaclean: \$(echo \$(fastaclean -h | head -n1 | cut -f5 -d " " ))
    END_VERSIONS
    """
}
