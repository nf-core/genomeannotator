process CAT_GFF {
    tag "$meta.id"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::cat=5.2.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/cat:5.2.3--hdfd78af_1':
        'quay.io/biocontainers/cat:5.2.3--hdfd78af_1' }"

    input:
    tuple val(meta), path(gffs)

    output:
    tuple val(meta), path(merged_gff), emit: gff
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    merged_gff = prefix + ".augustus.gff"
    """
    cat $gffs > $merged_gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cat: \$(echo \$(cat --version 2>&1) | sed 's/^.*coreutils) //; s/ .*\$//')
    END_VERSIONS
    """
}
