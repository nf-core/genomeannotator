process GAAS_FASTASTATISTICS {
    tag "$meta.id"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::gaas=1.2.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gaas:1.2.0--pl526r35_0':
        'quay.io/biocontainers/gaas:1.2.0--pl526r35_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta),path("stats"), emit: stats
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    
    """
       gaas_fasta_statistics.pl -f $fasta -o stats

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gaas: 1.2.0
    END_VERSIONS
    """
}
