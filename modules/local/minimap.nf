process MINIMAP {
    tag "$transcripts"

    label 'process_high'
    
    container 'ikmb/esga:minimap_1.3'

    input:
    path genome
    path transcripts
    val max_intron_size

    output:
    path minimap_bam, emit: bam
    path "versions.yml", emit: versions

    script:
    minimap_bam = est.getBaseName() + ".minimap.bam"

    """
       samtools faidx $genome
       minimap2 -t ${task.cpus} --split-prefix tmp -ax splice:hq -c -G $max_intron_size  $genome $transcripts | samtools sort -@ ${task.cpus} -m 2G -O BAM -o $minimap_bam

       cat <<-END_VERSIONS > versions.yml
       "${task.process}":
          Minimap2: \$( minimap2 --version" )
       END_VERSIONS

    """

}
