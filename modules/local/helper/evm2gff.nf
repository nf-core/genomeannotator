process HELPER_EVM2GFF {
    tag "$meta.id"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::perl-bioperl=1.7.8" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl-bioperl:1.7.2--pl526_11':
        'quay.io/biocontainers/perl-bioperl:1.7.2--pl526_11' }"

    input:
    tuple val(meta), path(partitions)

    output:
    tuple val(meta), path("*.gff3"), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def gff = prefix + ".evm.gff3"
    """
    merge_evm_gff.pl --partitions $partitions --gff $gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        helper: ${workflow.manifest.version}
    END_VERSIONS
    """
}
