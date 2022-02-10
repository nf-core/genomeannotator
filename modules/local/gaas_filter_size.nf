process GAAS_FILTER_SIZE {
    tag "$fa"

    conda (params.enable_conda ? "bioconda::gaas:1.2.0" : null)
    container 'quay.io/biocontainers/gaas:1.2.0--pl526r35_0'

    input:
    path fa
    val min_len

    output:
    path fasta_filtered       , emit: fasta

    script: // This script is bundled with the pipeline, in nf-core/esga/bin/
    fasta_filtered = fa.getBaseName() + ".size_filtered.fa"
    """
       gaas_fasta_filter_by_size.pl -f $fa -s $min_len -o $fasta_filtered

    """
}
