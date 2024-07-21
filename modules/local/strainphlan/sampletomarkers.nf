process STRAINPHLAN_SAMPLETOMARKERS {
    tag "$meta.id"
    label 'process_single'
    label 'metaphlan'
    label 'strainphlan_publish'
    label 'error_retry'

    input:
    tuple val(meta), path(input)
    path(database)

    output:
    // Change this back to json.bz2 for metaphlan 4.1.1
    tuple val(meta), path("consensus_markers/*.pkl")        , emit: markers
    path "versions.yml"                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    INDEX=\$(find -L $database/ -name "*.pkl")
    [ -z "\$INDEX" ] && echo "Pickle file not found in $database" 1>&2 && exit 1

    mkdir consensus_markers
    sample2markers.py \\
        -i $input \\
        -o consensus_markers \\
        -d \$INDEX \\
        -n $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metaphlan: \$(metaphlan --version 2>&1 | awk '{print \$3}')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        strainphlan: \$(strainphlan --version |& sed '1!d ; s/StrainPhlAn //')
    END_VERSIONS
    """
}
