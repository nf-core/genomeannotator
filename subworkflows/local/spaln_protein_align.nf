//
// Check input samplesheet and get read channels
//

include { GAAS_FASTACLEANER } from '../../modules/local/gaas/fastacleaner'
include { EXONERATE_FASTACLEAN } from '../../modules/local/exonerate/fastaclean'
include { GAAS_FASTAFILTERBYSIZE } from '../../modules/local/gaas/fastafilterbysize'
include { SPALN_MAKEINDEX } from '../../modules/local/spaln/makeindex'
include { SPALN_ALIGN } from '../../modules/local/spaln/align'
include { SPALN_MERGE } from '../../modules/local/spaln/merge'
//include { SPALN_TO_EVM } from '../../modules/local/spaln_to_evm'
include { SPALNTOGMOD } from '../../modules/local/spalntogmod'
include { AUGUSTUS_ALIGNTOHINTS } from '../../modules/local/augustus/aligntohints'

workflow SPALN_PROTEIN_ALIGN {

    take:
    genome // file path
    proteins // file path
    protein_identity // an integer between 0 and 100

    main:

       GAAS_FASTACLEANER(
          create_protein_channel(proteins)
       )
       EXONERATE_FASTACLEAN(
          GAAS_FASTACLEANER.out.fasta
       )
       GAAS_FASTAFILTERBYSIZE(
          EXONERATE_FASTACLEAN.out.fasta,
          params.min_prot_length
       )
       SPALN_MAKEINDEX(genome)  

       ch_fasta_chunks = GAAS_FASTAFILTERBYSIZE.out.fasta.splitFasta(by: params.nproteins, file: true, elem: [1])       
       SPALN_ALIGN(
          SPALN_MAKEINDEX.out.spaln_index,
          ch_fasta_chunks,
          params.spaln_q,
          params.spaln_taxon,
          params.spaln_options
       )

       SPALN_MERGE(
          SPALN_MAKEINDEX.out.spaln_index,
          SPALN_ALIGN.out.align.collect(),
          protein_identity
       )
       AUGUSTUS_ALIGNTOHINTS(
          SPALN_MERGE.out.gff,
         "spaln",
          params.max_intron_size,
          params.pri_prot
       )
       SPALNTOGMOD(
          SPALN_MERGE.out.gff
       )
    emit:
       hints = AUGUSTUS_ALIGNTOHINTS.out.gff
       gff = SPALN_MERGE.out.gff
       versions = GAAS_FASTACLEANER.out.versions.mix(EXONERATE_FASTACLEAN.out.versions, SPALN_ALIGN.out.versions)

}


def create_protein_channel(proteins) {
    def meta = [:]
    meta.id           = file(proteins).getSimpleName()

    def array = [ meta, proteins ]

    return array
}

