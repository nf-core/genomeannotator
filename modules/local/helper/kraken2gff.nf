process HELPER_KRAKEN2GFF {
    tag "$meta.id"
    label 'process_medium'
    
    conda (params.enable_conda ? "bioconda::perl-bioperl=1.7.8" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl-bioperl:1.7.2--pl526_11':
        'quay.io/biocontainers/perl-bioperl:1.7.2--pl526_11' }"

    input:
    tuple val(meta), path(gtf)

    output:
    tuple val(meta), path("*.gff"), emit: gff
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def gff = meta.id + "-" + meta.target + ".kraken.gff"

    """
    sed -i.bak 's/;\"/\"/g' $gtf
    sed -i.bak2 's/\t\t/\tensembl\t/' $gtf
    kraken2gff.pl --infile $gtf > kraken.gff
    grep -v "#" kraken.gff | sort -k1,1 -k4,4n -k5,5n -t\$'\t' >sorted.gff
    sed 's/;type.*\$//' sorted.gff > $gff
    rm *.bak* kraken.gff sorted.gff
 
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        helper: 1.0
    END_VERSIONS
    """
}
