process BUSCO_BUSCO {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::busco=5.3.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/busco:5.3.0--pyhdfd78af_0':
        'quay.io/biocontainers/busco:5.3.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(proteins)
    tuple val(lineage_path),path(db)

    output:
    path(busco_summary), emit: summary
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    busco_summary = "short_summary_" + proteins.getBaseName() + ".txt"
    def options = ""
    if (!lineage_path.contains("/") ) {
       options = "--download_path $db"
    }
    """

    busco -m proteins -i $proteins $options -l $lineage_path -o busco -c ${task.cpus} --offline
    cp busco/short_summary*specific*busco.txt $busco_summary

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        busco: \$(echo \$(busco -version 2>&1) | cut -f2 -d " " ))
    END_VERSIONS
    """
}
