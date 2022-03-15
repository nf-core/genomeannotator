process REPEATMODELER {
    tag "$meta.id"
    label 'process_high'
    
    conda (params.enable_conda ? "bioconda::repeatmodeler=2.0.2a" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/repeatmodeler:2.0.2a--pl5321h9ee0642_1':
        'quay.io/biocontainers/repeatmodeler:2.0.2a--pl5321h9ee0642_1' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("consensi.fa"), emit: fasta
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    BuildDatabase -name genome_source -engine ncbi $fasta
    RepeatModeler -engine ncbi -pa ${task.cpus} -database genome_source
    cp RM_*/consensi.fa .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        repeatmodeler: \$(echo \$(RepeatModeler --version | cut -f3 -d " "))
    END_VERSIONS
    """
}
