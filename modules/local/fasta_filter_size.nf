process FASTA_FILTER_SIZE {
    tag "$fasta"

    conda (params.enable_conda ? "bioconda::gaas=1.2.0" : null)
    container "quay.io/biocontainers/gaas:1.2.0--pl526r35_0"

    input:
    path fasta

    output:
    path fasta_filtered       , emit: fasta

    script: // This script is bundled with the pipeline, in nf-core/esga/bin/
    fasta_filtered = fasta.getBaseName() + "." + params.min_contig_size + ".fa"
    """
       gaas_fasta_filter_by_size.pl -f $fasta -s ${params.min_contig_size} -o $fasta_filtered

    """
}
