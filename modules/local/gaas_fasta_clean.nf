process GAAS_FASTA_CLEAN {
    tag "$fa"

    conda (params.enable_conda ? "bioconda::gaas:1.2.0" : null)
    container 'quay.io/biocontainers/gaas:1.2.0--pl526r35_0'

    input:
    path fa

    output:
    path fasta_clean       , emit: fasta

    script: // This script is bundled with the pipeline, in nf-core/esga/bin/
    fasta_clean = fa.getBaseName() + ".clean"
    """
       sed 's/[.]\$//' $fa > cleaned.fa
       gaas_fasta_cleaner.pl -f cleaned.fa -o $fasta_clean
       rm cleaned.fa
    """
}
