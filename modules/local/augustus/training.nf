process AUGUSTUS_TRAINING {
    tag "$meta.id"
    label 'process_long'
    
    conda (params.enable_conda ? "bioconda::augustus=3.4.0" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/augustus:3.4.0--pl5321hd8b735c_4':
        'quay.io/biocontainers/augustus:3.4.0--pl5321hd8b735c_4' }"

    input:
    tuple val(meta), path(gff)
    tuple val(meta_g), path(genome)
    env AUGUSTUS_CONFIG_PATH
    path aug_config_dir    
    val(species)

    output:
    tuple val(meta), path(aug_config_dir), emit: augstus_config_dir
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    complete_gb = "complete_peptides.raw.gb"
    train_gb = "complete_peptides.raw.gb.train"
    test_gb = "complete_peptides.raw.gb.test"
    training_stats = "training_accuracy.out"
    options = ""
    aug_folder = "${aug_config_dir}/species/${species}"
    aug_folder_path = file(aug_folder)
    if (!aug_folder_path.exists()) {
       options = "new_species.pl --species=${species}"
    }

    """
    gff2gbSmallDNA.pl $gff $genome 1000 $complete_gb
    randomSplit.pl $complete_gb 250
    if [ ! -d $aug_folder ]; then
       $options
    fi
    etraining --species=$species --stopCodonExcludedFromCDS=true $train_gb
    augustus --stopCodonExcludedFromCDS=true --species=$species $test_gb | tee $training_stats

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        augustus: \$(echo \$(augustus  | head -n1 | cut -f2 -d " " | sed "s/[)]//" | sed "s/[(]//" ))
    END_VERSIONS
    """
}
