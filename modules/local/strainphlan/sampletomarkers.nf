process STRAINPHLAN_SAMPLETOMARKERS {
    tag "$meta.id"
    label 'process_single'
    label 'metaphlan'

    input:
    tuple val(meta), path(input)
    path(database)

    output:
    tuple val(meta), path("consensus_markers/*.pkl")  , emit: markers
    path "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir consensus_markers
    sample2markers.py \\
        -i $input \\
        -o consensus_markers \\
        -d $database \\
        -n $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        strainphlan: \$(strainphlan --version |& sed '1!d ; s/StrainPhlAn //')
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
