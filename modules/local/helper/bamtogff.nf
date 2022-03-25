process HELPER_BAMTOGFF {
    tag "$meta.id"
    label 'process_medium'
    
    conda (params.enable_conda ? "bioconda::nanovar:1.4.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanovar:1.4.1--py39h38f01e4_0':
        'quay.io/biocontainers/nanovar:1.4.1--py39h38f01e4_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.gff"), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    gff = bam.getBaseName() + ".gff"
    """
    bam2gff.pl $bam > $gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bam2gff: ${workflow.manifest.version}
    END_VERSIONS
    """
}
