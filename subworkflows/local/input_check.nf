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
        .map { create_meta_channel(it) }
        .set { sambz }

    emit:
    sambz                                    
    samplesheet = SAMPLESHEETCHECK.out.csv
    versions = SAMPLESHEETCHECK.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ sambz ] ]
def create_meta_channel(LinkedHashMap row) {
    // Create meta map
    def meta = [:]
    meta.id = row.sampleID
    meta.subject = row.subjectID

    // Add path(s) of the sambz file to the meta map
    def file_meta = []
    if (!file(row.sambz).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Sambz2 file does not exist!\n${row.sambz}"
    }
    file_meta = [meta, [file(row.sambz)]]
    return file_meta
}