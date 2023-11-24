process MINIPROT_INDEX {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::miniprot=0.12" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/miniprot:0.12--he4a0461_0 ':
        'quay.io/biocontainers/miniprot:0.12--he4a0461_0' }"

    input:
    tuple val(meta), path(genome)

    output:
    path("*.mpi")                 , emit: index
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def index = prefix + ".mpi"

    """
    miniprot -t${task.cpus} -d $index $genome

    cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            miniprot: \$(echo \$(minprot --version ))
        END_VERSIONS

    """

}
