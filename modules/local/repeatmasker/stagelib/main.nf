process REPEATMASKER_STAGELIB {

    tag "$fasta"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::repeatmasker=4.1.5" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'https://depot.galaxyproject.org/singularity/repeatmasker:4.1.2.p1--pl5321hdfd78af_1':
                    'quay.io/biocontainers/repeatmasker:4.1.2.p1--pl5321hdfd78af_1' }"
                    
    input:
    path fasta
    val species
    path db

    output:
    path "Libraries", emit: library

    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def options = ""
    def copy_option = ""
    if (species) {
        options = "-species $species"
        copy_option = "cp $db Libraries/Dfam.h5"
    } else {
        options = "-lib $fasta"
    }
    """
    cp ${baseDir}/assets/repeatmasker/my_genome.fa .
    cp ${baseDir}/assets/repeatmasker/repeats.fa .
    cp -R /usr/local/share/RepeatMasker/Libraries .
    $copy_option
    export LIBDIR=\$PWD/Libraries
    RepeatMasker $options my_genome.fa > out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        repeatmasker: \$(echo \$(RepeatMasker -v 2> /dev/null) | cut -f3 -d " "| sed "s/[)]//") )
    END_VERSIONS
    """
}
