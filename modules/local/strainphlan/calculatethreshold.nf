process STRAINPHLAN_CALCULATETHRESHOLD {
    tag "$clade"
    label 'process_single'

    input:
    tuple   val(clade), path(info), path(aln), path(dist)
    path    metadata
    path    straintable

    output:
    path "strainphlan_output/nGD_plots/${clade}_distance.pdf"      , emit: plot, optional: true
    path "strainphlan_output/${clade}/thresholds_${clade}.csv"     , emit: thresholds
    path "strainphlan_output/${clade}/sharing_${clade}.csv"        , emit: sharing
    path "versions.yml"                                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    
    """
    #!/usr/bin/env Rscript
    dir.create("strainphlan_output", showWarnings = FALSE)
    dir.create(file.path("strainphlan_output", "${clade}"), showWarnings = FALSE)
    dir.create("strainphlan_output/nGD_plots", showWarnings = FALSE)

    suppressPackageStartupMessages(library(tidyverse))
    suppressPackageStartupMessages(library(ggplot2))
    suppressPackageStartupMessages(library(Biostrings))
    suppressPackageStartupMessages(library(stringr))
    suppressPackageStartupMessages(library(cutpointr))

    print('open dataframes..')
    md <- read.csv('$metadata', header = TRUE, stringsAsFactors = FALSE)
    info_sgb <- readLines('$info')
    sgb_id <- str_remove('$clade', "t__")
    sgb_tax <- read.csv('$straintable', header = TRUE, sep = '\\t', skip = 1)
    aln <- readDNAStringSet('$aln')
    sgb_tax <- sgb_tax %>% select(clade_name) %>% filter(str_detect(clade_name, "t__")) %>%
      separate(col = clade_name, into = c('taxonomy', 'sgb'), sep = 't__') %>%
      filter(sgb %in% sgb_id)
    sgb_tax\$taxonomy <- str_extract(sgb_tax\$taxonomy, "(?<=s__)[^|]+")
    nGD <- read.csv('$dist', header = FALSE, stringsAsFactors = FALSE, sep = "\\t")
    colnames(nGD) <- c("sampleid_1", "sampleid_2", "distance")
    nGD_sharing <- nGD
    colnames(nGD_sharing)[3] <- "dist_$clade"

    # Prepare distance data frame by joining with metadata
    print('prepare distance data..')
    nGD <- left_join(nGD %>% select(sampleid_1, everything()),
                            md %>% select(sampleid_1 = sampleID,
                                                  subjectid_1 = subjectID,
                                                  timepoint_1 = timepoint))
    nGD <- left_join(nGD %>% select(sampleid_2, everything()),
                            md %>% select(sampleid_2 = sampleID,
                                                  subjectid_2 = subjectID,
                                                  timepoint_2 = timepoint)) %>% 
      select(sampleid_1, sampleid_2, subjectid_1, subjectid_2, timepoint_1, timepoint_2,
          everything()) %>%
      mutate(relation = case_when(
                subjectid_1 == subjectid_2 ~ "same",
                .default = "different"
      ))
    manydifferent <- case_when(length(nGD\$relation == "same") > 50 ~ "many",
                                  length(nGD\$relation == "same") > 25 ~ "few",
                                  .default = "too few")

    # Calculate threshold
    if(nlevels(as.factor(nGD\$relation)) > 1 & manydifferent != "too few") { # if there are 2 groups
      print('calculate threshold..')
        if (manydifferent == "many") {
          # If there is enough power, Youden or 5th percentile (whichever lower)
          res_youden <- cutpointr(data = nGD, x = distance, class = relation, 
                                    method = maximize_metric, metric = youden)
          sum_youd_cm <- as.data.frame(summary(res_youden)\$confusion_matrix)
          res_youden <- res_youden %>% mutate(max_youden = sensitivity + specificity - 1,
                                              FPR = sum_youd_cm\$fp/(sum_youd_cm\$fp + sum_youd_cm\$tn),
                                              FNR = sum_youd_cm\$fn/(sum_youd_cm\$fn + sum_youd_cm\$tp)
                                              )
          nGDdiff <- nGD %>% filter(relation == "different")
          quantile_pc <- quantile(nGDdiff\$distance, 0.05)
          method <- case_when(res_youden\$optimal_cutpoint < quantile_pc ~ "Youden",
                              res_youden\$optimal_cutpoint >= quantile_pc ~ "5thperc")
          threshold <- min(res_youden\$optimal_cutpoint, quantile_pc)
        } else if (manydifferent == "few") { # If there is not enough power 3th percentile
          nGDdiff <- nGD %>% filter(relation == "different")
          quantile_pc <- quantile(nGDdiff\$distance, 0.03)
          res_youden <- data.frame(max_youden = as.numeric(""), FPR = as.numeric(""), FNR = as.numeric(""))
          threshold <- quantile_pc
          method <- "3thperc"
        }
      print(str_c("method is ", method))
      nGD_sharing\$sharing_$clade <- case_when(nGD_sharing\$dist_$clade <= threshold ~ TRUE, .default = FALSE)

      print('plot distances..')
      anno <- str_c("method: ", method, "\\n", sgb_tax\$tax)
      plot <- ggplot(data = nGD) +
        geom_density(aes(x = distance, fill = relation), alpha = 0.6) +
        geom_vline(xintercept = threshold, color = "darkgrey", linetype = "dashed") +
        theme_minimal() + 
        scale_fill_manual(values = c("firebrick", "royalblue")) + 
        labs(x = "distance", title = "${clade}", y = "frequency", fill = "") + 
        theme(legend.position = "bottom")
      plot <- plot + annotate(geom = "text", x = Inf, y = Inf, label = anno, hjust = 1, vjust = 1, size = 3)
      ggsave(plot, filename = "strainphlan_output/nGD_plots/${clade}_distance.pdf", width = 5, height = 5)

    } else { # too few samples, make empty table
      print("too few samples to calculate threshold")
      res_youden <- data.frame(max_youden = as.numeric(""), FPR = as.numeric(""), FNR = as.numeric(""))
      nGD_sharing\$sharing_$clade <- ""; threshold <- ""; method <- ""

      print('plot distances..')
      anno <- str_c("<25 same-subject samples", "\\n", sgb_tax\$tax)
      plot <- ggplot(data = nGD) +
        geom_density(aes(x = distance, fill = relation), alpha = 0.6) +
        theme_minimal() + 
        scale_fill_manual(values = c("firebrick", "royalblue")) + 
        labs(x = "distance", y = "frequency", fill = "", title = "${clade}") + 
        theme(legend.position = "bottom")
      plot <- plot + annotate(geom = "text", x = Inf, y = Inf, label = anno, hjust = 1, vjust = 1, size = 3)
      ggsave(plot, filename = "strainphlan_output/nGD_plots/${clade}_distance.pdf", width = 5, height = 5)
    }

    print('prepare output table..')
    table_output <- data.frame(
      SGB = sgb_tax\$sgb,
      taxonomy = sgb_tax\$taxonomy,
      n_markers = str_extract(info_sgb[12], "[0-9]+"),
      n_samples = str_extract(info_sgb[13], "[0-9]+"),
      aln_length = nchar(as.character(aln)[[1]]),
      avg_gap_prop = length(str_extract_all(as.character(aln[[1]]), "-")[[1]]) / nchar(as.character(aln)[[1]]),
      threshold_value = threshold, method = method,
      max_youden = res_youden\$max_youden[[1]],
      false_positive_rate = res_youden\$FPR,
      false_negative_rate = res_youden\$FNR
    )

    # Write output csvs
    print('write output csvs..')
    write.csv2(table_output, 'strainphlan_output/${clade}/thresholds_${clade}.csv', row.names = FALSE)
    write.csv2(nGD_sharing, 'strainphlan_output/${clade}/sharing_${clade}.csv', row.names = FALSE)

    # Record versions
    writeLines(paste0("\\"${task.process}\\":\n", 
            paste0("    R: ", paste0(R.Version()[c("major","minor")], collapse = "."), "\n"),
            paste0("    tidyverse: ", packageVersion("tidyverse"), "\n"),
            paste0("    stringr: ", packageVersion("stringr"), "\n"),
            paste0("    ggplot2: ", packageVersion("ggplot2"), "\n"),
            paste0("    cutpointr: ", packageVersion("cutpointr"), "\n"),
            paste0("    Biostrings: ", packageVersion("Biostrings"))), 
        "versions.yml")
    """

    stub:
    def args = task.ext.args ?: ''
    """
    
    """
}
