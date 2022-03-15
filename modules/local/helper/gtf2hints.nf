process HELPER_GTF2HINTS {
    tag "$meta.id"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::perl-bioperl=1.7.8" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl-bioperl:1.7.2--pl526_11':
        'quay.io/biocontainers/perl-bioperl:1.7.2--pl526_11' }"

    input:
    tuple val(meta), path(gtf)
    val(pri)

    output:
    path("*.gff"), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}-${meta.target}"
    def gff = prefix + ".kraken_hints.gff"
    """
    gtf2hints.pl --gtf $gtf --pri $pri --source T > $gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        helper: 1.0
    END_VERSIONS
    """
}
