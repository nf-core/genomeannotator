process HELPER_DOWNLOADRFAM {
    tag 'Rfam14'
    label 'process_low'
    
    executor 'local'

    conda (params.enable_conda ? "bioconda::multiqc=1.12" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.12--pyhdfd78af_0':
        'quay.io/biocontainers/multiqc:1.12--pyhdfd78af_0' }"

    input:
    tuple val(meta),path(fasta)

    output:
    path("*.cm"), emit: cm
    path("*.txt"), emit: txt
    
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    
    """
    wget ftp://ftp.ebi.ac.uk/pub/databases/Rfam/14.2/Rfam.cm.gz
    gunzip Rfam.cm.gz
    wget ftp://ftp.ebi.ac.uk/pub/databases/Rfam/14.2/database_files/family.txt.gz
    gunzip family.txt.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$(echo \$(wget --version) |  head -n1 | cut -f3 -d " " ))
    END_VERSIONS
    """
}
