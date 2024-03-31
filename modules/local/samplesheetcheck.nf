process SAMPLESHEETCHECK {
    tag "$samplesheet"
    label 'process_single'
    label 'python'

    input:
    path samplesheet

    output:
    path '*.csv'       , emit: csv
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when
    merge = mergeruns == true ? "--mergeruns" : ""

    script: // This script is bundled with the pipeline, in nf-core/metagenomicspipeline/bin/
    """
    check_samplesheet.py \\
        $samplesheet \\
        samplesheet.valid.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
