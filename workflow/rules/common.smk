import pandas as pd
from snakemake.utils import validate
from snakemake.utils import min_version
from pathlib import Path
import yaml

min_version("6.15.1")

##### load config and sample sheets #####

configfile: "config/config.yaml"
validate(config, schema="../schemas/config.schema.yaml")

# set up sample
samples = pd.read_csv(config["samples"], sep="\t").set_index("strain", drop=False)
samples.index.names = ["strain_id"]
validate(samples, schema="../schemas/samples.schema.yaml")

# set up units
units = pd.read_table(config["units"], dtype=str).set_index(
    ["strain"], drop=False
)
validate(units, schema="../schemas/units.schema.yaml")

##### Wildcard constraints #####
wildcard_constraints:
    sample="|".join(samples.index),
    unit="|".join(units["unit"]),

##### Helper functions #####

STRAINS = samples.strain.to_list()
ILLUMINA = {k: v for (k,v) in units.illumina_reads.to_dict().items()}
NANOPORE = {k: v for (k,v) in units.nanopore_reads.to_dict().items()}

##### Select Cluster using user provided definition
def get_clusters(filepath):
    """
    Read the clusters output and return a dictionary
    """
    with open(filepath) as file:
        # The FullLoader parameter handles the conversion from YAML
        # scalar values to Python the dictionary format
        selected_cluster = yaml.load(file, Loader=yaml.FullLoader)
    return selected_cluster

def get_final_cluster(strain, cluster):
    """
    given a dictionary of strains : cluster, return a list of the final reconcile output file
    """
    output = []
    for c in cluster[strain]:
        item = f"data/interim/03_trycycler_consensus/{strain}/{c}"
        output.append(item)
    return output

def get_final_msa(strain, cluster):
    """
    given a dictionary of strains : cluster, return a list of the final reconcile output file
    """
    output = []
    for c in cluster[strain]:
        item = f"data/interim/03_trycycler_consensus/{strain}/{c}/3_msa.fasta"
        output.append(item)
    return output

def get_final_partition(strain, cluster):
    """
    given a dictionary of strains : cluster, return a list of the final reconcile output file
    """
    output = []
    for c in cluster[strain]:
        item = f"data/interim/03_trycycler_consensus/{strain}/{c}/4_reads.fastq"
        output.append(item)
    return output

def get_final_consensus(strain, cluster):
    """
    given a dictionary of strains : cluster, return a list of the final consensus output file
    """
    output = []
    for c in cluster[strain]:
        item = f"data/interim/03_trycycler_consensus/{strain}/{c}/7_final_consensus.fasta"
        output.append(item)
    return output

cluster = get_clusters(config["clusters"])