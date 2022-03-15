//
// Align genomes and map annotations
//

include { FASTASPLITTER } from '../../modules/local/fastasplitter'
include { SATSUMA2_SATSUMASYNTENY2 } from '../../modules/local/satsuma2/satsumasynteny2'
include { KRAKEN } from '../../modules/local/kraken'
include { HELPER_KRAKEN2GFF as SATSUMA_KRAKEN2GFF } from '../../modules/local/helper/kraken2gff'
include { GAAS_FASTACLEANER } from '../../modules/local/gaas/fastacleaner'
include { HELPER_GTF2HINTS as SATSUMA_GTF2HINTS } from '../../modules/local/helper/gtf2hints'
include { GAAS_FASTAFILTERBYSIZE } from '../../modules/local/gaas/fastafilterbysize'

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

    // 
    // MODULE: Remove small contigs from the assembly
    //
    GAAS_FASTAFILTERBYSIZE(
       GAAS_FASTACLEANER.out.fasta,
       params.min_contig_size
    )

    // Merge cleaned fasta with gtf again
    GAAS_FASTAFILTERBYSIZE.out.fasta
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
    // map list of fasta chunks to meta<->fasta pairs
    FASTASPLITTER.out.chunks.flatMap{ row ->
       row[1..-1].collect { [row[0].clone(), it]  }
    }.set {genome_chunks}

    //
    // MODULE: Align two genome sequences
    //
    SATSUMA2_SATSUMASYNTENY2(
       genome_chunks.combine(targets_clean)
    )
    
    grouped_chains = SATSUMA2_SATSUMASYNTENY2.out.chain.groupTuple(by: [0,1,2,3])

    // [ meta, query_fa, reference_fa, reference_gtf, [chains] 
    KRAKEN(
       grouped_chains
    )
    SATSUMA_KRAKEN2GFF(
       KRAKEN.out.gtf
    )
    SATSUMA_GTF2HINTS(
       KRAKEN.out.gtf,
       params.pri_trans
    )

    emit:
       versions = SATSUMA2_SATSUMASYNTENY2.out.versions
       gff = SATSUMA_KRAKEN2GFF.out.gff
       hints = SATSUMA_GTF2HINTS.out.gff
}

def create_target_channel(LinkedHashMap row) {

    // species,fasta,gtf
    def meta = [:]
    meta.id           = row.species
   
    array = [ meta, file(row.fasta), file(row.gtf) ]

    return array
}

