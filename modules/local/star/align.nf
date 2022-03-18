process STAR_ALIGN {
    tag "$meta.id"
    label 'process_high'
    
    conda (params.enable_conda ? "bioconda::star=2.6.1d" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:59cdd445419f14abac76b31dd0d71217994cbcc9-0' :
        'quay.io/biocontainers/mulled-v2-1fa26d1ce03c295fe2fdcf85831a92fbcbd7e8c2:59cdd445419f14abac76b31dd0d71217994cbcc9-0' }"

    input:
    tuple val(meta_g), path(star_index)
    tuple val(meta), path(reads)
    path gtf
    val star_ignore_sjdbgtf

    output:
    tuple val(meta), path('*.bam'), emit: bam
    path "versions.yml"           , emit: versions
    path junctions                , emit: junctions
    path '*.wig'                  , emit: wiggle, optional: true

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    options = "--outFilterType BySJout --outFilterMultimapNmax 5 --outSAMstrandField intronMotif"
    junctions = prefix + ".SJ.out.tab"
    if (star_ignore_sjdbgtf) {
       bamFile = prefix + ".aligned.bam"
    } else {
       options = options.concat(" --sjdbFileChrStartEnd $gtf --outWigType wiggle")
       bamFile = prefix + ".with_juncs.aligned.bam"
    }
    meta.ref = meta_g.id
    """
    STAR --runThreadN ${task.cpus} \
       --genomeDir $star_index \
       --readFilesCommand zcat \
       --limitBAMsortRAM ${task.memory.toBytes()/4} \
       --readFilesIn $reads \
       --alignIntronMin 20 \
       --alignIntronMax $params.max_intron_size \
       --outSAMtype BAM SortedByCoordinate \
       --outFileNamePrefix $prefix \
       $options
    
    mv *Aligned.sortedByCoord.out.bam $bamFile
    cp *SJ.out.tab $junctions

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(echo \$(STAR --version) )
    END_VERSIONS
    """
}
