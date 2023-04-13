//
// Clean and filter assembly
//

include { FASTASPLITTER } from '../../modules/local/fastasplitter'
include { AUGUSTUS_AUGUSTUSBATCH } from '../../modules/local/augustus/batch/main'
include { AUGUSTUS_FIXJOINGENES } from '../../modules/local/augustus/fixjoingenes/main'
include { HELPER_CREATEGFFIDS as AUGUSTUS_CREATEGFFIDS } from '../../modules/local/helper/creategffids'
include { GFFREAD as AUGUSTUS_GFF2PROTEINS } from '../../modules/local/gffread'
include { CAT_GFF as AUGUSTUS_MERGE_CHUNKS } from '../../modules/local/cat/gff'

ch_versions = Channel.from([])

workflow AUGUSTUS_PIPELINE {
    take:
    genome // file: /path/to/samplesheet.csv
    hints
    aug_config_folder
    aug_extrinsic_cfg

    main:

    FASTASPLITTER(
        genome,
        params.npart_size
    )

    // Splitter either outputs one file, or a list of files.
    FASTASPLITTER.out.chunks.branch { m,f ->
        single: f.getClass() != ArrayList
        multi: f.getClass() == ArrayList
    }.set { ch_fa_chunks }

    ch_versions = ch_versions.mix(FASTASPLITTER.out.versions)

    ch_fa_chunks.multi.flatMap { h,fastas ->
        fastas.collect { [ h,file(it)] }
    }.set { ch_chunks_split }

    AUGUSTUS_AUGUSTUSBATCH(
        ch_chunks_split.mix(ch_fa_chunks.single),
        hints.collect(),
        aug_config_folder.collect().map{ it[0].toString() },
        aug_extrinsic_cfg.collect(),
        params.aug_chunk_length,
        params.aug_species
    )

    ch_versions = ch_versions.mix(AUGUSTUS_AUGUSTUSBATCH.out.versions)

    AUGUSTUS_FIXJOINGENES(
        AUGUSTUS_AUGUSTUSBATCH.out.gff
    )

    AUGUSTUS_FIXJOINGENES.out.gff
    .multiMap { m,gff ->
        metadata: [m.id, m]
        gffs: [m.id,gff ]
    }.set { ch_gffs }

    ch_gffs.gffs.collectFile { mkey, file -> [ "${mkey}.augustus.gff", file ] }
    .map { file -> [ file.simpleName, file ] }
    .set { ch_merged_gffs }

    ch_gffs.metadata.join(
        ch_merged_gffs
    )
    .map { k,m,f -> tuple(m,f) }
    .set { ch_genome_gff }

    AUGUSTUS_CREATEGFFIDS(
        ch_genome_gff
    )
    AUGUSTUS_GFF2PROTEINS(
        AUGUSTUS_CREATEGFFIDS.out.gff.join(genome)
    )

    ch_func_annot = AUGUSTUS_GFF2PROTEINS.out.proteins.join(AUGUSTUS_CREATEGFFIDS.out.gff)

    emit:
    gff = AUGUSTUS_CREATEGFFIDS.out.gff
    proteins = AUGUSTUS_GFF2PROTEINS.out.proteins
    versions = ch_versions
    func_annot = ch_func_annot
}
