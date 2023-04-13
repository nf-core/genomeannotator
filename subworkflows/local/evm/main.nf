//
// Clean and filter assembly
//

include { EVIDENCEMODELER_MERGE } from '../../../modules/local/evidencemodeler/merge/main'
include { EVIDENCEMODELER_PARTITION } from '../../../modules/local/evidencemodeler/partition/main'
include { EVIDENCEMODELER_EXECUTE } from '../../../modules/local/evidencemodeler/execute/main'
include { HELPER_EVM2GFF } from '../../../modules/local/helper/evm2gff'
include { GFFREAD as EVIDENCEMODELER_GFF2PROTEINS } from '../../../modules/local/gffread'

ch_versions = Channel.from([])

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

    ch_versions = ch_versions.mix(EVIDENCEMODELER_PARTITION.out.versions)

    EVIDENCEMODELER_EXECUTE(
        EVIDENCEMODELER_PARTITION.out.commands.splitText(by: params.nevm, file: true)
    )

    ch_versions = ch_versions.mix(EVIDENCEMODELER_EXECUTE.out.versions)

    EVIDENCEMODELER_MERGE(
        EVIDENCEMODELER_PARTITION.out.partitions,
        EVIDENCEMODELER_EXECUTE.out.log.groupTuple(by: [0]),
        genome.collect()
    )

    ch_versions = ch_versions.mix(EVIDENCEMODELER_MERGE.out.versions)

    HELPER_EVM2GFF(
        EVIDENCEMODELER_MERGE.out.partitions
    )

    EVIDENCEMODELER_GFF2PROTEINS(
        HELPER_EVM2GFF.out.gff.join(genome)
    )

    ch_func_annot = HELPER_EVM2GFF.out.gff.join(EVIDENCEMODELER_GFF2PROTEINS.out.proteins)

    emit:
    proteins = EVIDENCEMODELER_GFF2PROTEINS.out.proteins
    versions = ch_versions
    func_annot = ch_func_annot

}
