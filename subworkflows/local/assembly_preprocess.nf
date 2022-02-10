//
// Clean and filter assembly
//

include { FASTA_CLEAN_NAMES } from '../../modules/local/fasta_clean_names'
include { ASSEMBLY_STATS } from '../../modules/local/assembly_stats'
include { FASTA_FILTER_SIZE as ASSEMBLY_FILTER_SIZE } from '../../modules/local/fasta_filter_size'

workflow ASSEMBLY_PREPROCESS {
    take:
    genome // file: /path/to/samplesheet.csv

    main:
    FASTA_CLEAN_NAMES(genome)
    ASSEMBLY_FILTER_SIZE(FASTA_CLEAN_NAMES.out.fasta)
    ASSEMBLY_STATS(ASSEMBLY_FILTER_SIZE.out.fasta)

    emit:
    fasta = ASSEMBLY_FILTER_SIZE.out.fasta
    stats = ASSEMBLY_STATS.out.stats

}

