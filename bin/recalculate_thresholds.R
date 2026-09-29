#!/usr/bin/env Rscript
# Retrospectively recalculate strainsharing thresholds with the corrected pair counting
# (number of same-subject pairs instead of the total number of pairs).
#
# Usage:
#   Rscript recalculate_thresholds.R <ngd> <samplesheet> <outdir> [old_thresholds_merged.csv]
#
#   ngd             either a directory searched recursively for <clade>_nGD.tsv files
#                   (pipeline output: <outdir>/strainphlan/strainphlan_output/<clade>/<clade>_nGD.tsv)
#                   or ngd_merged.csv (";"-separated, decimal comma; columns sampleid_1, sampleid_2,
#                   dist_t__SGBxxx...; needs to contain all sample pairs)
#   samplesheet     samplesheet with columns sampleID, subjectID, timepoint (csv or tsv)
#   outdir          output directory
#   old_thresholds  optional thresholds_merged.csv from the original run; used to carry over
#                   taxonomy/n_markers/n_samples/aln_length/avg_gap_prop and to compare old vs new

suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(cutpointr))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) stop("Usage: recalculate_thresholds.R <ngd> <samplesheet> <outdir> [old_thresholds_merged.csv]")
ngd_input <- args[1]; samplesheet <- args[2]; outdir <- args[3]
old_thresholds <- if (length(args) >= 4) args[4] else NA
dir.create(file.path(outdir, "nGD_plots"), recursive = TRUE, showWarnings = FALSE)

# samplesheet: detect tab vs comma
first_line <- readLines(samplesheet, n = 1)
md <- read.delim(samplesheet, sep = ifelse(grepl("\t", first_line), "\t", ","),
                 header = TRUE, stringsAsFactors = FALSE) %>%
  select(sampleID, subjectID, timepoint) %>%
  mutate(across(everything(), as.character))

calc_threshold <- function(clade, nGD) {
  nGD <- nGD %>%
    left_join(md %>% select(sampleid_1 = sampleID, subjectid_1 = subjectID, timepoint_1 = timepoint),
              by = "sampleid_1") %>%
    left_join(md %>% select(sampleid_2 = sampleID, subjectid_2 = subjectID, timepoint_2 = timepoint),
              by = "sampleid_2") %>%
    mutate(relation = case_when(subjectid_1 == subjectid_2 ~ "same", .default = "different"))

  n_same <- sum(nGD$relation == "same", na.rm = TRUE)
  n_diff <- sum(nGD$relation == "different", na.rm = TRUE)
  power <- case_when(n_same > 50 ~ "many", n_same > 25 ~ "few", .default = "too few")

  threshold <- NA_real_; method <- NA_character_
  max_youden <- NA_real_; FPR <- NA_real_; FNR <- NA_real_

  if (n_same > 0 & n_diff > 0 & power != "too few") {
    nGDdiff <- nGD %>% filter(relation == "different")
    if (power == "many") {
      # Youden or 5th percentile of different-subject distances (whichever lower)
      res_youden <- cutpointr(data = nGD, x = distance, class = relation,
                              pos_class = "same", direction = "<=",
                              method = maximize_metric, metric = youden, silent = TRUE)
      cm <- as.data.frame(summary(res_youden)$confusion_matrix)
      max_youden <- res_youden$sensitivity[[1]] + res_youden$specificity[[1]] - 1
      FPR <- cm$fp / (cm$fp + cm$tn)
      FNR <- cm$fn / (cm$fn + cm$tp)
      quantile_pc <- unname(quantile(nGDdiff$distance, 0.05))
      method <- ifelse(res_youden$optimal_cutpoint[[1]] < quantile_pc, "Youden", "5thperc")
      threshold <- min(res_youden$optimal_cutpoint[[1]], quantile_pc)
    } else {
      # not enough power for Youden: 3rd percentile of different-subject distances
      threshold <- unname(quantile(nGDdiff$distance, 0.03))
      method <- "3thperc"
    }
  }

  sharing <- nGD %>%
    transmute(SGB = str_remove(clade, "t__"), sampleid_1, sampleid_2, subjectid_1, subjectid_2,
              relation, distance,
              sharing = if (is.na(threshold)) NA else distance <= threshold)

  plot <- ggplot(nGD, aes(x = distance, fill = relation)) +
    geom_density(alpha = 0.6) +
    scale_fill_manual(values = c(different = "firebrick", same = "royalblue")) +
    labs(x = "distance", y = "frequency", fill = "", title = clade) +
    annotate("text", x = Inf, y = Inf, hjust = 1, vjust = 1, size = 3,
             label = ifelse(is.na(method), str_c("<=25 same-subject pairs (n=", n_same, ")"),
                            str_c("method: ", method, "\nsame-subject pairs: ", n_same))) +
    theme_minimal() + theme(legend.position = "bottom")
  if (!is.na(threshold)) plot <- plot + geom_vline(xintercept = threshold, color = "darkgrey", linetype = "dashed")
  ggsave(plot, filename = file.path(outdir, "nGD_plots", str_c(clade, "_distance.pdf")), width = 5, height = 5)

  list(
    thresholds = tibble(SGB = str_remove(clade, "t__"), n_pairs = nrow(nGD), n_same_pairs = n_same,
                        n_different_pairs = n_diff, threshold_value = threshold, method = method,
                        max_youden = max_youden, false_positive_rate = FPR, false_negative_rate = FNR),
    sharing = sharing
  )
}

