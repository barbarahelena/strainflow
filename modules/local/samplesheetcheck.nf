process SAMPLESHEETCHECK {
    tag "$samplesheet"
    label 'process_single'
    label 'python'

    input:
    path samplesheet

    output:
    path 'samplesheet.valid.csv'       , emit: csv
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
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
