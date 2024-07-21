process STRAINPHLAN_EXTRACTMARKERS {
    tag "$clade"
    label 'process_medium'
    label 'metaphlan'
    label 'strainphlan_publish'
    label 'error_retry'

    input:
    val(clade)
    path(database)

    output:
    tuple val(clade), path("db_markers/*.fna")  , emit: dbmarkers
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir db_markers
    INDEX=\$(find -L $database/ -name "*.pkl")
    [ -z "\$INDEX" ] && echo "Pickle file not found in $database" 1>&2 && exit 1

    extract_markers.py \\
        -c $clade \\
        -o db_markers \\
        -d \$INDEX

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
