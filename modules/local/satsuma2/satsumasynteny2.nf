process SATSUMA2_SATSUMASYNTENY2 {
    tag "${meta.id} | ${meta_t.id}"
    label 'satsuma'
    
    if (params.enable_conda) {
        exit 1, "Conda environments cannot be used when using this version of Satsuma2. Please use docker or singularity containers."
    }
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/satsuma2:20161123--h7d875b9_3':
        'quay.io/biocontainers/satsuma2:20161123--h7d875b9_3' }"

    input:
    tuple val(meta),path(query),val(meta_t),path(target),path(target_gtf)

    output:
    tuple val(meta),path(query),path(target),path(target_gtf),path(satsuma_chain_chunk), emit: chain
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    satsuma_chain_chunk = query.getBaseName() + "-" + meta_t.id + ".satsuma_summary.chained.out"
    // Satsuma is extremely chatty, need to redirect logs to /dev/null
    """

    export SATSUMA2_PATH=/usr/local/bin

    SatsumaSynteny2 -q $query -t $target -threads ${task.cpus} -o align 2>&1 >/dev/null
    cp align/satsuma_summary.chained.out $satsuma_chain_chunk

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        satsuma2: 20161123
    END_VERSIONS
    """
}
