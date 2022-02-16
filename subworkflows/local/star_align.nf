//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'
include { STAR_INDEX } from '../../modules/local/star/index'
include { STAR_ALIGN as STAR_ALIGN_PASS_ONE ; STAR_ALIGN as STAR_ALIGN_PASS_TWO } from '../../modules/local/star/align'
include { FASTP } from '../../modules/local/fastp'

workflow STAR_ALIGN {

    take:
    genome // file path
    samplesheet // file path

    main:
    
    STAR_INDEX(
       genome
    )
    SAMPLESHEET_CHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_fastq_channel(it) }
        .set { reads }

    FASTP(
       reads
    )
    STAR_ALIGN_PASS_ONE(
       STAR_INDEX.out.star_index.collect(),
       FASTP.out.reads,
       Channel.from(params.dummy_gff).collect(),
       true
    )
    STAR_ALIGN_PASS_TWO(
       STAR_INDEX.out.star_index.collect(),
       FASTP.out.reads,
       STAR_ALIGN_PASS_ONE.out.junctions.collectFile(),
       false
    )
 
    emit:
    bam = STAR_ALIGN_PASS_TWO.out.bam
    json = FASTP.out.json
    html = FASTP.out.html
    versions = STAR_INDEX.out.versions.mix(STAR_ALIGN_PASS_ONE.out.versions,FASTP.out.versions)
}

def create_fastq_channel(LinkedHashMap row) {
    def meta = [:]
    meta.id           = row.sample
    meta.single_end   = row.single_end.toBoolean()
    meta.strandedness = row.strandedness

    def array = []
    if (!file(row.fastq_1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.fastq_1}"
    }
    if (meta.single_end) {
        array = [ meta, [ file(row.fastq_1) ] ]
    } else {
        if (!file(row.fastq_2).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.fastq_2}"
        }
        array = [ meta, [ file(row.fastq_1), file(row.fastq_2) ] ]
    }
    return array
}
