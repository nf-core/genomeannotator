include { BUSCO_DOWNLOADDB } from '../../modules/local/busco/downloaddb'
include { BUSCO_BUSCO as BUSCO } from '../../modules/local/busco/busco'

workflow BUSCO_QC {

   take:
   proteins
   busco_lineage

   main:

   // 
   // MODULE: Download the BUSCO database for this taxonomic group
   //
   BUSCO_DOWNLOADDB(
      busco_lineage
   )
   ch_lineage_dir = BUSCO_DOWNLOADDB.out.busco_lineage_dir

   //
   // MODULE: Run BUSCO on the protein sets
   //
   BUSCO(
      proteins,
      ch_lineage_dir.collect()
   )

   emit:
   busco_summary = BUSCO.out.summary

}

