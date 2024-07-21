process STRAINPHLAN_TREEPAIRWISEDIST {
    tag "$clade"
    label 'process_single'

    input:
    tuple   val(clade), path(tree)

    output:
    tuple val(clade), path("strainphlan_output/$clade/*_nGD.tsv")   , emit: dist
    path "versions.yml"                                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    """
    mkdir -p strainphlan_output
    mkdir -p strainphlan_output/$clade

    tree_pairwisedists.py \\
        -n $tree \\
        strainphlan_output/$clade/${clade}_nGD.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed -E 's/[^0-9]+//g')
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
