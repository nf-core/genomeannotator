process STAR_INDEX {
    tag "$meta.id"
    label 'process_long'
    
    conda (params.enable_conda ? "bioconda::star=2.7.10a" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/star:2.7.10a--h9ee0642_0':
        'quay.io/biocontainers/star:2.7.10a--h9ee0642_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path(star_dir), emit: star_index
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    star_dir = meta.id + "_star"
    """
    mkdir -p $star_dir
    STAR --runThreadN ${task.cpus} \
       --runMode genomeGenerate \
       --genomeDir $star_dir \
       --genomeFastaFiles $fasta \
       --limitGenomeGenerateRAM ${task.memory.toBytes()}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        star: \$(echo \$(STAR --version)
    END_VERSIONS
    """
}