run_clade <- function(clade, nGD) {
  tryCatch(calc_threshold(clade, nGD), error = function(e) {
    message("failed for ", clade, ": ", conditionMessage(e)); NULL
  })
}

if (dir.exists(ngd_input)) {
  ngd_files <- list.files(ngd_input, pattern = "_nGD\\.tsv$", recursive = TRUE, full.names = TRUE)
  if (length(ngd_files) == 0) stop("No *_nGD.tsv files found in ", ngd_input)
  print(str_c("found ", length(ngd_files), " nGD files"))
  res <- map(ngd_files, function(f) {
    nGD <- read.delim(f, header = FALSE, stringsAsFactors = FALSE,
                      colClasses = c("character", "character", "numeric"))
    colnames(nGD) <- c("sampleid_1", "sampleid_2", "distance")
    run_clade(str_remove(basename(f), "_nGD\\.tsv$"), nGD)
  }) %>% compact()
} else {
  # merged wide table: one row per sample pair, one distance column per SGB
  print("reading merged nGD table..")
  merged <- read_delim(ngd_input, delim = ";", locale = locale(decimal_mark = ","),
                       col_types = cols(sampleid_1 = "c", sampleid_2 = "c", .default = "d"),
                       na = c("", "NA"), progress = FALSE)
  dist_cols <- str_subset(colnames(merged), "^dist_")
  print(str_c("found ", length(dist_cols), " SGBs and ", nrow(merged), " sample pairs"))
  res <- map(dist_cols, function(col) {
    nGD <- merged %>%
      select(sampleid_1, sampleid_2, distance = all_of(col)) %>%
      filter(!is.na(distance)) %>%
      as.data.frame()
    run_clade(str_remove(col, "^dist_"), nGD)
  }) %>% compact()
  rm(merged); invisible(gc())
}

thresholds <- map_dfr(res, "thresholds")
sharing <- map_dfr(res, "sharing")

if (!is.na(old_thresholds)) {
  old <- read.csv2(old_thresholds, header = TRUE, stringsAsFactors = FALSE) %>%
    mutate(SGB = as.character(SGB)) %>%
    distinct(SGB, .keep_all = TRUE)
  thresholds <- old %>%
    select(SGB, taxonomy, n_markers, n_samples, aln_length, avg_gap_prop,
           old_threshold_value = threshold_value, old_method = method) %>%
    right_join(thresholds, by = "SGB") %>%
    relocate(old_threshold_value, old_method, .after = last_col())
  print("method change old -> new:")
  print(thresholds %>% count(old_method, method))
}

write.csv2(thresholds, file.path(outdir, "thresholds_recalculated.csv"), row.names = FALSE)
write.csv2(sharing, file.path(outdir, "strainsharing_recalculated_long.csv"), row.names = FALSE)
# wide table as in the pipeline output: one row per sample pair, one sharing column per SGB
sharing %>%
  select(sampleid_1, sampleid_2, SGB, sharing) %>%
  pivot_wider(names_from = SGB, values_from = sharing, names_prefix = "sharing_t__") %>%
  write.csv2(file.path(outdir, "strainsharing_recalculated_wide.csv"), row.names = FALSE)

print(str_c("done: ", nrow(thresholds), " SGBs, ", sum(!is.na(thresholds$threshold_value)), " with a threshold"))
