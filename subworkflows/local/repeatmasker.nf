//
// Check input samplesheet and get read channels
//

include { REPEATMASKER_STAGELIB } from '../../modules/local/repeatmasker/stagelib'
include { REPEATMASKER_REPEATMASK } from '../../modules/local/repeatmasker/repeatmask'
include { FASTASPLITTER } from '../../modules/local/fastasplitter'

workflow REPEATMASKER {
    take:
    genome // file path
    rm_lib // file path

    main:
    FASTASPLITTER(genome,params.npart_size)
    REPEATMASKER_STAGELIB(rm_lib)
    REPEATMASKER_REPEATMASK( 
       FASTASPLITTER.out.chunks,
       REPEATMASKER_STAGELIB.out.library.collect(),
       rm_lib.collect()
    )

    rm = REPEATMASKER_REPEATMASK.out.masked.collectFile(name: "genome_rm.fa", newLine: true)
    
    emit:
    genome_rm = rm
    versions = REPEATMASKER_STAGELIB.out.versions.mix(REPEATMASKER_REPEATMASK.out.versions,FASTASPLITTER.out.versions)
}
