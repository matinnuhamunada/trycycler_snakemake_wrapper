rule nanoplot:
    input: 
        lambda wildcards: NANOPORE[wildcards.strains]
    output:
        directory('data/processed/{strains}/00_quality_control/nanoplot'),
    conda:
        "../envs/qc.yaml"
    threads: 2
    log:
        "workflow/report/logs/00_quality_control/{strains}/nanoplot-{strains}.log"
    shell:
        """
        NanoPlot --fastq_rich {input} -o {output} --loglength -t {threads} 2>> {log}
        """
