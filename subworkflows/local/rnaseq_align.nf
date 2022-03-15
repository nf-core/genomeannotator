//
// Check input samplesheet and get read channels
//

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check'
include { STAR_INDEX } from '../../modules/local/star/index'
include { STAR_ALIGN as STAR_ALIGN_PASS_ONE ; STAR_ALIGN as STAR_ALIGN_PASS_TWO } from '../../modules/local/star/align'
include { FASTP } from '../../modules/local/fastp'
include { CAT_FASTQ } from '../../modules/nf-core/modules/cat/fastq/main'

workflow RNASEQ_ALIGN {

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
    
    FASTP.out.reads
        .map {
           meta,fastq ->
               meta.id = (meta.id.contains("SRR")) ? meta.id : meta.id.split('_')[0..-2].join('_')
           [ meta , fastq ] }
        .groupTuple(by: [0])
        .branch {
           meta, fastq ->
              single: fastq.size() == 1
                 return [ meta, fastq.flatten() ]
              multiple: fastq.size() > 1
                 return [ meta, fastq.flatten() ]
              
        }
        .set { ch_fastq }

    //
    // MODULE: concatenate reads per library
    CAT_FASTQ(
       ch_fastq.multiple
    ).reads
    .mix( ch_fastq.single )
    .set { ch_cat_fastq }

    //
    // MODULE: Align reads, first pass to produce junction information
    STAR_ALIGN_PASS_ONE(
       STAR_INDEX.out.star_index.collect(),
       ch_cat_fastq,
       Channel.from(params.dummy_gff).collect(),
       true
    )

    junctions = STAR_ALIGN_PASS_ONE.out.junctions.collectFile(name: 'all_juncs.gtf')
   
    //
    // MODULE: Align reads with junction information
    STAR_ALIGN_PASS_TWO(
       STAR_INDEX.out.star_index.collect(),
       FASTP.out.reads,
       junctions.collect(),
       false
    )
 
    emit:
    bam = STAR_ALIGN_PASS_TWO.out.bam
    json = FASTP.out.json
    html = FASTP.out.html
    versions = STAR_INDEX.out.versions.mix(STAR_ALIGN_PASS_ONE.out.versions,FASTP.out.versions)
}

def create_fastq_channel(LinkedHashMap row) {
    // sample,fastq_1,fastq_2,strandedness
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
