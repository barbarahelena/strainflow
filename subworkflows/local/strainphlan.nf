//
// Strainphlan: consensus markers, strainphlan, extract consensus markers, strainphlan, ngd, threshold, concat tables
//

include { STRAINPHLAN_MAKEDB                            } from '../../modules/local/strainphlan/makedb.nf'
include { STRAINPHLAN_SAMPLETOMARKERS                   } from '../../modules/local/strainphlan/sampletomarkers.nf'
include { STRAINPHLAN_GETSGB                            } from '../../modules/local/strainphlan/getsgb.nf'
include { STRAINPHLAN_STRAINPHLAN                       } from '../../modules/local/strainphlan/strainphlan.nf'
include { STRAINPHLAN_EXTRACTMARKERS                    } from '../../modules/local/strainphlan/extractmarkers.nf'
include { STRAINPHLAN_TREEPAIRWISEDIST                  } from '../../modules/local/strainphlan/treepairwisedist.nf'
include { STRAINPHLAN_CALCULATETHRESHOLD                } from '../../modules/local/strainphlan/calculatethreshold.nf'
include { STRAINPHLAN_MERGETABLES                       } from '../../modules/local/strainphlan/mergetables.nf'

workflow STRAINPHLAN {
    take:
    sambz
    samplesheet
    metaphlan_table
    sample_with_n_markers
    marker_in_n_samples
    sample_markers_filter
    phylophlan_mode
    mutation_rates

    main:
    ch_versions = Channel.empty()

    STRAINPHLAN_MAKEDB( )

    STRAINPHLAN_SAMPLETOMARKERS( 
        sambz,
        STRAINPHLAN_MAKEDB.out.db
    )
    
    ch_markers = STRAINPHLAN_SAMPLETOMARKERS.out.markers.collect {it[1]}
    // ch_markers.view()
    ch_versions = ch_versions.mix(STRAINPHLAN_SAMPLETOMARKERS.out.versions)

    STRAINPHLAN_GETSGB ( 
        ch_markers,
        STRAINPHLAN_MAKEDB.out.db
    )

    if(STRAINPHLAN_GETSGB.out.clades){
        STRAINPHLAN_GETSGB.out.clades
            | splitCsv( header: true, sep: '\t' )
            | map { row -> [row.Clade] }
            | flatten()
            | set { ch_clades }
    
        STRAINPHLAN_EXTRACTMARKERS (
            ch_clades,
            STRAINPHLAN_MAKEDB.out.db
        )

        STRAINPHLAN_STRAINPHLAN( 
            ch_markers,
            STRAINPHLAN_EXTRACTMARKERS.out.dbmarkers,
            STRAINPHLAN_MAKEDB.out.db,
            sample_with_n_markers,
            marker_in_n_samples,
            sample_markers_filter,
            phylophlan_mode,
            mutation_rates
        )

        STRAINPHLAN_TREEPAIRWISEDIST( 
            STRAINPHLAN_STRAINPHLAN.out.tree
        )
        ch_versions = ch_versions.mix(STRAINPHLAN_TREEPAIRWISEDIST.out.versions)
        
        clade_info = STRAINPHLAN_STRAINPHLAN.out.info
            .join(STRAINPHLAN_STRAINPHLAN.out.aln)
            .join(STRAINPHLAN_TREEPAIRWISEDIST.out.dist)

        STRAINPHLAN_CALCULATETHRESHOLD(
            clade_info,
            samplesheet,
            metaphlan_table,
        )
        ch_versions = ch_versions.mix(STRAINPHLAN_CALCULATETHRESHOLD.out.versions)
        
        ch_sharing = STRAINPHLAN_CALCULATETHRESHOLD.out.sharing.collect { it }
        ch_thresholds = STRAINPHLAN_CALCULATETHRESHOLD.out.sharing.collect { it[1] }
        ch_sharing.view()

        STRAINPHLAN_MERGETABLES(
            ch_sharing,
            ch_thresholds
        )
        ch_versions = ch_versions.mix(STRAINPHLAN_MERGETABLES.out.versions)
    }

    emit:
    versions = ch_versions                     // channel: [ versions.yml ]
}

