process STRAINPHLAN_STRAINPHLAN {
    tag "$clade"
    label 'process_medium'
    label 'metaphlan'

    input:
    path    consensusmarkers
    tuple   val(clade), path(dbmarkers)
    path    database
    val     sample_with_n_markers
    val     marker_in_n_samples
    val     phylophlan_mode
    val     mutation_rates
    

    output:
    tuple val(clade), path("strainphlan_output/$clade/RAxML_bestTree.*.StrainPhlAn4.tre")   , emit: tree
	path "strainphlan_output/$clade/*.info"                                                 , emit: info
	path "strainphlan_output/$clade/*.StrainPhlAn4_concatenated.aln"                        , emit: aln
    path "strainphlan_output/$clade/*_mutation_rates.tsv"                                   , emit: mutrate
    path "versions.yml"                                                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def mr = mutation_rates ? "--mutation_rates" : ""
    
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
