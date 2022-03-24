process HELPER_CREATEGFFIDS {
    //tag "$meta.id"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::perl-bioperl=1.7.8" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl-bioperl:1.7.2--pl526_11':
        'quay.io/biocontainers/perl-bioperl:1.7.2--pl526_11' }"

    input:
    tuple val(meta), path(gff)

    output:
    tuple val(meta), path("*.stable_id.gff"), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    updated_gff = gff.getBaseName() + ".stable_id.gff"
    """
    create_gff_ids.pl --gff $gff > $updated_gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        helper: ${workflow.manifest.version}
    END_VERSIONS
    """
}
