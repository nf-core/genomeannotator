//
// Check input samplesheet and get read channels
//

include { GAAS_FASTACLEANER } from '../../modules/local/gaas/fastacleaner'
include { EXONERATE_FASTACLEAN } from '../../modules/local/exonerate/fastaclean'
include { MINIMAP2_ALIGN } from '../../modules/local/minimap2/align'
include { SAMTOOLS_MERGE } from '../../modules/local/samtools/merge'
include { HELPER_BAMTOGFF } from '../../modules/local/helper/bamtogff'
include { HELPER_MINIMAPTOHINTS } from '../../modules/local/helper/minimaptohints'

workflow MINIMAP_ALIGN_TRANSCRIPTS {

    take:
    genome // file path
    transcripts // file path

    main:

       GAAS_FASTACLEANER(
          create_transcript_channel(transcripts)
       )
       EXONERATE_FASTACLEAN(
          GAAS_FASTACLEANER.out.fasta
       )
       MINIMAP2_ALIGN(
          EXONERATE_FASTACLEAN.out.fasta.splitFasta(by: 100000, file: true),
          genome.collect(),
          params.max_intron_size
       )
       SAMTOOLS_MERGE(
          MINIMAP2_ALIGN.out.bam.groupTuple()
       )
       HELPER_BAMTOGFF(
          SAMTOOLS_MERGE.out.bam
       )
       HELPER_MINIMAPTOHINTS(
          HELPER_BAMTOGFF.out.gff,
          params.t_est,
          params.pri_est
       )
  
    emit:
       hints = HELPER_MINIMAPTOHINTS.out.gff
       gff = HELPER_BAMTOGFF.out.gff
       bam = SAMTOOLS_MERGE.out.bam
       versions = MINIMAP2_ALIGN.out.versions

}


def create_transcript_channel(transcripts) {
    def meta = [:]
    meta.id           = file(transcripts).getSimpleName()

    def array = [ meta, transcripts ]

    return array
}

