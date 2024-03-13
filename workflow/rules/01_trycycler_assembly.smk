rule clean_nanopore:
    input: 
        lambda wildcards: NANOPORE[wildcards.strains]
    output:
        temp('data/interim/01_trycycler_assembly/{strains}/nanopore/porechop.fq'),
    conda:
        "../envs/utilities.yaml"
    threads: 4
    log:
        "logs/01_trycycler_assembly/{strains}/clean_nanopore-{strains}.log"
    shell:
        """
        porechop -t {threads} -i {input} -o {output} &>> {log}
        """

rule filter_length:
    input: 
        'data/interim/01_trycycler_assembly/{strains}/nanopore/porechop.fq',
    output:
        'data/interim/01_trycycler_assembly/{strains}/nanopore/min1kb.fq'
    conda:
        "../envs/utilities.yaml"
    log:
        "logs/01_trycycler_assembly/{strains}/filter_length-{strains}.log"
    params:
        min_length = 1000,
        keep_percent = 95
    shell:
        """
        filtlong --min_length {params.min_length} --keep_percent {params.keep_percent} {input} > {output} 2>> {log}
        """

rule subsample:
    input:
        'data/interim/01_trycycler_assembly/{strains}/nanopore/min1kb.fq'
    output:
        temp(expand('data/interim/01_trycycler_assembly/{{strains}}/nanopore/read_subsets/sample_{subsample}.fastq', subsample=['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']))
    threads: 12
    log:
        "logs/01_trycycler_assembly/{strains}/subsample-{strains}.log"
    conda:
        "../envs/trycycler.yaml"
    params:
        outdir = 'data/interim/01_trycycler_assembly/{strains}/nanopore/read_subsets/',
        n_subsample = 12
    shell:  
        """
        trycycler subsample --count {params.n_subsample} --threads {threads} --reads {input} --out_dir {params.outdir} 2>> {log}
        """

rule assemble_flye:
    input:
        'data/interim/01_trycycler_assembly/{strains}/nanopore/read_subsets/sample_{subsample}.fastq'
    output:
        assembly = 'data/interim/01_trycycler_assembly/{strains}/nanopore/assemblies/assembly_{subsample}.fasta',
        flye = directory('data/interim/01_trycycler_assembly/{strains}/nanopore/assemblies/assembly_{subsample}'),
        graph = 'data/interim/01_trycycler_assembly/{strains}/nanopore/assemblies/assembly_{subsample}.gfa',
    threads: 8
    log:
        "logs/01_trycycler_assembly/{strains}/assemble_flye/assemble_flye-{strains}_{subsample}.log"
    wildcard_constraints:
        subsample="|".join(['01', '04', '07', '10']),
    conda:
        "../envs/utilities.yaml"
    shell:  
        """
        flye --nano-raw {input} --threads {threads} --out-dir {output.flye} 2>> {log}
        cp {output.flye}/assembly.fasta {output.assembly}
        cp {output.flye}/assembly_graph.gfa {output.graph}
        """

rule assemble_minipolish:
    input:
        'data/interim/01_trycycler_assembly/{strains}/nanopore/read_subsets/sample_{subsample}.fastq'
    output:
        assembly = 'data/interim/01_trycycler_assembly/{strains}/nanopore/assemblies/assembly_{subsample}.fasta',
        graph = 'data/interim/01_trycycler_assembly/{strains}/nanopore/assemblies/assembly_{subsample}.gfa'
    threads: 8
    log:
        "logs/01_trycycler_assembly/{strains}/assemble_minipolish/assemble_minipolish-{strains}_{subsample}.log"
    wildcard_constraints:
        subsample="|".join(['02', '05', '08', '11']),
    conda:
        "../envs/utilities.yaml"
    shell:  
        """
        # Create temporary intermediate files.
        overlaps=$(mktemp)".paf"
        unpolished_assembly=$(mktemp)".gfa"

        # Find read overlaps with minimap2.
        minimap2 -x ava-ont -t {threads} {input} {input} > "$overlaps" 2>> {log}

        # Run miniasm to make an unpolished assembly.
        miniasm -f {input} "$overlaps" > "$unpolished_assembly" 2>> {log}

        # Polish the assembly with minipolish, outputting the result to stdout.
        minipolish --threads {threads} {input} "$unpolished_assembly" > {output.graph} 2>> {log}

        # Convert to fasta
        any2fasta {output.graph} > {output.assembly} 2>> {log}
        
        # Clean up.
        rm "$overlaps" "$unpolished_assembly"
        """

rule assemble_raven:
    input:
        'data/interim/01_trycycler_assembly/{strains}/nanopore/read_subsets/sample_{subsample}.fastq'
    output:
        assembly = 'data/interim/01_trycycler_assembly/{strains}/nanopore/assemblies/assembly_{subsample}.fasta',
        graph = 'data/interim/01_trycycler_assembly/{strains}/nanopore/assemblies/assembly_{subsample}.gfa'
    threads: 8
    log:
        "logs/01_trycycler_assembly/{strains}/assemble_raven/assemble_raven-{strains}_{subsample}.log"
    wildcard_constraints:
        subsample="|".join(['03', '06', '09', '12']),
    conda:
        "../envs/utilities.yaml"
    shell:  
        """
        raven --threads {threads} --graphical-fragment-assembly {output.graph} --disable-checkpoints {input} > {output.assembly} 2>> {log}
        """

rule draw_graph:
    input:
        graph = 'data/interim/01_trycycler_assembly/{strains}/nanopore/assemblies/assembly_{subsample}.gfa'
    output:
        graph = temp('data/processed/{strains}/01_trycycler_assembly/{subsample}_{strains}.png'),
        gfa = 'data/processed/{strains}/01_trycycler_assembly/{strains}_{subsample}.gfa'
    log:
        "logs/01_trycycler_assembly/{strains}/bandage/{strains}_{subsample}.log"
    conda:
        "../envs/utilities.yaml"
    shell:
        """
        Bandage image {input.graph} {output.graph} &>> {log}
        cp {input.graph} {output.gfa}
        """

rule merge_draw_graph:
    input:
        expand('data/processed/{{strains}}/01_trycycler_assembly/{subsample}_{{strains}}.png', subsample=['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']),
    output:
        png = "data/processed/{strains}/01_trycycler_assembly/{strains}_graphs.png",
    log:
        "logs/01_trycycler_assembly/{strains}/bandage/merge_{strains}.log"
    conda:
        "../envs/utilities.yaml"
    params:
        dir = 'data/processed/{strains}/01_trycycler_assembly'
    shell:
        """
        python workflow/scripts/merge_draw_graph.py {params.dir} {output}
        """
