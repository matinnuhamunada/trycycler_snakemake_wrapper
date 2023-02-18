rule illumina_qc:
    input:
        illumina_reads = lambda wildcards: ILLUMINA[wildcards.strains]
    output:
        out1 = temp('data/interim/04_trycycler_polish/{strains}/illumina/1.fastq.gz'),
        out2 = temp('data/interim/04_trycycler_polish/{strains}/illumina/2.fastq.gz'),
        unpaired = temp('data/interim/04_trycycler_polish/{strains}/illumina/u.fastq.gz'),
    threads: 4
    log:
        "workflow/report/logs/05_unicycler/fastp/illumina_qc-{strains}.log"
    conda:
        "../envs/polish.yaml"
    shell:  
        """
        echo {input.illumina_reads}/{wildcards.strains}*R1*.fastq {input.illumina_reads}/{wildcards.strains}*R2*.fastq 2>> {log}
        fastp --in1 {input.illumina_reads}/{wildcards.strains}*R1*.fastq --in2 {input.illumina_reads}/{wildcards.strains}*R2*.fastq --out1 {output.out1} --out2 {output.out2} --unpaired1 u.fastq.gz --unpaired2 {output.unpaired} 2>> {log}
        """

rule unicycler:
    input:
        out1 = 'data/interim/04_trycycler_polish/{strains}/illumina/1.fastq.gz',
        out2 = 'data/interim/04_trycycler_polish/{strains}/illumina/2.fastq.gz',
        unpaired = 'data/interim/04_trycycler_polish/{strains}/illumina/u.fastq.gz',
    output:
        unicycler = directory("data/interim/05_unicycler/{strains}")
    threads: 4
    log:
        "workflow/report/logs/05_unicycler/unicycler/unicycler-{strains}.log"
    conda:
        "../envs/unicycler.yaml"
    shell:
        """
        unicycler -1 {input.out1} -2 {input.out2} -s {input.unpaired} -o {output.unicycler} --threads {threads} &>> {log}
        """

rule copy_unicycler:
    input:
        unicycler = "data/interim/05_unicycler/{strains}"
    output:
        graph = 'data/processed/{strains}/05_unicycler/{strains}.png',
        gfa = 'data/processed/{strains}/05_unicycler/{strains}.gfa',
        fasta = 'data/processed/{strains}/05_unicycler/{strains}.fna'
    log:
        "workflow/report/logs/05_unicycler/{strains}/bandage/{strains}.log"
    conda:
        "../envs/utilities.yaml"
    shell:
        """
        Bandage image {input.unicycler}/assembly.gfa {output.graph} &>> {log}
        cp {input.unicycler}/assembly.gfa {output.gfa} 2>> {log}
        cp {input.unicycler}/assembly.fasta {output.fasta} 2>> {log}
        """