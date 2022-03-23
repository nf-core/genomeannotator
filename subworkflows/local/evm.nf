//
// Clean and filter assembly
//

include { EVIDENCEMODELER_MERGE } from '../../modules/local/evidencemodeler/merge'
include { EVIDENCEMODELER_PARTITION } from '../../modules/local/evidencemodeler/partition'
include { EVIDENCEMODELER_EXECUTE } from '../../modules/local/evidencemodeler/execute'
include { HELPER_EVM2GFF } from '../../modules/local/helper/evm2gff'
include { GFFREAD as EVIDENCEMODELER_GFF2PROTEINS } from '../../modules/local/gffread'

workflow EVM {

    take:
    genome
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
       params.evm_weights
    )
    EVIDENCEMODELER_EXECUTE(
        EVIDENCEMODELER_PARTITION.out.commands.splitText(by: params.nevm, file: true)
    )
    
    EVIDENCEMODELER_MERGE(
       EVIDENCEMODELER_PARTITION.out.partitions,
       EVIDENCEMODELER_EXECUTE.out.log.groupTuple(by: [0]),
       genome.collect()
    )
    HELPER_EVM2GFF(
       EVIDENCEMODELER_MERGE.out.partitions
    )
    EVIDENCEMODELER_GFF2PROTEINS(
       HELPER_EVM2GFF.out.gff.join(genome)
    )
       
    emit:
    proteins = EVIDENCEMODELER_GFF2PROTEINS.out.proteins
    versions = EVIDENCEMODELER_PARTITION.out.versions

}
