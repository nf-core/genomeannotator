process AUGUSTUS_BAM2HINTS {
    tag "$meta.id"
    label 'process_long'
    
    conda (params.enable_conda ? "bioconda::augustus=3.4.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/augustus:3.4.0--pl5321hd8b735c_3':
        'quay.io/biocontainers/augustus:3.4.0--pl5321hd8b735c_3' }"

    input:
    tuple val(meta), path(bam)
    val(priority)

    output:
    path("*.gff"), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    gff = prefix + ".hints.gff"
    """
    bam2hints --intronsonly 0 -p $priority -s 'E' --in=$bam --out=$gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        augustus: \$(echo \$(augustus  | head -n1 | cut -f2 -d " " | sed "s/[)]//" | sed "s/[(]//" ))
    END_VERSIONS
    """
}
