process STRAINPHLAN_STRAINPHLAN {
    tag "$clade"
    label 'metaphlan'
    label 'strainphlan_publish'
    label 'error_retry'

    input:
    path    consensusmarkers
    tuple   val(clade), path(dbmarkers)
    path    database
    val     sample_with_n_markers
    val     marker_in_n_samples
    val     sample_markers_filter
    val     phylophlan_mode
    val     mutation_rates
    

    output:
    tuple val(clade), path("strainphlan_output/$clade/RAxML_bestTree.*.StrainPhlAn4.tre")   , emit: tree
	tuple val(clade), path ("strainphlan_output/$clade/*.info")                             , emit: info
	tuple val(clade), path ("strainphlan_output/$clade/*.StrainPhlAn4_concatenated.aln")    , emit: aln
    path "strainphlan_output/$clade/*_mutation_rates/*"                                     , emit: mutrate
    path "versions.yml"                                                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def mr = mutation_rates ? "--mutation_rates" : ""
    def filt = sample_markers_filter ? "--sample_with_n_markers_after_filt ${sample_markers_filter}" : ""
    
    """
    INDEX=\$(find -L $database/ -name "*.pkl")
    [ -z "\$INDEX" ] && echo "Pickle file not found in $database" 1>&2 && exit 1

    mkdir -p strainphlan_output
    mkdir -p "strainphlan_output/$clade"

    strainphlan \\
        -s $consensusmarkers \\
        -m $dbmarkers \\
        -d \$INDEX \\
        -o "strainphlan_output/$clade" \\
        -n $task.cpus \\
        -c $clade \\
        $mr \\
        $filt \\
        $args \\
        --sample_with_n_markers ${sample_with_n_markers} \\
        --marker_in_n_samples ${marker_in_n_samples} \\
        --phylophlan_mode ${phylophlan_mode}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        strainphlan: \$(strainphlan --version |& sed '1!d ; s/StrainPhlAn //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        strainphlan: \$(strainphlan --version |& sed '1!d ; s/StrainPhlAn //')
    END_VERSIONS
    """
}
