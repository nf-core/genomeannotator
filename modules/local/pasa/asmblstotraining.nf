process PASA_ASMBLSTOTRAINING {
    tag "$meta.id"
    label 'process_medium'
    
    if (params.enable_conda) {
        exit 1, "Conda environments cannot be used when using this version of PASA. Please use docker or singularity containers."
    }
    container 'pasapipeline/pasapipeline:2.5.2'

    input:
    tuple val(meta), path(fasta),path(gff)

    output:
    tuple val(meta), path('*.genome.gff3'), emit: gff
    tuple val(meta), path('*.transdecoder.pep'), emit: fasta
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    \$PASAHOME/scripts/pasa_asmbls_to_training_set.dbi \
       --pasa_transcripts_fasta $fasta \
       --pasa_transcripts_gff3 $gff 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pasa: 2.5.2
    END_VERSIONS
    """
}
