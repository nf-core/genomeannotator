//
// Check input samplesheet and get read channels
//

include { GAAS_FASTACLEANER } from '../../modules/local/gaas/fastacleaner'
include { EXONERATE_FASTACLEAN } from '../../modules/local/exonerate/fastaclean'
include { MINIMAP_ALIGN } from '../../modules/local/minimap/align'
include { SAMTOOLS_MERGEBAM } from '../../modules/local/samtools/mergebam'
include { BAMTOGFF } from '../../modules/local/helper/bamtogff'

workflow MINIMAP_TRANSCRIPT_ALIGN {

    take:
    genome // file path
    transcripts // file path

    main:

       GAAS_FASTACLEANER(transcripts)
       FASTACLEAN(
          GAAS_FASTACLEANER.out.fasta
       )
       MINIMAP_ALIGN(
          FASTACLEAN.out.fasta.splitFasta(by: 100000, file: true),
          genome.collect()
       )
       SAMTOOLS_MERGEBAM(
          MINIMAP.out.bam.collect()
       )
       BAMTOGFF(
          SAMTOOLS_MERGE.out.bam
       )
  
    emit:

       gff = BAMTOGFF.out.gff
       versions = MINIMAP_ALIGN.out.versions.concat(SAMTOOLS_MERGE.out.versions)

}
