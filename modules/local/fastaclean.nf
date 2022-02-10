process FASTACLEAN {
    tag "$fa"

    conda (params.enable_conda ? "bioconda::exonerate:2.4.0" : null)
    container 'quay.io/biocontainers/exonerate:2.4.0--h7c8e0dd_4'

    input:
    path fa

    output:
    path fasta_clean       , emit: fasta

    script: // This script is bundled with the pipeline, in nf-core/esga/bin/
    fasta_clean = fa.getBaseName() + ".purged.fa"
    """
       fastaclean -f $fa -p | sed 's/:filter(clean)//' | sed 's/ pep .*//' > $fasta_clean
    """
}
