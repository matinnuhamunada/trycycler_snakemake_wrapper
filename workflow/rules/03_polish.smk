ASSEMBLY = {k: v for (k,v) in units.assembly.to_dict().items()}

rule medaka_polish:
    input:
        consensus = lambda wildcards: ASSEMBLY[wildcards.strains],
        reads_fastq = lambda wildcards: NANOPORE[wildcards.strains],
    output:
        medaka = "data/interim/03_trycycler_consensus/{strains}/{cluster}/8_medaka.fasta"
    conda:
        "../envs/trycycler.yaml"
    threads: 8
    log:
        "workflow/report/logs/03_trycycler_consensus/medaka_polish/medaka_polish-{cluster}-{strains}.log"
    params:
        model = 'r941_min_sup_g507',
        cluster = "data/interim/03_trycycler_consensus/{strains}/{cluster}",
    shell:
        """
        medaka_consensus -i {input.reads_fastq} -d {input.consensus} -o {params.cluster}/medaka -m {params.model} -t {threads} &>> {log}
        mv {params.cluster}/medaka/consensus.fasta {params.cluster}/8_medaka.fasta
        #rm -r {params.cluster}/medaka {params.cluster}/*.fai {params.cluster}/*.mmi
        """

rule trycycler_concat:
    input:
        lambda wildcards: get_final_consensus(wildcards.strains, cluster)
    output:
        assembly = 'data/interim/03_trycycler_consensus/{strains}/assembly.fasta'
    threads: 1
    log:
        "workflow/report/logs/03_trycycler_consensus/trycycler_concat/trycycler_concat-{strains}.log"
    conda:
        "../envs/trycycler.yaml"
    shell:  
        """
        cat {input} > {output.assembly} 2>> {log}
        """

rule format_final_assembly:
    input:
        assembly = 'data/interim/03_trycycler_consensus/{strains}/assembly.fasta'
    output:
        assembly = 'data/processed/{strains}/03_trycycler_consensus/{strains}.fna'
    threads: 1
    log:
        "workflow/report/logs/03_trycycler_consensus/trycycler_format_final_assembly/trycycler_format_final_assembly-{strains}.log"
    conda:
        "../envs/trycycler.yaml"
    shell:
        """
        python workflow/scripts/format_fna.py {wildcards.strains} {input.assembly} {output.assembly} 2>> {log}
        """