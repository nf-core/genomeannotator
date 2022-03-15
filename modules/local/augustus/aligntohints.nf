process AUGUSTUS_ALIGNTOHINTS {
    tag "$meta.id"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::augustus=3.4.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/augustus:3.4.0--pl5321hd8b735c_3':
        'quay.io/biocontainers/augustus:3.4.0--pl5321hd8b735c_3' }"

    input:
    tuple val(meta), path(gff)
    val prog
    val max_intron_size
    val priority
    
    output:
    path(hints), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    hints = gff.getBaseName() + ".hints.gff3"
    """
    align2hints.pl --in=$gff --maxintronlen=$max_intron_size --prg=$prog --priority=$priority --out=$hints

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        align2hints.pl: 1.0
    END_VERSIONS
    """
}
