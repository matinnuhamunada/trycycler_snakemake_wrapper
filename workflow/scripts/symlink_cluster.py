from pathlib import Path
import yaml
import sys

def get_clusters(filepath):
    """
    Read the clusters output and return a dictionary
    """
    try:
        with open(filepath) as file:
            selected_cluster = yaml.load(file, Loader=yaml.FullLoader)
        return selected_cluster
    except FileNotFoundError as e:
        sys.stderr.write(f"No cluster selected. The file: <{filepath}> is not a valid cluster format. Check your config.yaml.\n")
        raise e

def symlink_cluster(strain, cluster, cluster_file, source_dir = 'data/interim/02_trycycler_cluster', target_dir = 'data/interim/03_trycycler_consensus'):
    clusters = get_clusters(cluster_file)
    source_path = Path(source_dir)
    target_path = Path(target_dir)

    for contigs in clusters[strain][cluster]:
        source = source_path / strain / cluster / "1_contigs" / f"{contigs}.fasta"
        target = target_path / strain / cluster / "1_contigs" / f"{contigs}.fasta"
        target.parent.mkdir(parents=True, exist_ok=True)
        try:
            target.symlink_to(source.resolve(), target_is_directory=False)
        except:
            if target.is_symlink():
                target.unlink(missing_ok=True)
                target.symlink_to(source.resolve(), target_is_directory=False)
        with open(str(target_path / strain / f"{cluster}_copy.log"), 'w') as f:
            f.write("")
    return

if __name__ == "__main__":
    symlink_cluster(sys.argv[1], sys.argv[2], sys.argv[3])    