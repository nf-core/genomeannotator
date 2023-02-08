//
// Check input samplesheet and get read channels
//

include { REPEATMASKER_STAGELIB } from '../../modules/local/repeatmasker/stagelib'
include { REPEATMASKER_REPEATMASK } from '../../modules/local/repeatmasker/repeatmask'
include { FASTASPLITTER } from '../../modules/local/fastasplitter'
include { CAT_FASTA as REPEATMASKER_CAT_FASTA} from '../../modules/local/cat/fasta'
include { GUNZIP } from '../../modules/nf-core/modules/gunzip/main'

workflow REPEATMASKER {
    take:
    genome // file path
    rm_lib // file path
    rm_species // tax name
    rm_db // file path

    main:

    FASTASPLITTER(genome,params.npart_size)

    // If chunks == 1, forward - else, map each chunk to the meta hash
    FASTASPLITTER.out.chunks.branch { m,f ->
        single: f.getClass() != ArrayList
        multi: f.getClass() == ArrayList
    }.set { ch_fa_chunks }

    ch_fa_chunks.multi.flatMap { h,fastas ->
        fastas.collect { [ h,file(it)] }
    }.set { ch_chunks_split }

    // We can avoid importing a Dfam database if it is not needed.
    if (params.rm_db && params.rm_species) {
        GUNZIP(
            create_meta_channel(rm_db)
        )
        REPEATMASKER_STAGELIB(
            rm_lib,
            rm_species,
            GUNZIP.out.gunzip.map { m,g -> g }
        )
    } else if (params.rm_species) {
        REPEATMASKER_STAGELIB(
            rm_lib,
            params.rm_species,
            file(params.dummy_gff)
        )
    } else {
        REPEATMASKER_STAGELIB(
            rm_lib,
            false,
            file(params.dummy_gff)
        )
    }

    REPEATMASKER_REPEATMASK(
        ch_fa_chunks.single.map { m,f -> [m,file(f)]}.mix(ch_chunks_split),
        REPEATMASKER_STAGELIB.out.library.collect().map{it[0].toString()},
        rm_lib.collect(),
        rm_species
    )

    REPEATMASKER_CAT_FASTA(REPEATMASKER_REPEATMASK.out.masked.groupTuple())

    emit:
    fasta = REPEATMASKER_CAT_FASTA.out.fasta
    versions = REPEATMASKER_STAGELIB.out.versions.mix(REPEATMASKER_REPEATMASK.out.versions,FASTASPLITTER.out.versions,REPEATMASKER_CAT_FASTA.out.versions)
}


def create_meta_channel(f) {
    def meta = [:]
    meta.id           = file(f).getSimpleName()

    def array = [ meta, f ]

    return array
}

