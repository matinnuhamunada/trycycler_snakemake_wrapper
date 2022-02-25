# Snakemake workflow: Trycycler Genome Assembly

[![Snakemake](https://img.shields.io/badge/snakemake-≥6.15.1-brightgreen.svg)](https://snakemake.github.io)

This is an experimental snakemake workflow for trying out [trycylcer](https://github.com/rrwick/Trycycler). 
It follow the author's instruction: https://github.com/rrwick/Trycycler/wiki

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

    snakemake --snakefile workflow/Snakefile-assembly --use-conda --cores <n_cores>

#### Part 2 - Clustering Contigs

    snakemake --snakefile workflow/Snakefile-cluster --use-conda --cores <n_cores>

#### Part 3 - Generating Consensus

    snakemake --snakefile workflow/Snakefile-consensus --use-conda --cores <n_cores>

See the [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/executable.html) for further snakemake CLI details.

### Step 5: Investigate results
`TO DO`