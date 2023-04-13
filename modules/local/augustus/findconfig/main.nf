process AUGUSTUS_FINDCONFIG {
    tag 'STAGING...'
    label 'process_low'

    conda (params.enable_conda ? "bioconda::augustus=3.4.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/augustus:3.4.0--pl5321hd8b735c_4':
        'quay.io/biocontainers/augustus:3.4.0--pl5321hd8b735c_4' }"

    input:
    path dummy

    output:
    path "config", emit: config
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    """
    touch test.fa
    cp -R `augustus --species=caenorhabditis test.fa 2>/dev/null | grep "using config directory" | cut -f8 -d " "` config

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        augustus: \$(echo \$(augustus  | head -n1 | cut -f2 -d " " | sed "s/[)]//" | sed "s/[(]//" ))
    END_VERSIONS
    """
}
