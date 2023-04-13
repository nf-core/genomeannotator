process GAAS_FASTACLEANER {
    tag "$meta.id"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::gaas=1.2.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gaas:1.2.0--pl526r35_0':
        'quay.io/biocontainers/gaas:1.2.0--pl526r35_0' }"

    input:
    tuple val(meta), path(fa)

    output:
    tuple val(meta), path(fa_clean), emit: fasta
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    fa_clean = fa.getBaseName() + ".clean.fa"
    """
    sed "s/[.]\$//" $fa | sed "s/ .*//" > tmp
    gaas_fasta_cleaner.pl -f tmp -o $fa_clean
    rm tmp
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gaas: 1.2.0
    END_VERSIONS
    """
}
