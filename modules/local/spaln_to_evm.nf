process SPALN_TO_EVM {

    input:
    path spaln_models

    output:
    path spaln_evm, emit: gff

    script:
    spaln_evm = spaln_models.getBaseName() + ".evm.gff3"

    """
      spaln2evm.pl --infile $spaln_models > $spaln_evm

    """
}
