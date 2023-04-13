process INFERNAL_PRESS {
    tag '$cm_file'
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::infernal=1.1.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/infernal:1.1.4--h779adbc_0':
        'quay.io/biocontainers/infernal:1.1.4--h779adbc_0' }"

    input:
    path(cm_file)

    output:
    tuple path(cm_file),path("*.i1f"),path("*.i1i"),path("*.i1m"),path("*.i1p"), emit: cm
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    
    """
    cmpress $cm_file

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cmpress: \$(echo \$(cmsearch -h) | head -n2 | tail -n1  | cut -f3 -d " " ))
    END_VERSIONS
    """
}
