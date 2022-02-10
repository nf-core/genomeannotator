//
// Check input samplesheet and get read channels
//

include { GAAS_FASTA_CLEAN } from '../../modules/local/gaas_fasta_clean'
include { FASTACLEAN } from '../../modules/local/fastaclean'
include { GAAS_FILTER_SIZE } from '../../modules/local/gaas_filter_size'
include { SPALN_MAKE_INDEX } from '../../modules/local/spaln_make_index'
include { SPALN_ALIGN } from '../../modules/local/spaln_align'
include { SPALN_MERGE } from '../../modules/local/spaln_merge'
include { SPALN_TO_EVM } from '../../modules/local/spaln_to_evm'
include { SPALN_TO_GMOD } from '../../modules/local/spaln_to_gmod'
include { AUGUSTUS_ALIGN_TO_HINTS } from '../../modules/local/augustus_align_to_hints'

workflow SPALN_PROTEIN_HINTS {

    take:
    genome // file path
    proteins // file path

    main:

       GAAS_FASTA_CLEAN(proteins)
       FASTACLEAN(
          GAAS_FASTA_CLEAN.out.fasta
       )
       GAAS_FILTER_SIZE(
          FASTACLEAN.out.fasta,
	  params.min_prot_length
       )
       SPALN_MAKE_INDEX(genome)         
       SPALN_ALIGN(
          GAAS_FILTER_SIZE.out.fasta.splitFasta(by: params.nproteins, file: true),
          SPALN_MAKE_INDEX.out,
	  params.spaln_q,
          params.spaln_taxon,
          params.spaln_options
       )
       SPALN_MERGE(
          SPALN_ALIGN.out.align.collect(),
          SPALN_MAKE_INDEX.out,
          60
       )     
       AUGUSTUS_ALIGN_TO_HINTS(
          SPALN_MERGE.out,
	  "spaln",
          params.max_intron_size,
          params.pri_prot
       )
       SPALN_TO_EVM(
          SPALN_MERGE.out
       )
       SPALN_TO_GMOD(
          SPALN_MERGE.out
       )

    emit:
       hints = AUGUSTUS_ALIGN_TO_HINTS.out.gff
       evm = SPALN_TO_EVM.out.gff
       gff = SPALN_MERGE.out.gff
       

}
