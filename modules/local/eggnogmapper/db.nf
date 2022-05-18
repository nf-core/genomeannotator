process EGGNOGMAPPER_DB {
    tag "$meta.id"
    label 'process_long'

    conda (params.enable_conda ? "eggnog-mapper=2.1.7" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eggnog-mapper:2.1.7--pyhdfd78af_0 ':
        'quay.io/biocontainers/eggnog-mapper:2.1.7--pyhdfd78af_0 ' }"

    input:
    val(tax_id)

    output:
    path("db"), emit: db
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    mkdir -p db
    download_eggnog_data.py -d $tax_id --data_dir db -y

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eggnogmapper: \$(echo \$(emapper.py -v | tail -n1 | cut -f1 -d " " | sed 's/emapper-//' ))
    END_VERSIONS
    """
}
