process HELPER_MINIMAPTOHINTS {
    tag "$meta.id"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::multiqc=1.12" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.12--pyhdfd78af_0':
        'quay.io/biocontainers/multiqc:1.12--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(gff)
    val(source_key)
    val(priority)

    output:
    path("*.hints.gff"), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def hints = prefix + ".hints.gff"
    """
    minimap2hints.pl --src $source_key --source est2genome --pri $priority --infile $gff --outfile $hints

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        helper: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
