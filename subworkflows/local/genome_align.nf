//
// Check input samplesheet and get read channels
//

include { FASTASPLITTER } from '../../modules/local/fastasplitter'
include { SATSUMA2_SATSUMASYNTENY2 } from '../../modules/local/satsuma2/satsumasynteny2'

workflow GENOME_ALIGN {

    take:
    genome // file path
    target // file path

    main:

    //
    // MODULE: Split fasta file into chunks
    //

    FASTASPLITTER(
       genome,
       params.npart_size
    )
    //
    // MODULE: Align two genome sequences
    //
    SATSUMA2_SATSUMASYNTENY2(
       FASTASPLITTER.out.chunks,
       target
    )
    
    // [ assembly_id, reference_id, chain_files, assembly_fa, reference_fa, reference_gtf ]
    
    emit:
       versions = SATSUMA2_SATSUMA2SYNTENY.out.versions

}
