//
// Clean and filter assembly
//

include { FASTASPLITTER } from '../../modules/local/fastasplitter'
include { AUGUSTUS_AUGUSTUSBATCH } from '../../modules/local/augustus/augustusbatch'

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
    AUGUSTUS_AUGUSTUSBATCH(
       FASTASPLITTER.out.chunks,
       hints.collect(),
       aug_config_folder.collect().map{ it[0].toString() },
       aug_extrinsic_cfg.collect(),
       params.aug_chunk_length,
       params.aug_species
    )
    //AUGUSTUS_FIXJOINGENES(
    //   AUGUSTUS_AUGUSTUSBATCH.out.gff
    //)
    
    //merged_models = AUGUSTUS_FIXJOINGENES.out.gff.collecFile(name: "augustus_merged_models.gff3")    

    emit:
    //gff = AUGUSTUS_FIXJOINGENES.out.gff
    versions = FASTASPLITTER.out.versions
}
