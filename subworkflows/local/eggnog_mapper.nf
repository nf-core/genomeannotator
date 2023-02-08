include { EGGNOGMAPPER_DB } from './../../modules/local/eggnogmapper/db'
include { EGGNOGMAPPER_EMAPPER} from './../../modules/local/eggnogmapper/emapper'

workflow FUNCTIONAL_ANNOTATION {

    take:
    annotation

    main:

    if (!params.eggnog_mapper_db) {
        EGGNOGMAPPER_DB(
            params.eggnog_taxonomy
        )
        ch_eggnog_db = EGGNOGMAPPER_DB.out.db
    } else {
        ch_eggnog_db = Channel.fromPath(file(params.eggnog_mapper_db))
    }

    EGGNOGMAPPER_EMAPPER(
        annotation,
        ch_eggnog_db.collect()
    )

    emit:
    gff = EGGNOGMAPPER_EMAPPER.out.gff
}
