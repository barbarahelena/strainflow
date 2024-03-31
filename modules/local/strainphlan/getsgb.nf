process STRAINPHLAN_GETSGB {
    label 'process_single'
    label 'metaphlan'

    input:
    path(markers)
    path(database)

    output:
    path("clades/*.tsv")                   , emit: clades
    path "versions.yml"                    , emit: versions

    when:
    markers.size() < 3

    script:
    def args = task.ext.args ?: ''

    """
    INDEX=\$(find -L $database/ -name "*.pkl")
    [ -z "\$INDEX" ] && echo "Pickle file not found in $database" 1>&2 && exit 1

    mkdir clades
    strainphlan \\
        -s $markers \\
        -d \$INDEX \\
        --mutation_rates \\
        --sample_with_n_markers 1 \\
        --marker_in_n_samples 1 \\
        --sample_with_n_markers_after_filt 1 \\
		--print_clades_only \\
        -o clades

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
