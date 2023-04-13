include { BUSCO_DOWNLOADDB } from '../../../modules/local/busco/downloaddb/main'
include { BUSCO_BUSCO as BUSCO } from '../../../modules/local/busco/busco/main'

ch_versions = Channel.from([])

workflow BUSCO_QC {

    take:
    proteins
    busco_lineage
    busco_db_path

    main:

   //
   // MODULE: Download the BUSCO database for this taxonomic group
   //
    if (!busco_db_path) {
        BUSCO_DOWNLOADDB(
            busco_lineage
        )
        ch_lineage_dir = BUSCO_DOWNLOADDB.out.busco_lineage_dir

        ch_versions = ch_versions.mix(BUSCO_DOWNLOADDB.out.versions)

    } else {
        ch_lineage_dir = Channel.from([busco_lineage,busco_db_path])
    }

   //
   // MODULE: Run BUSCO on the protein sets
   //
    BUSCO(
        proteins,
        ch_lineage_dir.collect()
    )

    ch_versions = ch_versions.mix(BUSCO.out.versions)

    emit:
    busco_summary = BUSCO.out.summary
    versions = ch_versions

}

