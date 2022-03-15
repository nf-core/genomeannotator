//
// Check input samplesheet and get read channels
//

include { GAAS_FASTACLEANER } from '../../modules/local/gaas/fastacleaner'
include { EXONERATE_FASTACLEAN } from '../../modules/local/exonerate/fastaclean'
include { PASA_SEQCLEAN } from '../../modules/local/pasa/seqclean'
include { PASA_ALIGNASSEMBLE } from '../../modules/local/pasa/alignassemble'
include { PASA_ASMBLSTOTRAINING } from '../../modules/local/pasa/asmblstotraining'
include { HELPER_PASA2TRAINING } from '../../modules/local/helper/pasa2training'

workflow PASA_PIPELINE {

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
       PASA_SEQCLEAN(
          EXONERATE_FASTACLEAN.out.fasta
       )
       PASA_ALIGNASSEMBLE(
          genome,
          PASA_SEQCLEAN.out.fasta,
          params.pasa_config_file,
          params.max_intron_size
       )
       PASA_ASMBLSTOTRAINING(
          PASA_ALIGNASSEMBLE.out.pasa_out
       )
       HELPER_PASA2TRAINING(
           PASA_ASMBLSTOTRAINING.out.gff,
           params.pasa_nmodels
       )
  
    emit:
       gff = PASA_ASMBLSTOTRAINING.out.gff
       gff_training = HELPER_PASA2TRAINING.out.gff
       versions = PASA_ALIGNASSEMBLE.out.versions

}


def create_transcript_channel(transcripts) {
    println transcripts

    def meta = [:]
    meta.id           = file(transcripts).getSimpleName()

    def array = [ meta, transcripts ]

    return array
}

