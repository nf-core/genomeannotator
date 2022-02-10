//
// Check input samplesheet and get read channels
//

include { REPEATLIB_STAGE } from '../../modules/local/repeatlib_stage'
include { REPEATMASKER } from '../../modules/local/repeatmasker'
include { FASTA_SPLIT_SIZE } from '../../modules/local/fasta_split_size'

workflow REPEATMASK {
    take:
    genome // file path
    rm_lib // file path

    main:
    FASTA_SPLIT_SIZE(genome,params.npart_size)
    REPEATLIB_STAGE(rm_lib)
    REPEATMASKER( 
       FASTA_SPLIT_SIZE.out.flatMap(),
       REPEATLIB_STAGE.out.library.collect().flatMap(),
       rm_lib.collect()
    )

    rm = REPEATMASKER.out.rm_fa.collectFile(name: "genome_rm.fa", newLine: true)
    
    emit:
    genome_rm = rm
}
