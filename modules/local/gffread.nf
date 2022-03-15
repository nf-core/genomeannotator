process GFFREAD {
    tag "$meta.id"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::gffread=0.12.7" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gffread:0.12.7--h9a82719_0':
        'quay.io/biocontainers/gffread:0.12.7--h9a82719_0' }"

    input:
    tuple val(meta), path(gff),path(fasta)
   
    output:
    tuple val(meta), path(proteins), emit: proteins
    tuple val(meta), path(cdna), emit: cdna
    tuple val(meta), path(cds), emit: cds
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    proteins = gff.getBaseName() + ".proteins.fasta"
    cdna = gff.getBaseName() + ".cdna.fasta"
    cds = gff.getBaseName() + ".cds.fasta"
    """
    gffread -y $proteins -w $cdna -x $cds -g $fasta $gff
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gffread: \$(echo \$(gffread 2>&1) | head -n1 | cut -f2 -d " " ))
    END_VERSIONS
    """
}
