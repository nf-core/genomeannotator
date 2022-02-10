process FASTA_CLEAN_NAMES {
    tag "$fa"

    conda (params.enable_conda ? "conda-forge::python=3.8.3" : null)
    container 'ikmb/esga:1.3'

    input:
    path fa

    output:
    path fasta_clean       , emit: fasta

    script: // This script is bundled with the pipeline, in nf-core/esga/bin/
    fasta_clean = fa.getBaseName() + ".clean"
    """
	sed 's/ .*//' $fa > $fasta_clean
    """
}
