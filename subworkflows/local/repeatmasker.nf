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
    rm_species
    rm_db

    main:
    FASTASPLITTER(genome,params.npart_size)
    GUNZIP(
       create_meta_channel(rm_db)
    )
    REPEATMASKER_STAGELIB(
       rm_lib,
       rm_species,
       GUNZIP.out.gunzip.map {m,g -> g}
    )
    REPEATMASKER_REPEATMASK( 
       FASTASPLITTER.out.chunks,
       REPEATMASKER_STAGELIB.out.library.collect().map{it[0].toString()},
       rm_lib.collect(),
       rm_species
    )
    
    REPEATMASKER_CAT_FASTA(REPEATMASKER_REPEATMASK.out.masked)
    
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

