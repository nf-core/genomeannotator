process SPALN_MAKE_INDEX {
    tag "$fa"
    
    label 'process_high' 

    conda (params.enable_conda ? "bioconda::spaln=2.4.7" : null)
    container "quay.io/biocontainers/spaln:2.4.7--pl5321h9a82719_1"

    input:
    path fa

    output:
    path("genome_spaln*"), emit: spaln_index

    script: // This script is bundled with the pipeline, in nf-core/esga/bin/
    """
       cp $fa genome_spaln.fa
       spaln -W -KP -t${task.cpus} genome_spaln.fa
    """
}
