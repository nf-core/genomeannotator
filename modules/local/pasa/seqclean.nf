process PASA_SEQCLEAN {
    tag "$meta.id"
    label 'process_medium'
    
    if (params.enable_conda) {
        exit 1, "Conda environments cannot be used when using this version of PASA. Please use docker or singularity containers."
    }
    container 'pasapipeline/pasapipeline:2.5.2'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta),path(fasta),path("*.clean"),path("*.cln"), emit: fasta
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // Seqclean won't work inside container if the username is not exported to USER
    """
    export USER=${workflow.userName}
    seqclean $fasta -c ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pasa: 2.4.1
    END_VERSIONS
    """
}
