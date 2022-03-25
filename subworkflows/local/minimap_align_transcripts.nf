//
// Check input samplesheet and get read channels
//

include { GAAS_FASTACLEANER } from '../../modules/local/gaas/fastacleaner'
include { EXONERATE_FASTACLEAN } from '../../modules/local/exonerate/fastaclean'
include { MINIMAP2_ALIGN } from '../../modules/local/minimap2/align'
include { SAMTOOLS_MERGE } from '../../modules/local/samtools/merge'
include { HELPER_BAMTOGFF as MINIMAP_BAMTOGFF } from '../../modules/local/helper/bamtogff'
include { HELPER_MINIMAPTOHINTS } from '../../modules/local/helper/minimaptohints'
include { HELPER_MATCH2GMOD } from '../../modules/local/helper/match2gmod'

workflow MINIMAP_ALIGN_TRANSCRIPTS {

    take:
    genome // file path
    transcripts // file path

    main:

       GAAS_FASTACLEANER(
          transcripts
       )
       EXONERATE_FASTACLEAN(
          GAAS_FASTACLEANER.out.fasta
       )
       MINIMAP2_ALIGN(
          EXONERATE_FASTACLEAN.out.fasta.splitFasta(by: 100000, file: true),
          genome.collect(),
          params.max_intron_size
       )
   
       MINIMAP2_ALIGN.out.bam
          .groupTuple()
          .branch {
             meta,bam ->
                single: bam.size() == 1
                   return [meta, bam ]
                multiple: bam.size() > 1
                   return [meta, bam ]
          }
       .set { ch_bams }
                    
       SAMTOOLS_MERGE(
         ch_bams.multiple
       )
       MINIMAP_BAMTOGFF(
          SAMTOOLS_MERGE.out.bam.mix(ch_bams.single)
       )
       HELPER_MINIMAPTOHINTS(
          MINIMAP_BAMTOGFF.out.gff,
          params.t_est,
          params.pri_est
       )
       HELPER_MATCH2GMOD(
          MINIMAP_BAMTOGFF.out.gff
       )
  
    emit:
       hints = HELPER_MINIMAPTOHINTS.out.gff
       gff = MINIMAP_BAMTOGFF.out.gff
       bam = SAMTOOLS_MERGE.out.bam
       versions = MINIMAP2_ALIGN.out.versions

}
