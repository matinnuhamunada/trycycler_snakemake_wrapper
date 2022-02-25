rule trycylcer_intermediate:
    input:
        cluster = "data/interim/02_trycycler_cluster/{strains}/{cluster}/"
    output:
        reconcile = 'data/interim/03_trycycler_consensus/{strains}/{cluster}_copy.log'
    threads: 12
    log:
        "workflow/report/logs/trycycler/trycylcer_intermediate-{cluster}-{strains}.log"
    params:
        cluster_file = config["clusters"]
    shell:  
        """
        python workflow/scripts/symlink_cluster.py {wildcards.strains} {wildcards.cluster} {params.cluster_file} 2>> {log}
        """ 

rule trycylcer_reconcile:
    input:
        raw_reads = 'data/interim/01_trycycler_assembly/{strains}/nanopore/min1kb.fq',
        reconcile = 'data/interim/03_trycycler_consensus/{strains}/{cluster}_copy.log',
    output:
        reconcile = 'data/interim/03_trycycler_consensus/{strains}/{cluster}/2_all_seqs.fasta'
    threads: 12
    log:
        "workflow/report/logs/trycycler/trycylcer_reconcile-{cluster}-{strains}.log"
    conda:
        "../envs/trycycler.yaml"
    params:
        cluster = "data/interim/03_trycycler_consensus/{strains}/{cluster}",
    shell:  
        """
        trycycler reconcile --threads {threads} --reads {input.raw_reads} --cluster_dir {params.cluster} 2>> {log}
        """

rule trycylcer_MSA:
    input:
        reconcile = 'data/interim/03_trycycler_consensus/{strains}/{cluster}/2_all_seqs.fasta'
    output:
        msa = 'data/interim/03_trycycler_consensus/{strains}/{cluster}/3_msa.fasta'
    threads: 12
    log:
        "workflow/report/logs/trycycler/trycylcer_MSA-{cluster}-{strains}.log"
    conda:
        "../envs/trycycler.yaml"
    params:
        cluster = "data/interim/03_trycycler_consensus/{strains}/{cluster}",
    shell:  
        """
        trycycler msa --threads {threads} --cluster_dir {params.cluster} 2>> {log}
        """

rule trycylcer_partition:
    input:
        #reconcile = 'data/interim/03_trycycler_consensus/{strains}/{cluster}_copy.log',
        msa = lambda wildcards: get_final_msa(wildcards.strains, cluster),
        raw_reads = 'data/interim/01_trycycler_assembly/{strains}/nanopore/min1kb.fq',
    output:
        partition = "data/interim/03_trycycler_consensus/{strains}/partition.log"
    threads: 12
    log:
        "workflow/report/logs/trycycler/trycylcer_partition_{strains}.log"
    conda:
        "../envs/trycycler.yaml"
    params:
        cluster = lambda wildcards: get_final_cluster(wildcards.strains, cluster)
    shell:  
        """
        trycycler partition --threads {threads} --reads {input.raw_reads} --cluster_dirs {params.cluster} 2>> {log}
        echo "partition success!" > {output.partition}
        """

rule trycylcer_consensus:
    input:
        partition = "data/interim/03_trycycler_consensus/{strains}/partition.log",
        reconcile = 'data/interim/03_trycycler_consensus/{strains}/{cluster}_copy.log',
    output:
        consensus = 'data/interim/03_trycycler_consensus/{strains}/{cluster}/7_final_consensus.fasta'
    threads: 12
    log:
        "workflow/report/logs/trycycler/trycylcer_consensus-{cluster}-{strains}.log"
    conda:
        "../envs/trycycler.yaml"
    shell:  
        """
        trycycler consensus --threads {threads} --cluster_dir data/interim/03_trycycler_consensus/{wildcards.strains}/{wildcards.cluster} 2>> {log}
        """

rule medaka_polish:
    input:
        cluster = "data/interim/03_trycycler_consensus/{strains}/{cluster}",
        consensus = 'data/interim/03_trycycler_consensus/{strains}/{cluster}/7_final_consensus.fasta'
    output:
        medaka = "data/interim/03_trycycler_consensus/{strains}/{cluster}/8_medaka.fasta"
    conda:
        "../envs/trycycler.yaml"
    threads: 12
    log:
        "workflow/report/logs/trycycler/medaka_polish-{cluster}-{strains}.log"
    params:
        model = 'r941_min_sup_g507'
    shell:
        """
        medaka_consensus -i {input.cluster}/4_reads.fastq -d {input.consensus} -o {input.cluster}/medaka -m {params.model} -t 12 2>> {log}
        mv {input.cluster}/medaka/consensus.fasta {input.cluster}/8_medaka.fasta
        #rm -r {input.cluster}/medaka {input.cluster}/*.fai {input.cluster}/*.mmi 
        """

rule trycylcer_concat:
    input:
        lambda wildcards: get_final_consensus(wildcards.strains, cluster)
    output:
        assembly = 'data/interim/03_trycycler_consensus/{strains}/assembly.fasta'
    threads: 12
    log:
        "workflow/report/logs/trycycler/trycylcer_concat-{strains}.log"
    conda:
        "../envs/trycycler.yaml"
    shell:  
        """
        cat {input} > {output.assembly} 2>> {log}
        """