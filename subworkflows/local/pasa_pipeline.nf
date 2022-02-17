//
// Check input samplesheet and get read channels
//

include { GAAS_FASTACLEANER } from '../../modules/local/gaas/fastacleaner'
include { EXONERATE_FASTACLEAN } from '../../modules/local/exonerate/fastaclean'
include { PASA_SEQCLEAN } from '../../modules/local/pasa/seqclean'
include { PASA_ALIGNASSEMBLE } from '../../modules/local/pasa/alignassemble'
include { PASA_PASATOMODELS } from '../../modules/local/pasa/pasatomodels'

workflow PASA_PIPELINE {

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
       PASA_SEQCLEAN(
          EXONERATE_FASTACLEAN.out.fasta
       )
       PASA_ALIGNASSEMBLE(
          genome,
          SEQCLEAN.out.fasta,
          params.pasa_config_file,
          params.max_intron_size
       )
  
    emit:
       gff = PASATOMODELS.out.gff
       fasta = PASATOMODELS.out.fasta
       versions = PASA_ALIGNASSEMBLE.out.versions

}


def create_transcript_channel(transcripts) {
    def meta = [:]
    meta.id           = file(transcripts).getSimpleName()

    def array = [ meta, transcripts ]

    return array
}

