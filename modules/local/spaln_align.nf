process SPALN_ALIGN {
    tag "$proteins"

    label 'process_high'

    conda (params.enable_conda ? "bioconda::spaln=2.4.7" : null)
    container "quay.io/biocontainers/spaln:2.4.7--pl5321h9a82719_1"

    input:
    path proteins
    path spaln_index
    val spaln_q
    val spaln_taxon
    val spaln_options

    output:
    path ("${chunk_name}.*"),  emit: align

    script: // This script is bundled with the pipeline, in nf-core/esga/bin/
    chunk_name = proteins.getBaseName()
    spaln_gff = chunk_name + ".gff3"
    spaln_grd = chunk_name + ".grd"

    """
       spaln -o $chunk_name -Q${spaln_q} -T${spaln_taxon} ${spaln_options} -O12 -t${task.cpus} -Dgenome_spaln $proteins

    """
}
