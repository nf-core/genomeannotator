process SPALN_MERGE {

    conda (params.enable_conda ? "bioconda::spaln=2.4.7" : null)
    container "quay.io/biocontainers/spaln:2.4.7--pl5321h9a82719_1"

    input:
    path spaln_reports
    path spaln_index
    val similarity

    output:
    path spaln_final, emit: gff

    script:
    spaln_final = spaln_reports[0].getBaseName() + ".merged.${similarity}.final.gff"

    """
       sortgrcd  -I${similarity} -O0 -n0 *.grd > merged.gff
       spaln_add_exons.pl --infile merged.gff > $spaln_final
       rm merged.gff
    """
}
