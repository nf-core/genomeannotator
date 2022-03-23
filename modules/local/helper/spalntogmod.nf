process HELPER_SPALNTOGMOD {
    tag "$meta.id"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::multiqc=1.12" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.12--pyhdfd78af_0':
        'quay.io/biocontainers/multiqc:1.12--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(gff)

    output:
    tuple val(meta), path("*.gff3"), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    spaln_track = gff.getBaseName() + ".gmod.gff3"
    """
    spaln2gmod.pl --infile $gff > $spaln_track

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spalntogmod: ${workflow.manifest.version}
    END_VERSIONS
    """
}
