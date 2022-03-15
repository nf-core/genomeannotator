process AUGUSTUS_FIXJOINGENES {
    tag "$meta.id"
    label 'process_medium'
    
    conda (params.enable_conda ? "bioconda::augustus=3.4.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/augustus:3.4.0--pl5262h5a9fe7b_2':
        'quay.io/biocontainers/augustus:3.4.0--pl5262h5a9fe7b_2' }"

    input:
    tuple val(meta), path(gff)

    output:
    tuple val(meta), path(fixed_gff), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    fixed_gff = gff.getBaseName() + ".fixed.gff"

    """
    fix_joingenes_gtf.pl < $gff > $fixed_gff
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        augustus: \$(echo \$(augustus  | head -n1 | cut -f2 -d " " | sed "s/[)]//" | sed "s/[(]//" ))
    END_VERSIONS
    """
}
