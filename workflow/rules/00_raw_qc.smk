rule nanopore_quality_assessment:
    input:
        raw_reads=lambda wildcards: NANOPORE[wildcards.strains],
    output:
        outdir=directory("data/processed/{strains}/00_raw_qc/{strains}_nanoplot"),
    log:
        "logs/raw_qc/nanoplot/{strains}.log"
    params:
        prefix="{strains}_nanoplot"
    threads: 4
    conda:
        "../envs/utilities.yaml"
    shell:
        """
        NanoPlot --fastq {input.raw_reads} \
            --outdir {output.outdir} \
            --prefix {params.prefix} \
            --tsv_stats \
            -t {threads} \
            --raw \
            -f svg \
            --verbose &>> {log} 2>&1
        """

rule kraken2_install:
    output:
        dir=directory("resources/kraken2_db")
    log:
        "logs/raw_qc/kraken2/kraken2_install.log"
    conda:
        "../envs/utilities.yaml"
    shell:
        """
        mkdir -p {output.dir}
        kraken2-build --standard --db {output.dir} &>> {log}
        """

rule kraken2_classification:
    input:
        "resources/kraken2_db",
        raw_reads=lambda wildcards: NANOPORE[wildcards.strains]
    output:
        report="data/processed/{strains}/00_raw_qc/{strains}_kraken2_report.txt",
        classified="data/processed/{strains}/00_raw_qc/{strains}_kraken2_classified.fastq",
        unclassified="data/processed/{strains}/00_raw_qc/{strains}_kraken2_unclassified.fastq"
    log:
        "logs/raw_qc/kraken2/{strains}.log"
    params:
        db="path/to/kraken2_db"
    threads: 4
    conda:
        "../envs/utilities.yaml"
    shell:
        """
        kraken2 --db {params.db} \
                --threads {threads} \
                --report {output.report} \
                --classified-out {output.classified} \
                --unclassified-out {output.unclassified} \
                {input.raw_reads} &>> {log}
        """
