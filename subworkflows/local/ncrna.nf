include { INFERNAL_PRESS } from '../../modules/local/infernal/press'
include { INFERNAL_SEARCH } from '../../modules/local/infernal/search'
include { FASTASPLITTER } from '../../modules/local/fastasplitter'
include { HELPER_DOWNLOADRFAM } from '../../modules/local/helper/downloadrfam'

workflow NCRNA {

   take:
   genome

   main:
   FASTASPLITTER(
      genome,
      params.npart_size
   )

   HELPER_DOWNLOADRFAM()

   INFERNAL_PRESS(
      DOWNLOAD_RFAM.out.fasta
   )
  
   INFERNAL_SEARCH(
      FASTASPLITTER.out.fasta,
      INFERNAL_PRESS.out.cm.collect()
   )

   HELPER_RFAMTOGFF(
      INFERNAL_SEARCH.out.tbl.collectFile(name: 'rfam.tbl'),
      HELPER_DOWNLOADRFAM.out.families
   )

   emit:
   gff = HELPER_RFAMTOGFF.out.gff

}

