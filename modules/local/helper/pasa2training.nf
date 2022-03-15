process HELPER_PASA2TRAINING {
    tag "$meta.id"
    label 'process_low'
    
    if (params.enable_conda) {
        exit 1, "Conda environments cannot be used when using this version of PASA. Please use docker or singularity containers."
    }
    container 'pasapipeline/pasapipeline:2.5.2'

    input:
    tuple val(meta), path(gff)
    val(nmodels)

    output:
    tuple val(meta), path(training_gff), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    training_gff = prefix + ".pasa_training.gff3"
    """
    pasa_select_training_models.pl --nmodels $nmodels --infile $gff >> $training_gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        helper: 1.0
    END_VERSIONS
    """
}
