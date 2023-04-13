process INFERNAL_SEARCH {
    tag "$meta.id"
    label 'process_high'
    
    conda (params.enable_conda ? "bioconda::infernal=1.1.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/infernal:1.1.4--h779adbc_0':
        'quay.io/biocontainers/infernal:1.1.4--h779adbc_0' }"

    input:
    tuple val(meta), path(fasta)
    tuple path(cm),path(i1f),path(i1i),path(i1m),path(i1p)

    output:
    tuple val(meta), path("*.tbl"), emit: tbl
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    rfam_tbl = fasta.getBaseName() + ".rfam.tbl"
    rfam_txt = fasta.getBaseName() + ".rfam.out"
    """
    cmsearch --rfam --cpu ${task.cpus} --cut_tc --tblout $rfam_tbl -o $rfam_txt $cm $fasta
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cmsearch: \$(echo \$(cmsearch -h) | head -n2 | tail -n1  | cut -f3 -d " " ))
    END_VERSIONS
    """
}
