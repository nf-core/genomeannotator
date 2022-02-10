process REPEATLIB_STAGE {
    tag "$repeat_lib"

    container 'quay.io/biocontainers/repeatmasker:4.1.2-p1'

    input:
    path repeat_lib

    output:
    path 'Library'       , emit: library

    script: // This script is bundled with the pipeline, in nf-core/esga/bin/
    """

       cp ${baseDir}/assets/repeatmasker/my_genome.fa .
                cp ${baseDir}/assets/repeatmasker/repeats.fa .
                mkdir -p Library
                cp ${baseDir}/assets/repeatmasker/DfamConsensus.embl Library/
                gunzip -c ${baseDir}/assets/repeatmasker/taxonomy.dat.gz > Library/taxonomy.dat
                export REPEATMASKER_LIB_DIR=\$PWD/Library
                RepeatMasker -lib $repeat_lib my_genome.fa > out

    """
}
