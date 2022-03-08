// TODO nf-core: If in doubt look at other nf-core/modules to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/modules
//               You can also ask for help via your pull request or on the #modules channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided using the "task.ext" directive, see here:
//               https://www.nextflow.io/docs/latest/process.html#ext
//               where "task.ext" is a string. 
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
// TODO nf-core: Software that can be piped together SHOULD be added to separate module files
//               unless there is a run-time, storage advantage in implementing in this way
//               e.g. it's ok to have a single module for bwa to output BAM instead of SAM:
//                 bwa mem | samtools view -B -T ref.fasta
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process PASA_ALIGNASSEMBLE {
    tag "$meta.id"
    label 'process_high'
    
    // TODO nf-core: List required Conda package(s).
    //               Software MUST be pinned to channel (i.e. "bioconda"), version (i.e. "1.10").
    //               For Conda, the build (i.e. "h9402c20_2") must be EXCLUDED to support installation on different operating systems.
    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    if (params.enable_conda) {
        exit 1, "Conda environments cannot be used when using this version of PASA. Please use docker or singularity containers."
    }
    container 'pasapipeline/pasapipeline:2.5.2'

    input:
    // TODO nf-core: Where applicable all sample-specific information e.g. "id", "single_end", "read_group"
    //               MUST be provided as an input via a Groovy Map called "meta".
    //               This information may not be required in some instances e.g. indexing reference genome files:
    //               https://github.com/nf-core/modules/blob/master/modules/bwa/index/main.nf
    // TODO nf-core: Where applicable please provide/convert compressed files as input/output
    //               e.g. "*.fastq.gz" and NOT "*.fastq", "*.bam" and NOT "*.sam" etc.
    tuple val(meta), path(genome)
    tuple val(meta_t), path(transcripts), path(transcripts_clean),path(transcripts_cln)
    path(pasa_config)
    val(max_intron_size)

    output:
    // TODO nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path(pasa_assemblies_fasta),path(pasa_assemblies_gff),  emit: pasa_out
    tuple val(meta), path(db_name), emit: db

    // TODO nf-core: List additional required output channels/values here
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    pasa_assemblies_fasta = "pasa_DB_${prefix}.sqlite.assemblies.fasta"
    pasa_assemblies_gff = "pasa_DB_${prefix}.sqlite.pasa_assemblies.gff3"
    db_name = "pasa_DB_" + prefix + ".sqlite"

    // TODO nf-core: Where possible, a command MUST be provided to obtain the version number of the software e.g. 1.10
    //               If the software is unable to output a version number on the command-line then it can be manually specified
    //               e.g. https://github.com/nf-core/modules/blob/master/modules/homer/annotatepeaks/main.nf
    //               Each software used MUST provide the software name and version number in the YAML version file (versions.yml)
    // TODO nf-core: It MUST be possible to pass additional parameters to the tool as a command-line string via the "task.ext.args" directive
    // TODO nf-core: If the tool supports multi-threading then you MUST provide the appropriate parameter
    //               using the Nextflow "task" variable e.g. "--threads $task.cpus"
    // TODO nf-core: Please replace the example samtools command below with your module's command
    // TODO nf-core: Please indent the command appropriately (4 spaces!!) to help with readability ;)
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

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pasa: 2.5.2
    END_VERSIONS
    """
}