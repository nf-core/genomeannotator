process SPALN_TO_GMOD {
    tag "$spaln_models"

    conda (params.enable_conda ? "bioconda::spaln=2.4.7" : null)
    container "quay.io/biocontainers/spaln:2.4.7--pl5321h9a82719_1"

    input:
    path spaln_models

    output:
    path spaln_track, emit: gff

    script: // This script is bundled with the pipeline, in nf-core/esga/bin/
    spaln_track = spaln_models.getBaseName() + ".gmod.gff3"

    """
        spaln2gmod.pl --infile $spaln_models > $spaln_track

    """
}
