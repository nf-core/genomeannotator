//
// Check input samplesheet and get read channels
//

include { GAAS_FASTACLEANER } from '../../modules/local/gaas/fastacleaner/main'
include { EXONERATE_FASTACLEAN } from '../../modules/local/exonerate/fastaclean/main'
include { PASA_SEQCLEAN } from '../../modules/local/pasa/seqclean/main'
include { PASA_ALIGNASSEMBLE } from '../../modules/local/pasa/alignassemble/main'
include { PASA_ASMBLSTOTRAINING } from '../../modules/local/pasa/asmblstotraining/main'
include { HELPER_PASA2TRAINING } from '../../modules/local/helper/pasa2training'
include { GFFREAD as PASA_GFF2PROTEINS } from '../../modules/local/gffread'

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
        PASA_GFF2PROTEINS(
            PASA_ASMBLSTOTRAINING.out.gff.join(genome)
        )

    emit:
        gff = PASA_ASMBLSTOTRAINING.out.gff
        gff_training = HELPER_PASA2TRAINING.out.gff
        proteins = PASA_GFF2PROTEINS.out.proteins
        versions = PASA_ALIGNASSEMBLE.out.versions

}


def create_transcript_channel(transcripts) {
    println transcripts

    def meta = [:]
    meta.id           = file(transcripts).getSimpleName()

    def array = [ meta, transcripts ]

    return array
}

