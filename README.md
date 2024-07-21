<h1>Strainflow: a StrainPhlAn pipeline to assess strainsharing</h1>

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A523.04.0-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)

[![Follow on Twitter](http://img.shields.io/badge/twitter-%40BarbaraVerhaar-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/BarbaraVerhaar)

## Introduction

**strainflow** is a bioinformatics pipeline that uses StrainPhlan to assess strainsharing between the same subjects at two different timepoints.
![strainflow](https://github.com/user-attachments/assets/6b78775b-cf6a-4d61-b5a9-25d1c357adc8)

1. Sample input check
2. [`StrainPhlAn`](https://github.com/biobakery/MetaPhlAn/wiki/StrainPhlAn-4) to get species-level genome bins (SGBs) and make a table of the number of SNPs between the sample strains and the reference genome based on the strain alignment.
    - Get SGBs
    - Extract markers
    - StrainPhlAn
    - Calculate pairwise distance
    - Calculate optimal threshold to define strainsharing
    - Merge strainsharing tables

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.tsv`:

```tsv
sampleID	subjectID	sambz	timepoint
S1000_BA	S1000	data/S1000_BA.sam.bz2	baseline
S1000_FU	S1000	data/S1000_FU.sam.bz2	follow-up
```
Each row represents a sam.bz2 file resulting from Metaphlan (4.0.5). You will also need the merged profile (txt) table as produced by Metaphlan.

Now, you can run the pipeline using:

```bash
nextflow run strainflow/main.nf \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.tsv \
   --profiles metaphlan_merged_profiles.txt \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_;
> see [docs](https://nf-co.re/usage/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/strainflow/usage) and the [parameter documentation](https://nf-co.re/strainflow/parameters).

## Pipeline output
All output of the different parts of the pipeline are stored in subdirectories of the output directory. Other important outputs are the multiqc report in the multiqc folder and the execution html report in the pipeline_info folder.

For more details on the pipeline output, please refer to the [output documentation](https://github.com/barbarahelena/strainflow/blob/master/docs/output.md).

## Credits
I used the nf-core template as much as possible and used [Eduard's strainsharing pipeline](https://github.com/EvdVossen/Metagenomic_pipeline/tree/main) and the [Biobakery documentation](https://github.com/biobakery/MetaPhlAn/wiki/Strain-Sharing-Inference-(StrainPhlan-4.1)) on strainsharing analysis with StrainPhlAn as examples.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#strainflow` channel](https://nfcore.slack.com/channels/strainflow) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations
<!-- If you use nf-core/strainflow for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
