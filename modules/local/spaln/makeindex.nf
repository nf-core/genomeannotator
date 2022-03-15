process SPALN_MAKEINDEX {
    tag "$meta.id"
    label 'process_medium'
    
    conda (params.enable_conda ? "bioconda::spaln=2.4.7" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/spaln:2.4.7--pl5321h9a82719_1':
        'quay.io/biocontainers/spaln:2.4.7--pl5321h9a82719_1' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta),path("genome_spaln*"), emit: spaln_index
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cp $fasta genome_spaln.fa
    spaln -W -KP -t${task.cpus} genome_spaln.fa
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spaln: \$(echo \$( spaln 2>&1 | head -n3 | tail -n1 | cut -f4 -d " " )
    END_VERSIONS
    """
}
