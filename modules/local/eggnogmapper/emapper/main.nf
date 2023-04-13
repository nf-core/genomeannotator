process EGGNOGMAPPER_EMAPPER {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "eggnog-mapper=2.1.7" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/eggnog-mapper:2.1.7--pyhdfd78af_0 ':
        'quay.io/biocontainers/eggnog-mapper:2.1.7--pyhdfd78af_0 ' }"

    input:
    tuple val(meta), path(gff),path(proteins)
    path(db)

    output:
    tuple val(meta), path("*decorated.gff"), emit: gff
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def sorted = gff.getBaseName() + ".sorted.gff3"
    def decorated = gff.getBaseName() + ".decorated.gff"
    """
    grep -v "#" $gff | sort -k1,1 -k4,4n -k5,5n -t\$'\t' | grep -v "^\$" >> $sorted

    emapper.py -m diamond -i $proteins --decorate_gff $sorted --itype proteins -o eggnog --cpu ${task.cpus} --data_dir $db
    mv *decorated.gff $decorated
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eggnogmapper: \$(echo \$(emapper.py -v | tail -n1 | cut -f1 -d " " | sed 's/emapper-//' ))
    END_VERSIONS
    """
}
