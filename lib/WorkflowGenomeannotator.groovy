//
// This file holds several functions specific to the workflow/genomeannotator.nf in the nf-core/genomeannotator pipeline
//

class WorkflowGenomeannotator {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {

        //genomeExistsError(params, log)

        if (!params.assembly) {
            log.error "Genome assembly not specified with e.g. '--assembly genome.fa'"
            System.exit(1)
        }
        if (params.assembly.contains('*')) {
            log.error "This pipeline is not currently designed to annotate multiple assemblies in parallel. Please start separate pipeline runs instead."
            System.exit(1)
        }
        if (!params.aug_species) {
            log.error "Augustus profile model not specified with e.g. '--aug_species human'"
            System.exit(1)
        }
        if (params.aug_training && !params.proteins_targeted && !params.pasa) {
            log.error "Cannot train AUGUSTUS without targeted proteins ('--proteins_targeted') OR pasa transcripts ('--pasa')"
            System.exit(1)
        }
        if (params.aug_training && !params.aug_species) {
            log.error "Cannot train AUGUSTUS without a species name ('--aug_species')"
            System.exit(1)
        }
        if (params.pasa && !params.transcripts && !params.trinity) {
            log.error "Cannot run PASA without transcripts ('--transcripts' or '--trinity')"
            System.exit(1)
        }
        if (params.trinity && !params.rnaseq_samples) {
            log.error "Cannot run Trinity assembly without RNAseq data ('--rnaseq_samples')"
            System.exit(1)
        }
        if (!params.proteins && !params.proteins_targeted && !params.transcripts && !params.rnaseq_samples) {
            log.error "This pipeline requires some form of supporting evidence as input from proteins, transcripts or RNAseq"
            System.exit(1)
        }
        if  (params.busco_lineage && !params.busco_lineage ==~ /[a-z]*_odb10/) {
            log.error "This does not look like a valid busco lineage name! Was expecting xxx_odb10!"
            System.exit(1)
        }

    }

    //
    // Get workflow summary for MultiQC
    //
    public static String paramsSummaryMultiqc(workflow, summary) {
        String summary_section = ''
        for (group in summary.keySet()) {
            def group_params = summary.get(group)  // This gets the parameters of that particular group
            if (group_params) {
                summary_section += "    <p style=\"font-size:110%\"><b>$group</b></p>\n"
                summary_section += "    <dl class=\"dl-horizontal\">\n"
                for (param in group_params.keySet()) {
                    summary_section += "        <dt>$param</dt><dd><samp>${group_params.get(param) ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>\n"
                }
                summary_section += "    </dl>\n"
            }
        }

        String yaml_file_text  = "id: '${workflow.manifest.name.replace('/','-')}-summary'\n"
        yaml_file_text        += "description: ' - this information is collected when the pipeline is started.'\n"
        yaml_file_text        += "section_name: '${workflow.manifest.name} Workflow Summary'\n"
        yaml_file_text        += "section_href: 'https://github.com/${workflow.manifest.name}'\n"
        yaml_file_text        += "plot_type: 'html'\n"
        yaml_file_text        += "data: |\n"
        yaml_file_text        += "${summary_section}"
        return yaml_file_text
    }

    //
    // Exit pipeline if incorrect --genome key provided
    //
    private static void genomeExistsError(params, log) {
        if (params.genomes && params.genome && !params.genomes.containsKey(params.genome)) {
            log.error "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n" +
                "  Genome '${params.genome}' not found in any config files provided to the pipeline.\n" +
                "  Currently, the available genome keys are:\n" +
                "  ${params.genomes.keySet().join(", ")}\n" +
                "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            System.exit(1)
        }
    }
}
