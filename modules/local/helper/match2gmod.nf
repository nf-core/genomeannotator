process HELPER_MATCH2GMOD {
    tag "$meta.id"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::perl-bioperl=1.7.8" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl-bioperl:1.7.2--pl526_11':
        'quay.io/biocontainers/perl-bioperl:1.7.2--pl526_11' }"

    input:
    tuple val(meta), path(gff)

    output:
    tuple val(meta), path(gmod_track), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    gmod_track = prefix + ".gmod.gff3"
    """
    match2track.pl --infile $gff > $gmod_track

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        helper: 1.0
    END_VERSIONS
    """
}
