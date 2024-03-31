//
// Strainphlan: consensus markers, strainphlan, extract consensus markers, strainphlan, ngd, threshold, concat tables
//

include { STRAINPHLAN_SAMPLETOMARKERS                   } from '../../modules/local/strainphlan/sampletomarkers.nf'
include { STRAINPHLAN_GETSGB                            } from '../../modules/local/strainphlan/getsgb.nf'
include { STRAINPHLAN_STRAINPHLAN                       } from '../../modules/local/strainphlan/strainphlan.nf'
include { STRAINPHLAN_EXTRACTMARKERS                    } from '../../modules/local/strainphlan/extractmarkers.nf'
include { STRAINPHLAN_TREEPAIRWISEDIST                  } from '../../modules/local/strainphlan/treepairwisedist.nf'

workflow STRAINPHLAN {

    take:
    sambz
    database
    sample_with_n_markers
    marker_in_n_samples
    phylophlan_mode
    mutation_rates

    main:
    ch_versions = Channel.empty()

    STRAINPHLAN_SAMPLETOMARKERS( 
        sambz,
        database
    )

    ch_markers = STRAINPHLAN_SAMPLETOMARKERS.out.markers.collect {it[1]}

    STRAINPHLAN_GETSGB ( 
        ch_markers,
        database
    )

    if(STRAINPHLAN_GETSGB.out.clades){
        STRAINPHLAN_GETSGB.out.clades
            | splitCsv( header: true, sep: '\t' )
            | map { row -> [row.Clade] }
            | flatten()
            | set { ch_clades }
    
        STRAINPHLAN_EXTRACTMARKERS (
            ch_clades,
            database
        )

        STRAINPHLAN_STRAINPHLAN( 
            ch_markers,
            STRAINPHLAN_EXTRACTMARKERS.out.dbmarkers,
            database,
            sample_with_n_markers,
            marker_in_n_samples,
            phylophlan_mode,
            mutation_rates
        )

        STRAINPHLAN_TREEPAIRWISEDIST( 
            STRAINPHLAN_STRAINPHLAN.out.tree
        )
    }

    emit:
    versions = ch_versions                     // channel: [ versions.yml ]
}

