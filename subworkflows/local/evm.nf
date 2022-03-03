//
// Clean and filter assembly
//

include { EVIDENCEMODELER_MERGE } from '../../modules/local/evidencemodeler/merge'
include { EVIDENCEMODELER_PARTITION } from '../../modules/local/evidencemodeler/partition'
include { EVIDENCEMODELER_EXECUTE } from '../../modules/local/evidencemodeler/execute'


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
       proteins_gff,
       transcripts_gff,
       evm_config
    )
    EVIDENCEMODELER_EXECUTE(
        EVIDENCEMODELER_PARTITION.out.commands.splitText(by: params.nevm, file: true)
    )
    
    EVIDENCEMODELER_MERGE(
       EVIDENCEMODELER_PARTITION,out.partitions.collect(),
       EVIDENCEMODELER_EXECUTE.out.log.collect(),
       genome.collect()
    )
    
    emit:
    versions = EVIDENCEMODELER_PARTITION.out.versions
}
