//
// Clean and filter assembly
//

include { EVIDENCEMODELER_PARTITION } from '../../modules/local/evidencemodeler/partition'

workflow EVM {
    take:
    genome // file: /path/to/samplesheet.csv
    genes_gff
    proteins_gff
    transcripts_gff
    evm_config

    main:
       	
    EVIDENCEMODELER_PARTITION(
       genome,
       genes_gff,
       proteins_gff.ifEmpty(false),
       transcripts_gff.ifEmpty(false),
       evm_config
    )
    EVIDENCEMODELER_EXECUTE(
        EVIDENCEMODELER_PARTITION.out.partition.splitText(by: params.nevm, file: true)
    )
    
    emit:
    versions = EVIDENCEMODELER_PARTITION.out.versions
}

def create_genome_channel(genome) {
    def meta = [:]
    meta.id           = file(genome).getSimpleName()

    def array = [ meta, genome ]

    return array
}
