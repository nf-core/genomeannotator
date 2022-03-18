process EVIDENCEMODELER_PARTITION {
    //tag "$meta.id"
    label 'process_medium'
    
    conda (params.enable_conda ? "bioconda::evidencemodeler=1.1.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/evidencemodeler:1.1.1--hdfd78af_3':
        'quay.io/biocontainers/evidencemodeler:1.1.1--hdfd78af_3' }"

    input:
    tuple val(meta), path(genome)
    path(genes)
    path(proteins)
    path(transcripts)
    path(weights)

    output:
    tuple val(meta), path(partitions), emit: partitions
    tuple val(meta), path(evm_commands), emit: commands

    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    partitions = "partitions_list.out"
    evm_commands = "commands.evm.list"
    protein_options = ""
    transcript_options = ""
    if (proteins) {
       protein_options = "--protein_alignments $proteins"   
    }
    if (transcripts) {
       transcript_options = "--transcript_alignments $transcripts"
    }
    """
    /usr/local/opt/evidencemodeler-1.1.1/EvmUtils/partition_EVM_inputs.pl --genome $genome \
       --gene_predictions $genes \
       --segmentSize 2000000 --overlapSize 200000 --partition_listing $partitions \
       $protein_options $transcript_options

    /usr/local/opt/evidencemodeler-1.1.1/EvmUtils/write_EVM_commands.pl --genome $genome \
       --weights \$PWD/${weights} \
       --gene_predictions $genes \
       --output_file_name evm.out \
       --partitions $partitions > $evm_commands

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        evidencemodeler: 1.1.0
    END_VERSIONS
    """
}
