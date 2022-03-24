process BUSCO_DOWNLOADDB {
    //tag busco_tax
    label 'process_low'

    conda (params.enable_conda ? "bioconda::busco=5.3.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/busco:5.3.0--pyhdfd78af_0':
        'quay.io/biocontainers/busco:5.3.0--pyhdfd78af_0' }"

    input:
    val(busco_tax)

    output:
    tuple val(lineage_folder),path ("busco_downloads"), emit: busco_lineage_dir
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    lineage_folder = "busco_downloads/lineages/${busco_tax}"
 
    """

    busco --download $busco_tax

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        busco: \$(echo \$(wget --version 2>&1) | cut -f3 -d " " ))
    END_VERSIONS
    """
}
