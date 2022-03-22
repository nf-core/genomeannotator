//
// Clean and filter assembly
//

include { FASTASPLITTER } from '../../modules/local/fastasplitter'
include { AUGUSTUS_AUGUSTUSBATCH } from '../../modules/local/augustus/augustusbatch'
include { AUGUSTUS_FIXJOINGENES } from '../../modules/local/augustus/fixjoingenes'
include { HELPER_CREATEGFFIDS as AUGUSTUS_CREATEGFFIDS } from '../../modules/local/helper/creategffids'
include { GFFREAD as AUGUSTUS_GFF2PROTEINS } from '../../modules/local/gffread'
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
    AUGUSTUS_FIXJOINGENES(
       AUGUSTUS_AUGUSTUSBATCH.out.gff
    )
    AUGUSTUS_FIXJOINGENES.out.gff
    .groupTuple()
    .set { grouped_augustus_gff }
  
    AUGUSTUS_CREATEGFFIDS(
       grouped_augustus_gff
    )    
    AUGUSTUS_GFF2PROTEINS(
       AUGUSTUS_CREATEGFFIDS.out.gff.join(genome)
    )

    emit:
    gff = AUGUSTUS_CREATEGFFIDS.out.gff
    versions = FASTASPLITTER.out.versions
}
