//
// Check input samplesheet and get read channels
//

include { REPEATMASKER_STAGELIB } from '../../modules/local/repeatmasker/stagelib'
include { REPEATMASKER_REPEATMASK } from '../../modules/local/repeatmasker/repeatmask'
include { FASTASPLITTER } from '../../modules/local/fastasplitter'
include { CAT_FASTA as REPEAT_CAT_FASTA} from '../../modules/local/cat/fasta'

workflow REPEATMASKER {
    take:
    genome // file path
    rm_lib // file path
    rm_species

    main:
    FASTASPLITTER(genome,params.npart_size)
    REPEATMASKER_STAGELIB(rm_lib)
    REPEATMASKER_REPEATMASK( 
       FASTASPLITTER.out.chunks,
       REPEATMASKER_STAGELIB.out.library.collect(),
       rm_lib.collect(),
       rm_species
    )
    
    REPEAT_CAT_FASTA(REPEATMASKER_REPEATMASK.out.masked)
    
    emit:
    fasta = REPEAT_CAT_FASTA.out.fasta
    versions = REPEATMASKER_STAGELIB.out.versions.mix(REPEATMASKER_REPEATMASK.out.versions,FASTASPLITTER.out.versions,REPEAT_CAT_FASTA.out.versions)
}
