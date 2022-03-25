process SPALN_MERGE {
    tag "$meta.id"
    label 'process_medium'
    
    conda (params.enable_conda ? "bioconda::spaln=2.4.7" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/spaln:2.4.7--pl5321h9a82719_1':
        'quay.io/biocontainers/spaln:2.4.7--pl5321h9a82719_1' }"

    input:
    tuple val(meta), path(spaln_index)
    tuple val(meta_p),path(aligns)
    val(similarity)

    output:
    tuple val(meta), path(spaln_final), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    spaln_final = meta_p.id + "-" + meta.id + ".${similarity}.spaln_merged.gff"

    """
    sortgrcd  -I${similarity} -O0 -n0 *.grd > merged.gff
    spaln_add_exons.pl --infile merged.gff > $spaln_final
    rm merged.gff    

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spaln: \$(echo \$( spaln 2>&1 | head -n3 | tail -n1 | cut -f4 -d " " )
    END_VERSIONS
    """
}
