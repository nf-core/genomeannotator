process REPEATMASKER {
    tag "$fa"

    container 'quay.io/biocontainers/repeatmasker:4.1.2-p1'

    input:
    path fa
    env REPEATMASKER_LIB_DIR
    path rm_lib

    output:
    path genome_rm       , emit: rm_fa
    path rm_gff          , emit: rm_gff
    path "versions.yml", emit: versions

    script: // This script is bundled with the pipeline, in nf-core/esga/bin/
    base_name = fa.getName()
    genome_rm = base_name + ".masked"
    rm_gff = base_name + ".out.gff"
    rm_tbl = base_name + ".tbl"
    rm_out = base_name + ".out"
    """
    RepeatMasker -lib $rm_lib -gff -xsmall -q -nolow -pa ${task.cpus} $fa
                test -f ${genome_rm} || cp $fa $genome_rm && touch $rm_gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        RepeatMasker: \$( RepeatMasker -v )
    END_VERSIONS
    """
}
