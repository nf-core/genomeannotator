process GAAS_FASTACLEANER {
    tag "$meta.id"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::gaas=1.2.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gaas:1.2.0--pl526r35_0':
        'quay.io/biocontainers/gaas:1.2.0--pl526r35_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path(fasta_clean), emit: fasta
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    fasta_clean = fasta.getBaseName() + ".clean.fa"
    """
    sed "s/[.]\$//" $fasta | sed "s/ .*//" > tmp
    gaas_fasta_cleaner.pl -f tmp -o $fasta_clean
    rm tmp
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gaas: 1.2.0
    END_VERSIONS
    """
}
