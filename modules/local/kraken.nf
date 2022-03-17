process KRAKEN {
    tag "$meta.id"
    label 'process_long'
    
    if (params.enable_conda) {
        exit 1, "Conda environments cannot be used when using this version of Satsuma/Kraken. Please use docker or singularity containers."
    }
    container "mhoeppner/satsuma2:1.0"

    input:
    tuple val(meta), path(query),path(target),path(target_gtf),path(chains)

    output:
    tuple val(meta), path(mapped_gtf), emit: gtf

    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    mapped_gtf = meta.id + "-" + target.getBaseName() + ".mapped.gtf"
    """
    cat $chains > satsuma_chain.out
    kraken_build_config.pl --ref_fa $target --query_fa $query --chain satsuma_chain.out > kraken.config
    RunKraken -c kraken.config -T QUERY -S REF -s $target_gtf -o $mapped_gtf -f gene,transcript,mRNA,CDS,exon

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kraken: 826be177
    END_VERSIONS
    """
}
