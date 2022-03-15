process EVIDENCEMODELER_EXECUTE {
    tag "$meta.id"
    label 'process_high'
    
    conda (params.enable_conda ? "bioconda::evidencemodeler=1.1.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/evidencemodeler:1.1.1--hdfd78af_3':
        'quay.io/biocontainers/evidencemodeler:1.1.1--hdfd78af_3' }"

    input:
    tuple val(meta), path(partition)

    output:
    tuple val(meta), path(log_file), emit: log
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    log_file = partition.getBaseName() + ".log"
    """
    /usr/local/opt/evidencemodeler-1.1.1/EvmUtils/execute_EVM_commands.pl $partition | tee $log_file

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        evidencemodeler: 1.1.0
    END_VERSIONS
    """
}
