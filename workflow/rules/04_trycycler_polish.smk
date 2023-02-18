rule illumina_qc:
    input:
        illumina_reads = lambda wildcards: ILLUMINA[wildcards.strains]
    output:
        out1 = temp('data/interim/04_trycycler_polish/{strains}/illumina/1.fastq.gz'),
        out2 = temp('data/interim/04_trycycler_polish/{strains}/illumina/2.fastq.gz'),
        unpaired = temp('data/interim/04_trycycler_polish/{strains}/illumina/u.fastq.gz'),
    threads: 4
    log:
        "workflow/report/logs/04_trycycler_polish/illumina_qc/illumina_qc-{strains}.log"
    conda:
        "../envs/polish.yaml"
    shell:  
        """
        fastp --in1 {input.illumina_reads}/*_L2_1.fq.gz --in2 {input.illumina_reads}/*_L2_2.fq.gz --out1 {output.out1} --out2 {output.out2} --unpaired1 u.fastq.gz --unpaired2 {output.unpaired} 2>> {log}
        """

rule polypolish:
    input:
        out1 = 'data/interim/04_trycycler_polish/{strains}/illumina/1.fastq.gz',
        out2 = 'data/interim/04_trycycler_polish/{strains}/illumina/2.fastq.gz',
        assembly = 'data/processed/{strains}/03_trycycler_consensus/{strains}.fna'
    output:
        polypolish = temp('data/interim/04_trycycler_polish/{strains}/polypolish/polypolish.fasta'),
        bwa1 = temp('data/interim/04_trycycler_polish/{strains}/polypolish/alignments_1.sam'),
        bwa2 = temp('data/interim/04_trycycler_polish/{strains}/polypolish/alignments_2.sam'),
    threads: 4
    log:
        "workflow/report/logs/04_trycycler_polish/polypolish/polypolish-{strains}.log"
    conda:
        "../envs/polish.yaml"
    shell:
        """
        bwa index {input.assembly} 2>> {log}
        bwa mem -t {threads} -a {input.assembly} {input.out1} > {output.bwa1} 2>> {log}
        bwa mem -t {threads} -a {input.assembly} {input.out1} > {output.bwa2} 2>> {log}
        polypolish {input.assembly} {output.bwa1} {output.bwa2} > {output.polypolish} 2>> {log}
        """

rule polca:
    input:
        polypolish = 'data/interim/04_trycycler_polish/{strains}/polypolish/polypolish.fasta',
        out1 = 'data/interim/04_trycycler_polish/{strains}/illumina/1.fastq.gz',
        out2 = 'data/interim/04_trycycler_polish/{strains}/illumina/2.fastq.gz',
    output:
        polca = temp('data/interim/04_trycycler_polish/{strains}/polca/polypolish.fasta.PolcaCorrected.fa'),
    threads: 4
    log:
        "workflow/report/logs/04_trycycler_polish/polca/polca-{strains}.log"
    conda:
        "../envs/polish.yaml"
    params:
        memory="1G",
        polca="/datadrive/apps/masurca/MaSuRCA-4.1.0/bin/polca.sh"
    shell:
        """
        (cd data/interim/04_trycycler_polish/{wildcards.strains}/polca && {params.polca} -a ../polypolish/polypolish.fasta -r '../illumina/1.fastq.gz ../illumina/1.fastq.gz' -t {threads} -m {params.memory}) 2>> {log}
        """

rule copy_polca:
    input:
        polca = 'data/interim/04_trycycler_polish/{strains}/polca/polypolish.fasta.PolcaCorrected.fa',
    output:
        polished = 'data/processed/{strains}/04_trycycler_polish/{strains}.fna'
    threads: 4
    log:
        "workflow/report/logs/04_trycycler_polish/copy/{strains}.log"
    shell:
        """
        cp {input.polca} {output.polished} 2>> {log}
        """