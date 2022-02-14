process SAMTOOLS_MERGE_BAM {

    conda (params.enable_conda ? "bioconda::samtools:1.13" : null)
    container 'quay.io/biocontainers/samtools:1.13--h8c37831_0'

    input:
    path bams

    output:
    path merged_bam, emit: bam
    path "versions.yml", emit: versions

    script:
    merged_bam = bams[0].getSimpleName() + ".merged.bam"

    """

       cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            Samtools: \$( samtools --version" )
        END_VERSIONS

    """

}
