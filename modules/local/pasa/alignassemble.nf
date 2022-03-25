process PASA_ALIGNASSEMBLE {
    tag "$meta.id"
    label 'process_high'
    
    if (params.enable_conda) {
        exit 1, "Conda environments cannot be used when using this version of PASA. Please use docker or singularity containers."
    }
    container 'pasapipeline/pasapipeline:2.5.2'

    input:
    tuple val(meta), path(genome)
    tuple val(meta_t), path(transcripts), path(transcripts_clean),path(transcripts_cln)
    path(pasa_config)
    val(max_intron_size)

    output:
    tuple val(meta), path(pasa_fa_clean),path(pasa_gff_clean),  emit: pasa_out
    tuple val(meta), path(db_name), emit: db

    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    pasa_assemblies_fasta = "pasa_DB_${prefix}.sqlite.assemblies.fasta"
    pasa_assemblies_gff = "pasa_DB_${prefix}.sqlite.pasa_assemblies.gff3"

    pasa_fa_clean = meta.id + ".pasa.fasta"
    pasa_gff_clean = meta.id + "pasa.gff3"

    db_name = "pasa_DB_" + prefix + ".sqlite"

    """
    make_pasa_config.pl --infile ${pasa_config} --trunk $prefix --outfile pasa_DB.config

    \$PASAHOME/Launch_PASA_pipeline.pl \
       --ALIGNERS blat,gmap \
       -c pasa_DB.config -C -R \
       -t $transcripts_clean \
       -T \
       -u $transcripts \
       -I $max_intron_size \
       --transcribed_is_aligned_orient \
       -g $genome \
       --CPU ${task.cpus} \

    cp $pasa_assemblies_fasta $pasa_fa_clean
    cp $pasa_assemblies_gff $pasa_gff_clean

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pasa: 2.5.2
    END_VERSIONS
    """
}
