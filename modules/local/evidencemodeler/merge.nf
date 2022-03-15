process EVIDENCEMODELER_MERGE {
    tag "$meta.id"
    label 'process_medium'
    
    conda (params.enable_conda ? "bioconda::evidencemodeler=1.1.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/evidencemodeler:1.1.1--hdfd78af_3':
        'quay.io/biocontainers/evidencemodeler:1.1.1--hdfd78af_3' }"

    input:
    tuple val(meta), path(partitions)
    tuple val(meta_e),path(logs)
    tuple val(meta_g),path(genome)

    output:
    tuple val(meta), path(partitions), emit: partitions
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    evm_out = "evm.out"
    """
    /usr/local/opt/evidencemodeler-1.1.1/EvmUtils/recombine_EVM_partial_outputs.pl --partitions $partitions --output_file_name evm.out
    /usr/local/opt/evidencemodeler-1.1.1/EvmUtils/convert_EVM_outputs_to_GFF3.pl  --partitions $partitions --output $evm_out --genome $genome
    touch done.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        evidencemodeler: 1.1.0
    END_VERSIONS
    """
}
