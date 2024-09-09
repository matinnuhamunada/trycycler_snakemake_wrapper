rule final_qc:
    input:
        assembly = 'data/processed/{strains}/03_trycycler_consensus/{strains}.fna',
        raw_reads = 'data/interim/01_trycycler_assembly/{strains}/nanopore/min1kb.fq',
    output:
        index_assembly = 'data/processed/{strains}/04_final_qc/{strains}.mmi',
        aligned_reads_sam = 'data/processed/{strains}/04_final_qc/{strains}.sam',
        aligned_reads_bam = temp('data/processed/{strains}/04_final_qc/{strains}.bam'),
        aligned_reads_bam_sorted = 'data/processed/{strains}/04_final_qc/{strains}_sorted.bam',
        depth = 'data/processed/{strains}/04_final_qc/{strains}_depth.txt',
    threads: 4
    log:
        "logs/04_final_qc/final_qc-{strains}.log"
    conda:
        "../envs/utilities.yaml"
    shell:
        """
        # Step 1: Index the genome (optional for minimap2)
        minimap2 -d {output.index_assembly} {input.assembly} 2>> {log}

        # Step 2: Align the reads
        minimap2 -ax map-ont -t {threads} {output.index_assembly} {input.raw_reads} > {output.aligned_reads_sam} 2>> {log}

        # Step 3: Convert SAM to BAM
        samtools view -@ {threads} -S -b {output.aligned_reads_sam} > {output.aligned_reads_bam} 2>> {log}

        # Step 4: Sort the BAM file
        samtools sort -@ {threads} {output.aligned_reads_bam} -o {output.aligned_reads_bam_sorted} 2>> {log}

        # Step 5: Calculate depth
        samtools depth {output.aligned_reads_bam_sorted} > {output.depth} 2>> {log}
        """
