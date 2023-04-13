include { EGGNOGMAPPER_DB } from './../../../modules/local/eggnogmapper/db/main'
include { EGGNOGMAPPER_EMAPPER} from './../../../modules/local/eggnogmapper/emapper/main'

ch_versions = Channel.from([])

workflow EGGNOG_MAPPER {

    take:
    annotation

    main:

    // Download the eggnog mapper db, if only a taxonomy ID is provided
    if (!params.eggnog_mapper_db) {
        EGGNOGMAPPER_DB(
            params.eggnog_taxonomy
        )
        ch_eggnog_db = EGGNOGMAPPER_DB.out.db

        ch_versions = ch_versions.mix(EGGNOGMAPPER_DB.out.versions)

    } else {
        ch_eggnog_db = Channel.fromPath(file(params.eggnog_mapper_db))
    }

    // Perform functional annotation usin eggnog mapper
    EGGNOGMAPPER_EMAPPER(
        annotation,
        ch_eggnog_db.collect()
    )

    ch_versions = ch_versions.mix(EGGNOGMAPPER_EMAPPER.out.versions)

    emit:
    gff = EGGNOGMAPPER_EMAPPER.out.gff
    versions = ch_versions
}
