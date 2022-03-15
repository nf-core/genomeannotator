//
// Clean and filter assembly
//

include { GAAS_FASTACLEANER } from '../../modules/local/gaas/fastacleaner'

workflow FASTA_PREPROCESS {
    take:
    fasta // file: /path/to/samplesheet.csv

    main:
       	
    GAAS_FASTACLEANER(
       create_fasta_channel(fasta)
    )

    emit:
    fasta = GAAS_FASTACLEANER.out.fasta
    versions = GAAS_FASTACLEANER.out.versions
}


def create_fasta_channel(fasta) {
    def meta = [:]
    meta.id           = file(fasta).getSimpleName()

    def array = [ meta, fasta ]

    return array
}

