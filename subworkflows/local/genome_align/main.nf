//
// Align genomes and map annotations
//

include { FASTASPLITTER } from '../../../modules/local/fastasplitter'
include { SATSUMA2_SATSUMASYNTENY2 } from '../../../modules/local/satsuma2/synteny/main'
include { KRAKEN } from '../../../modules/local/kraken'
include { HELPER_KRAKEN2GFF as SATSUMA_KRAKEN2GFF } from '../../../modules/local/helper/kraken2gff'
include { GAAS_FASTACLEANER } from '../../../modules/local/gaas/fastacleaner'
include { HELPER_GTF2HINTS as SATSUMA_GTF2HINTS } from '../../../modules/local/helper/gtf2hints'
include { GAAS_FASTAFILTERBYSIZE } from '../../../modules/local/gaas/fastafilterbysize'

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
    FASTASPLITTER.out.chunks.branch { m,f ->
        single: f.getClass() != ArrayList
        multi: f.getClass() == ArrayList
    }.set { ch_fa_chunks }

    ch_fa_chunks.multi.flatMap { h,fastas ->
        fastas.collect { [ h,file(it)] }
    }.set { ch_chunks_split }

    genome_chunks = ch_chunks_split.mix(ch_fa_chunks.single)
    //
    // MODULE: Align two genome sequences
    //
    SATSUMA2_SATSUMASYNTENY2(
        genome_chunks.combine(targets_clean)
    )

    // Group Satsuma chains by query-target pair and add the target name to meta hash
    SATSUMA2_SATSUMASYNTENY2.out.chain.map { m,q,t,g,c ->
        new_meta = m.clone()
        new_meta.target = t.getSimpleName()

        tuple(new_meta,q,t,g,c)
    }.set { ch_satsuma_chains }

    // [ meta, query_fa, reference_fa, reference_gtf, chain
    //
    // MODULE: Map annotations across genomes using Satsuma chain file
    KRAKEN(
        ch_satsuma_chains
    )

    // [ meta, gtf ]
    KRAKEN.out.gtf.multiMap { m,f ->
        meta: [ "${m.id}-${m.target}",m ]
        gtf: [ "${m.id}-${m.target}",f ]
    }.set { ch_grouped_gtfs }

    ch_grouped_gtfs.gtf.collectFile { mkey,file -> [ "${mkey}.kraken.gtf",file] }
    .map { file -> [file.simpleName,file]}
    .set { ch_merged_gtfs }

    ch_grouped_gtfs.meta.unique().join(ch_merged_gtfs)
    .map { k,m,f -> tuple(m,f) }
    .set { ch_kraken_merged_gtf }

    //
    // MODULE: Convert Kraken GTF files to GFF
    //
    SATSUMA_KRAKEN2GFF(
        ch_kraken_merged_gtf
    )
    //
    // MODULE: Convert GFF file to hints
    //
    SATSUMA_GTF2HINTS(
        ch_kraken_merged_gtf,
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

