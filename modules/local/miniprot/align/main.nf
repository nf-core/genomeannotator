process MINIPROT_ALIGN {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::miniprot=0.12" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/miniprot:0.12--he4a0461_0 ':
        'quay.io/biocontainers/miniprot:0.12--he4a0461_0' }"

    input:
    tuple val(meta), path(proteins)
    path(index)

    output:
    path("*.gff3")                             , emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def gff = prefix + "-" + proteins.getBaseName() + ".gff3"

    """
    miniprot -t${task.cpus} --gff $index $proteins > $gff

    cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            miniprot: \$(echo \$(minprot --version ))
        END_VERSIONS

    """

}
