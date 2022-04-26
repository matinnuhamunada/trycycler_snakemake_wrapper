# Snakemake workflow: Trycycler Genome Assembly

[![Snakemake](https://img.shields.io/badge/snakemake-≥6.15.1-brightgreen.svg)](https://snakemake.github.io)

This is a snakemake wrapper to run [trycylcer](https://github.com/rrwick/Trycycler). The sub-workflows are divided into three different steps, following the original author's instruction: https://github.com/rrwick/Trycycler/wiki. See [step 4](#step-4-executing-the-workflow) for how to run the subworkflows.

## Usage
### Step 1: Clone the workflow

[Clone](https://help.github.com/en/articles/cloning-a-repository) this repository to your local system, into the place where you want to perform the data analysis. 

    git git@github.com:matinnuhamunada/genome_assembly_tryouts.git
    cd genome_assembly_tryouts

### Step 2: Get example data
```shell
mkdir -p data/raw/GCF_000012125
wget -O data/raw/GCF_000012125/23754659.tar.gz https://bridges.monash.edu/ndownloader/files/23754659
(cd data/raw/GCF_000012125 && tar -xvzf 23754659.tar.gz)
```
### Step 3: Configure workflow
#### Setting Up Your Samples Information
Configure the workflow according to your needs via editing the files in the `config/` folder. Adjust `config.yaml` to configure the workflow execution, and `samples.tsv` to specify the strains to assemble. The file `units.tsv` contains the location of the paired illumina and nanopore reads for each strain.

`samples.tsv` example:

|  strain       |       description |
|--------------:|------------------:|
| GCF_000012125 | Example |

`units.tsv` example:

|  strain       |  unit |    illumina_reads |               nanopore_reads |
|--------------:|------:|------------------:|-----------------------------:|
| GCF_000012125 | 1     |                   | data/raw/GCF_000012125.1     |

Further formatting rules will be defined in the `workflow/schemas/` folder.

### Step 3: Install Snakemake

Installing Snakemake using [Mamba](https://github.com/mamba-org/mamba) is advised. In case you don’t use [Mambaforge](https://github.com/conda-forge/miniforge#mambaforge) you can always install [Mamba](https://github.com/mamba-org/mamba) into any other Conda-based Python distribution with:

    conda install -n base -c conda-forge mamba

Then install Snakemake with:

    mamba create -c conda-forge -c bioconda -n snakemake snakemake

For installation details, see the [instructions in the Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).

### Step 4: Executing the workflow

Activate the conda environment:

    conda activate snakemake

#### Part 1 - Generating Assemblies
This step generates multiple assemblies as described in: https://github.com/rrwick/Trycycler/wiki/Generating-assemblies

    snakemake --snakefile workflow/Snakefile-assembly --use-conda --cores <n_cores>

TO DO: Generate a bandage gfa graph for each assemblies for manual curation
#### Part 2 - Clustering Contigs
This step clusters the assemblies into per-replicon groups as described in: https://github.com/rrwick/Trycycler/wiki/Clustering-contigs

    snakemake --snakefile workflow/Snakefile-cluster --use-conda --cores <n_cores>

This step also generate `data/interim/02_trycycler_cluster/cluster.yaml` which should be copied to the config folder in order to proceed to the next step. NOTE: You can select or drops the bad contigs or clusters that will ber run in the next step

TO DO: Generate a tree image with necessary information (size, depth) for manual curation of the clusters
#### Part 3 - Generating Consensus
This step summarizes step 3, 4, 5, and 6 in the Trycycler wiki and generate the consensus contig sequence as described in: https://github.com/rrwick/Trycycler/wiki/Generating-a-consensus


    snakemake --snakefile workflow/Snakefile-consensus --use-conda --cores <n_cores>

See the [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/executable.html) for further snakemake CLI details.

### Step 5: Investigate results
`TO DO`
