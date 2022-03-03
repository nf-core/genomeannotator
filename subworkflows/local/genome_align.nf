//
// Align genomes and map annotations
//

include { FASTASPLITTER } from '../../modules/local/fastasplitter'
include { SATSUMA2_SATSUMASYNTENY2 } from '../../modules/local/satsuma2/satsumasynteny2'
include { KRAKEN } from '../../modules/local/kraken'
INCLUDER { HELPER_KRAKEN2GFF } from '../../modules/local/helper/kraken2gff'

workflow GENOME_ALIGN {

    take:
    genome // file path
    samples // file path

    main:

    samples
       .splitCsv ( header:true, sep:',' )
       .map { create_target_channel(it) }
       .set { targets }

    //
    // MODULE: Clean the target genome
    //
    GAAS_FASTACLEANER(
       targets.map { m,f,g ->
          tuple(m,f)
       }
    )

    // Merge cleaned fasta with gtf again
    GAAS_FASTACLEANER.out.fasta
       .join(
          targets.map { m,f,g ->
             tuple(m,g)
          }
       )
    .set { targets_clean }

    //
    // MODULE: Split fasta file into chunks
    //

    FASTASPLITTER(
       genome,
       params.npart_size
    )

    //
    // MODULE: Align two genome sequences
    //
    SATSUMA2_SATSUMASYNTENY2(
       FASTASPLITTER.out.chunks,
       targets_clean
    )
    
    grouped_chains = SATSUMA2_SATSUMASYNTENY2.out.chain.groupTuple(by: [0,1,2,3])

    // [ meta, query_fa, reference_fa, reference_gtf, [chains] 
    KRAKEN(
       grouped_chains
    )
    KRAKEN2GFF(
       KRAKEN.out.gtf
    )

    emit:
       versions = SATSUMA2_SATSUMASYNTENY2.out.versions

}

def create_target_channel(LinkedHashMap row) {

    // species,fasta,gtf
    def meta = [:]
    meta.id           = row.species
   
    array = [ meta, [ file(row.fasta), file(row.gtf) ] ]

    return array
}

