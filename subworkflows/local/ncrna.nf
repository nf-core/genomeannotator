include { INFERNAL_PRESS } from '../../modules/local/infernal/press'
include { INFERNAL_SEARCH } from '../../modules/local/infernal/search'
include { FASTASPLITTER } from '../../modules/local/fastasplitter'
include { HELPER_DOWNLOADRFAM } from '../../modules/local/helper/downloadrfam'
include { HELPER_RFAMTOGFF } from '../../modules/local/helper/rfamtogff'

workflow NCRNA {

   take:
   genome

   main:
   FASTASPLITTER(
      genome,
      params.npart_size
   )

   HELPER_DOWNLOADRFAM(genome)

   INFERNAL_PRESS(
      HELPER_DOWNLOADRFAM.out.cm
   )
  
   INFERNAL_SEARCH(
      FASTASPLITTER.out.chunks,
      INFERNAL_PRESS.out.cm.collect()
   )

   HELPER_RFAMTOGFF(
      INFERNAL_SEARCH.out.tbl.collectFile(name: 'rfam.tbl'),
      HELPER_DOWNLOADRFAM.out.families
   )

   emit:
   gff = HELPER_RFAMTOGFF.out.gff

}

