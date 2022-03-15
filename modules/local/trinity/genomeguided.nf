process TRINITY_GENOMEGUIDED {
    tag "$meta.id"
    label 'process_high'
    
    conda (params.enable_conda ? "bioconda::trinity=2.13.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/trinity:2.13.2--h00214ad_1':
        'quay.io/biocontainers/trinity:2.13.2--h00214ad_1' }"

    input:
    tuple val(meta), path(bam)
    val(max_intron_size)

    output:
    tuple val(meta),path("transcriptome_trinity/Trinity-GG.fasta"), emit: fasta
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    trinity_option = ( meta.strandedness == "unstranded" ) ? "" : "--SS_lib_type RF"
    """
    Trinity --genome_guided_bam $bam \
       --genome_guided_max_intron ${max_intron_size} \
       --CPU ${task.cpus} \
       --max_memory ${task.memory.toGiga()-1}G \
       --output transcriptome_trinity \
       $trinity_option
   
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        trinity: \$(echo \$(Trinity --version ) | grep "Trinity version" | cut -f3 -d" " | sed "s/Trinity-//" )
    END_VERSIONS
    """
}
