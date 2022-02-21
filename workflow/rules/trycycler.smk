checkpoint trycylcer_cluster:
    input:
        raw_reads = 'data/raw/reads.fastq.gz',
        assembly = 'data/raw/assemblies'
    output:
        cluster=directory('data/interim/trycycler_cluster')
    threads: 12
    log:
        "workflow/report/logs/trycycler/trycycler_cluster.log"
    conda:
        "../envs/trycycler.yaml"
    shell:  
        """
        trycycler cluster --threads {threads} --reads {input.raw_reads} --assemblies {input.assembly}/*.fasta --out_dir {output.cluster} 2>> {log}
        """

def aggregate_cluster(wildcards):
    checkpoint_output = checkpoints.trycylcer_cluster.get(**wildcards).output[0]
    cluster_out = []
    glob_result = expand("{i}",i=glob_wildcards(os.path.join(checkpoint_output, "{i}")).i)
    for cluster in glob_result:
        path = os.path.join(checkpoint_output, cluster)
        if os.path.isdir(path) and not cluster.endswith('contigs'):
            cluster_out.append(f"data/interim/trycycler/{cluster}/7_final_consensus.fasta")
    print(cluster)
    return cluster_out

rule trycylcer_intermediate:
    input:
        cluster = "data/interim/trycycler_cluster/{cluster}"
    output:
        reconcile = 'data/interim/trycyler/{cluster}/copy.log'
    threads: 12
    log:
        "workflow/report/logs/trycycler/trycylcer_intermediate-{cluster}.log"
    conda:
        "../envs/trycycler.yaml"
    shell:  
        """
        cp {input.cluster} data/interim/trycyler/{wildcards.cluster}
        cat 'copy success!' > {output.reconcile}
        """ 

rule trycylcer_reconcile:
    input:
        raw_reads = 'data/raw/reads.fastq.gz',
        reconcile = 'data/interim/trycyler/{cluster}/copy.log',
    output:
        reconcile = 'data/interim/trycyler/{cluster}/2_all_seqs.fasta'
    threads: 12
    log:
        "workflow/report/logs/trycycler/trycylcer_reconcile-{cluster}.log"
    conda:
        "../envs/trycycler.yaml"
    params:
        cluster = "data/interim/trycycler/{cluster}",
    shell:  
        """
        do trycycler reconcile --reads {input.raw_reads} --cluster_dir {params.cluster} 2>> {log}
        """

rule trycylcer_MSA:
    input:
        reconcile = 'data/interim/{cluster}/2_all_seqs.fasta'
    output:
        msa = 'data/interim/{cluster}/3_msa.fasta'
    threads: 12
    log:
        "workflow/report/logs/trycycler/trycylcer_MSA-{cluster}.log"
    conda:
        "../envs/trycycler.yaml"
    params:
        cluster = "data/interim/trycycler/{cluster}",
    shell:  
        """
        trycycler msa --cluster_dir {params.cluster}
        """

#rule trycylcer_partition:
#    input:
#        msa = expand('data/interim/{cluster}/3_msa.fasta', cluster=aggregate_cluster),
#        raw_reads = 'data/raw/reads.fastq.gz',
#        cluster = expand("data/interim/trycycler/{cluster}", cluster=aggregate_cluster)
#    output:
#        partition = expand("data/interim/trycycler/{cluster}/4_reads.fastq", cluster=aggregate_cluster)
#    threads: 12
#    log:
#        "workflow/report/logs/trycycler/trycylcer_partition.log"
#    conda:
#        "../envs/trycycler.yaml"
#    shell:  
#        """
#        trycycler partition --reads {input.raw_reads} --cluster_dirs {input.cluster}
#        """

rule trycylcer_consensus:
    input:
        reconcile = 'data/interim/trycyler/{cluster}/copy.log',
    output:
        consensus = 'data/interim/trycycler/{cluster}/7_final_consensus.fasta'
    threads: 12
    log:
        "workflow/report/logs/trycycler/trycylcer_consensus-{cluster}.log"
    conda:
        "../envs/trycycler.yaml"
    shell:  
        """
        trycycler consensus --cluster_dir data/interim/trycycler/{wildcards.cluster}
        """

rule trycylcer_concat:
    input:
        aggregate_cluster
    output:
        assembly = 'data/interim/trycycler/assembly.fasta'
    threads: 12
    log:
        "workflow/report/logs/trycycler/trycylcer_concat.log"
    conda:
        "../envs/trycycler.yaml"
    shell:  
        """
        cat {input} > {output.assembly} 2>> {log}
        """