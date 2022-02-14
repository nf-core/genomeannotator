//
// Check input samplesheet and get read channels
//

include { GAAS_FASTACLEANER } from '../../modules/local/gaas/fastacleaner'
include { EXONERATE_FASTACLEAN } from '../../modules/local/exonerate/fastaclean'
include { MINIMAP_ALIGN } from '../../modules/local/minimap/align'
include { SAMTOOLS_MERGEBAM } from '../../modules/local/samtools/mergebam'
include { MINIMAP_TO_GFF } from '../../modules/local/minimap_to_gff'
include { MINIMAP_TO_GMOD } from '../../modules/local/minimap_to_gmod'

workflow MINIMAP_TRANSCRIPT_ALIGN {

    take:
    genome // file path
    transcripts // file path

    main:

       GAAS_FASTA_CLEAN(transcripts)
       FASTACLEAN(
          GAAS_FASTA_CLEAN.out.fasta
       )
       MINIMAP(
          FASTACLEAN.out.fasta.splitFasta(by: 100000, file: true),
          genome.collect()
       )
       SAMTOOLS_MERGE_BAM(
          MINIMAP.out.bam.collect()
       )
       MINIMAP_TO_GFF(
          SAMTOOLS_MERGE_BAM.out.bam
       )
       MINIMAP_TO_HINTS(
          MINIMAP_TO_GFF.out.gff
       )
       MINIMAP_TO_GMOD(
          MINIMAP_TO_GFF.out.gff
       )       
  
    emit:

       hints = MINIMAP_TO_HINTS.out.gff
       gff = MINIMAP_TO_GFF.out.gff
       versions = MINIMAP.out.versions.concat(SAMTOOLS_MERGE_BAM.out.versions)

}
