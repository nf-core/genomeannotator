process GAAS_FASTAFILTERBYSIZE {
    tag "$meta.id"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::gaas=1.2.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gaas:1.2.0--pl526r35_0':
        'quay.io/biocontainers/gaas:1.2.0--pl526r35_0' }"

    input:
    tuple val(meta),path(fasta)
    val min_size

    output:
    tuple val(meta),path(filtered), emit: fasta
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    filtered = fasta.getBaseName() + ".filtered.fa"
    """
    gaas_fasta_filter_by_size.pl -f $fasta -s $min_size -o $filtered

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gaas: 1.2.0
    END_VERSIONS
    """
}
