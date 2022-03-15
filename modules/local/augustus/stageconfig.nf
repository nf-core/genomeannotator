process AUGUSTUS_STAGECONFIG {
    tag "${augustus_config_dir}"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::augustus=3.4.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/augustus:3.4.0--pl5262h5a9fe7b_2':
        'quay.io/biocontainers/augustus:3.4.0--pl5262h5a9fe7b_2' }"

    input:
    path augustus_config_dir

    output:
    path "augustus_config", emit: config_dir
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    
    """
    mkdir -p augustus_config
    cp -R $augustus_config_dir/* augustus_config/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        augustus: \$(echo \$(augustus  | head -n1 | cut -f2 -d " " | sed "s/[)]//" | sed "s/[(]//" ))
    END_VERSIONS
    """
}
