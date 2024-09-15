rule trycycler_cluster:
    input:
        raw_reads = 'data/interim/01_trycycler_assembly/{strains}/nanopore/min1kb.fq',
        assembly = 'data/interim/01_trycycler_assembly/{strains}/nanopore/assemblies'
    output:
        cluster=directory('data/interim/02_trycycler_cluster/{strains}')
    threads: 12
    log:
        "logs/02_trycycler_cluster/trycycler_cluster/02_trycycler_cluster-{strains}.log"
    conda:
        "../envs/trycycler.yaml"
    shell:  
        """
        trycycler cluster --threads {threads} --reads {input.raw_reads} --assemblies {input.assembly}/*.fasta --out_dir {output.cluster} 2>> {log}
        """

rule cluster_dump:
    input:
        expand(rules.trycycler_cluster.output.cluster, strains=STRAINS),
    output:
        yaml = 'data/interim/02_trycycler_cluster/cluster.yaml'
    log:
        "logs/02_trycycler_cluster/cluster_dump/cluster_dump.log"
    params:
        cluster_path = 'data/interim/02_trycycler_cluster'
    run:
        class yaml_indent_dump(yaml.Dumper):
            def increase_indent(self, flow=False, indentless=False):
                    return super(yaml_indent_dump, self).increase_indent(flow, False)
            
        # grab all cluster
        cluster_path = Path(params.cluster_path)
        clusters = {}
        for s in STRAINS:
            contigs = {}
            strain = cluster_path / s
            strain_cluster = [i for i in strain.glob('cluster*')]
            for c in strain_cluster:
                contigs[c.name] = [i.stem for i in c.glob('*/*.fasta')]
            clusters[s] = contigs

        # write as yaml
        with open(output.yaml, 'w') as f:
            yaml.dump(clusters, f, Dumper=yaml_indent_dump, default_flow_style=False)

rule cluster_draw:
    input:
        cluster=rules.trycycler_cluster.output.cluster
    output:
        png = 'data/processed/{strains}/02_trycycler_cluster/{strains}_cluster.png',
        pdf = 'data/processed/{strains}/02_trycycler_cluster/{strains}_cluster.pdf',
    log:
        "logs/02_trycycler_cluster/cluster_draw/draw_cluster_{strains}.log"
    conda:
        "../envs/R.yaml"
    shell:
        """
        Rscript workflow/scripts/ggtree.R -i {input.cluster}/contigs.newick -o {output.png} 2>> {log}
        """