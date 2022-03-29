process REPEATMASKER_REPEATMASK {
    tag "$meta.id"
    label 'process_high'
    
    conda (params.enable_conda ? "bioconda::repeatmasker=4.1.2.p1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/repeatmasker:4.1.2.p1--pl5321hdfd78af_1':
        'quay.io/biocontainers/repeatmasker:4.1.2.p1--pl5321hdfd78af_1' }"

    input:
    tuple val(meta), path(fasta)
    env LIBDIR
    path rm_lib
    val rm_species

    output:
    tuple val(meta), path("*.masked"), emit: masked
    tuple val(meta), path(rm_gff), emit: gff
    tuple val(meta), path(rm_tbl), emit: tbl
    tuple val(meta), path(rm_out), emit: rm_out
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    base_name = fasta.getName()
    genome_rm = base_name + ".masked"
    rm_gff = base_name + ".out.gff"
    rm_tbl = base_name + ".tbl"
    rm_out = base_name + ".out"
    def options = ""
    if (rm_species) {
       options = "-species $rm_species"
    } else {
       options = "-lib $rm_lib"
    }
    """
    echo \$LIBDIR > lib.txt
    RepeatMasker $options -gff -xsmall -q -nolow -pa ${task.cpus} $fasta
    test -f ${genome_rm} || cp $fasta $genome_rm && touch $rm_gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        repeatmasker: \$(echo \$(RepeatMasker -v 2> /dev/null) | cut -f3 -d " "| sed "s/[)]//") )
    END_VERSIONS
    """
}
