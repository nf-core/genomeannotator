process FASTA_SPLIT_SIZE {
    tag "$fasta"

    input:
    path fasta
    val fsize

    output:
    path "*.part-*.*"       , emit: chunks

    script: // This script is bundled with the pipeline, in nf-core/esga/bin/

    """
       fasta-splitter.pl -part-sequence-size $fsize $fasta

    """
}
