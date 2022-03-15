process FASTP {
    tag "$meta.id"
    label 'process_high'
    
    conda (params.enable_conda ? "bioconda::fastp=0.23.2" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/fastp:0.23.2--h79da9fb_0':
        'quay.io/biocontainers/fastp:0.23.2--h79da9fb_0' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_trimmed.fastq.gz"), emit: reads
    path("*.json")                             , emit: json
    path("*.html")                             , emit: html  
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def json = prefix + ".fastp.json"
    def html = prefix + ".fastp.html"
    
    if (meta.single_end) {
       left = file(reads[0]).getBaseName() + "_trimmed.fastq.gz"
       """
          fastp -i ${reads[0]} --out1 ${left} -w ${task.cpus} -j $json -h $html

          cat <<-END_VERSIONS > versions.yml
          "${task.process}":
             fastp: \$(echo \$(fastp --version 2>&1) | cut -f2 -d " " )
          END_VERSIONS
       """
    } else {
       left = file(reads[0]).getBaseName() + "_trimmed.fastq.gz"
       right = file(reads[1]).getBaseName() + "_trimmed.fastq.gz"
       """
          fastp --detect_adapter_for_pe --in1 ${reads[0]} --in2 ${reads[1]} --out1 $left --out2 $right -w ${task.cpus} -j $json -h $html

          cat <<-END_VERSIONS > versions.yml
          "${task.process}":
             fastp: \$(echo \$(fastp --version 2>&1) | cut -f2 -d " " )
          END_VERSIONS

       """
    }

}
