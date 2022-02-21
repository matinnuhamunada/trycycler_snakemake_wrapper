import pandas as pd
from snakemake.utils import validate
from snakemake.utils import min_version

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
