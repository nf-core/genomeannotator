//
// Clean and filter assembly
//

include { GAAS_FASTASTATISTICS } from '../../modules/local/gaas/fastastatistics'
include { GAAS_FASTAFILTERBYSIZE } from '../../modules/local/gaas/fastafilterbysize'

workflow ASSEMBLY_PREPROCESS {
    take:
    genome // file: /path/to/samplesheet.csv

    main:
	
    GAAS_FASTAFILTERBYSIZE(
       create_genome_channel(genome),
       params.min_contig_size
    )
    GAAS_FASTASTATISTICS(GAAS_FASTAFILTERBYSIZE.out.fasta)

    emit:
    fasta = GAAS_FASTAFILTERBYSIZE.out.fasta
    stats = GAAS_FASTASTATISTICS.out.stats
    versions = GAAS_FASTAFILTERBYSIZE.out.versions
}

def create_genome_channel(genome) {
    def meta = [:]
    meta.id           = file(genome).getSimpleName()

    def array = [ meta, genome ]

    return array
}
