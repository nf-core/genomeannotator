process REPEATMASKER_STAGELIB {

    tag "$fasta"
    label 'process_low'
    
    conda (params.enable_conda ? "bioconda::repeatmasker=4.1.2.p1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/repeatmasker:4.1.2.p1--pl5321hdfd78af_1':
        'quay.io/biocontainers/repeatmasker:4.1.2.p1--pl5321hdfd78af_1' }"

    input:
    path fasta

    output:
    path "Library", emit: library

    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    
    """
       cp ${baseDir}/assets/repeatmasker/my_genome.fa .
       cp ${baseDir}/assets/repeatmasker/repeats.fa .
       mkdir -p Library
       cp ${baseDir}/assets/repeatmasker/DfamConsensus.embl Library/
       gunzip -c ${baseDir}/assets/repeatmasker/taxonomy.dat.gz > Library/taxonomy.dat
       export REPEATMASKER_LIB_DIR=\$PWD/Library
       RepeatMasker -lib $fasta my_genome.fa > out

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        repeatmasker: \$(echo \$(RepeatMasker -v 2> /dev/null) | cut -f3 -d " "| sed "s/[)]//") )
    END_VERSIONS
    """
}
