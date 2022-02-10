process ASSEMBLY_STATS {
    tag "$fasta"

    conda (params.enable_conda ? "bioconda::gaas=1.2.0" : null)
    container "quay.io/biocontainers/gaas:1.2.0--pl526r35_0"

    input:
    path fasta

    output:
    path 'stats'       , emit: stats

    script: // This script is bundled with the pipeline, in nf-core/esga/bin/
    """
       gaas_fasta_statistics.pl -f $fasta -o stats
    """
}
