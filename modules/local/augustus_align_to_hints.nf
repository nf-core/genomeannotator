process AUGUSTUS_ALIGN_TO_HINTS {

    conda (params.enable_conda ? "bioconda::augustus=3.4.0" : null)
    container "quay.io/biocontainers/augustus:3.4.0--pl5321hd8b735c_3"

    input:
    path gff
    val prog
    val max_intron_size
    val priority

    output:
    path hints, emit: gff

    script:
    hints = spaln_models.getBaseName() + ".hints.gff3"

    """
       align2hints.pl --in=$gff --maxintronlen=${max_intron_size} --prg=${prog} --priority=${priority} --out=$hints

    """
}
