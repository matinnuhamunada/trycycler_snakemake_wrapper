rule assemble_flye_only:
    input:
        'data/interim/01_trycycler_assembly/{strains}/nanopore/min1kb.fq',
    output:
        flye = directory('data/processed/{strains}/06_flye_only/assembly_{strains}'),
    threads: 8
    log:
        "logs/06_flye_only/{strains}/assemble_flye/assemble_flye-{strains}.log"
    conda:
        "../envs/utilities.yaml"
    shell:
        """
        flye --nano-hq {input} --threads {threads} --out-dir {output.flye} 2>> {log}
        """

rule medaka_polish_flye:
    input:
        flye = 'data/processed/{strains}/06_flye_only/assembly_{strains}',
        fastq = 'data/interim/01_trycycler_assembly/{strains}/nanopore/min1kb.fq',
    output:
        medaka = "data/interim/06_flye_only/{strains}/medaka.fasta"
    conda:
        "../envs/trycycler.yaml"
    threads: 8
    log:
        "logs/06_flye_only/medaka_polish/medaka_polish-{strains}.log"
    params:
        model = config['basecaller']['medaka_model'],
    shell:
        """
        medaka_consensus -i {input.fastq} -d {input.flye} -o data/interim/06_flye_only/{wildcards.strains}/medaka -m {params.model} -t {threads} &>> {log}
        mv data/interim/06_flye_only/{wildcards.strains}/medaka/consensus.fasta {output.medaka}
        """
