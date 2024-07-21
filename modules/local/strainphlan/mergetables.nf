process STRAINPHLAN_MERGETABLES {
    label 'process_single'

    input:
    path strainsharing
    path thresholds

    output:
    path "strainsharing_merged.csv"  , emit: straintable
    path "thresholds_merged.csv"     , emit: thresholds
    path "ngd_merged.csv"            , emit: ngd
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(tidyverse))

    if (length($strainsharing) > 0) {
        # strainsharing data
        profiles_list <- lapply($strainsharing, function(f) {
            read.csv(f, sep = ";", header = TRUE) %>%
                select(1,2,4) %>%
                pivot_wider(names_from = 1, values_from = 3)
        })
        merged_tables <- bind_cols(profiles_list)
        write.csv2(merged_tables, "strainsharing_merged.csv", row.names = FALSE)

        # NGD data
        profiles_list_dist <- lapply($strainsharing, function(f) {
            read.csv(f, sep = ",", header = TRUE) %>%
                select(1:4) %>%
                pivot_wider(names_from = c(V2, V3), values_from = V4)
        })
        merged_tables_dist <- bind_cols(profiles_list_dist)
        write.csv2(merged_tables_dist, "ngd_merged.csv", row.names = FALSE)
    } else {
        cat("No strainsharing table files to merge!\n")
    }

    if (length($thresholds) > 0) {
        thresholds_list <- lapply($thresholds, function(f) {
            read.csv(f, sep = ";", header = TRUE)
        })
        merged_tables <- bind_rows(thresholds_list)
        write.csv2(merged_tables, "thresholds_merged.csv", row.names = FALSE)
    } else {
        cat("No threshold table files to merge!\n")
    }

    writeLines(paste0("\\"${task.process}\\":\n", 
            paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = "."), "\n"),
            paste0("    tidyverse: ", packageVersion("tidyverse"), "\n")
        "versions.yml")
    """

    stub:
    def args = task.ext.args ?: ''
    
    """
    #!/usr/bin/env Rscript
    suppressPackageStartupMessages(library(tidyverse))

    writeLines(paste0("\\"${task.process}\\":\n", 
            paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = "."), "\n"),
            paste0("    tidyverse: ", packageVersion("tidyverse"), "\n")
        "versions.yml")
    """
}
