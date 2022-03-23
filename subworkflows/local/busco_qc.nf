include { BUSCO_DOWNLOADDB } from '../../modules/local/busco/downloaddb'
include { BUSCO_BUSCO as BUSCO } from '../../modules/local/busco/busco'

workflow BUSCO_QC {

   take:
   proteins
   busco_lineage_dir

   main:

   if (params.busco_lineage_dir) {
      ch_lineage_dir = busco_lineage_dir
   } else {
      BUSCO_DOWNLOADDB(
         params.busco_lineage
      )
      ch_lineage_dir = BUSCO_DOWNLOADDB.out.busco_lineage_dir
   }

   BUSCO(
      proteins,
      ch_lineage_dir.collect()
   )

   emit:
   busco_summary = BUSCO.out.summary

}

