//
// Check input samplesheet and get read channels
//

include { SAMPLESHEETCHECK } from '../../modules/local/samplesheetcheck'

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEETCHECK ( samplesheet )
        .csv
        .splitCsv ( header:true, sep:',' )
        .map { create_paired_channel(it) }
        .set { paths }

    emit:
    paths                                     // channel: [ val(meta), [ reads ] ]
    versions = SAMPLESHEETCHECK.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def create_paired_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id         = row.sample

    // add path(s) of the fastq file(s) to the meta map
    def paired_meta = []
    if (!file(row.sample1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Sample 1 sambz file does not exist!\n${row.sample1}"
    }
    if (meta.single_end) {
        paired_meta = [ meta, [ file(row.sample1) ] ]
    } else {
        if (!file(row.sample2).exists()) {
            exit 1, "ERROR: Please check input samplesheet -> Sample 2 sambz file does not exist!\n${row.sample2}"
        }
        paired_meta = [ meta, [ file(row.sample1), file(row.sample2) ] ]
    }
    return paired_meta
}
