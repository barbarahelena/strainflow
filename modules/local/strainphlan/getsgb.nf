process STRAINPHLAN_GETSGB {
    label 'process_high'
    label 'metaphlan'
    label 'strainphlan_publish'
    label 'process_long'

    input:
    path(markers)
    path(database)

    output:
    path("clades/*.tsv")                   , emit: clades
    path "versions.yml"                    , emit: versions

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
        -n ${task.cpus} \\
        --sample_with_n_markers 20 \\
        --marker_in_n_samples 50 \\
        --sample_with_n_markers_after_filt 10 \\
		--print_clades_only \\
        -o clades

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        strainphlan: \$(strainphlan --version |& sed '1!d ; s/StrainPhlAn //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    """

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        strainphlan: \$(strainphlan --version |& sed '1!d ; s/StrainPhlAn //')
    END_VERSIONS
    """
}
