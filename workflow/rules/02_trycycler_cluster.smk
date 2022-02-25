rule trycylcer_cluster:
    input:
        raw_reads = 'data/interim/01_trycycler_assembly/{strains}/nanopore/min1kb.fq',
        assembly = 'data/interim/01_trycycler_assembly/{strains}/nanopore/assemblies'
    output:
        cluster=directory('data/interim/02_trycycler_cluster/{strains}')
    threads: 12
    log:
        "workflow/report/logs/02_trycycler_cluster/02_trycycler_cluster-{strains}.log"
    conda:
        "../envs/trycycler.yaml"
    shell:  
        """
        trycycler cluster --threads {threads} --reads {input.raw_reads} --assemblies {input.assembly}/*.fasta --out_dir {output.cluster} 2>> {log}
        """

rule cluster_dump:
    input:
        expand('data/interim/02_trycycler_cluster/{strains}', strains=STRAINS)
    output:
        yaml = 'data/interim/02_trycycler_cluster/cluster.yaml'
    log:
        "workflow/report/logs/02_trycycler_cluster/cluster_dump.log"
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
            strain = cluster_path / s
            strain_cluster = [i.name for i in strain.glob('cluster_*')]
            clusters[s] = strain_cluster

        # write as yaml
        with open(output.yaml, 'w') as f:
            yaml.dump(clusters, f, Dumper=yaml_indent_dump, default_flow_style=False)