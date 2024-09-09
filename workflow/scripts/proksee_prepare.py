import argparse
import json
import logging
from pathlib import Path

import pandas as pd

logging.basicConfig(
    format="%(asctime)s - %(levelname)s - %(message)s", level=logging.INFO
)


def split_depth_file(
    input_file, output_dir, genome_id, output_depth=None, window_size=100
):
    # Read the depth file
    logging.info(f"Reading depth file: {input_file}")
    df = pd.read_csv(input_file, sep="\t", header=None)
    df = df.rename(columns={0: "contig_id", 1: "start", 2: "score"})

    # Create the output directory if it doesn't exist
    outdir = Path(output_dir)
    outdir.mkdir(parents=True, exist_ok=True)
    logging.info(f"Output directory created: {output_dir}")

    # Split the depth file by contig and save each to a separate file
    for contig in df.contig_id.unique():
        logging.info(f"Processing contig {contig}")
        subset = df[df.contig_id == contig]

        # Calculate non-overlapping window average
        subset["window"] = (subset["start"] - 1) // window_size
        window_avg = subset.groupby("window")["score"].mean().reset_index()
        window_avg["start"] = window_avg["window"] * window_size + 1
        window_avg["end"] = window_avg["start"] + window_size - 1

        if output_depth is None:
            output_depth = outdir

        outfile = Path(output_depth) / f"{contig}/plot/depth.txt"
        outfile.parent.mkdir(parents=True, exist_ok=True)
        window_avg.loc[:, ["start", "end", "score"]].to_csv(
            outfile, sep="\t", index=False
        )
        logging.info(f"Depth file saved for contig {contig}: {outfile}")

        # Create metadata
        metadata = {
            "metadata": {
                "description": f"Contig {contig} extracted from genome {genome_id}"
            }
        }

        # Save metadata to a JSON file
        metadata_file = outdir / f"{contig}/metadata/{contig}.json"
        metadata_file.parent.mkdir(parents=True, exist_ok=True)
        with open(metadata_file, "w") as f:
            json.dump(metadata, f, indent=2)
        logging.info(f"Metadata file saved for contig {contig}: {metadata_file}")

    logging.info(f"Splitting completed. Files are saved in {output_dir}")


def main():
    parser = argparse.ArgumentParser(
        description="Split depth file by contig and save each to a separate file with metadata."
    )
    parser.add_argument("input_file", help="Path to the input depth file")
    parser.add_argument("output_dir", help="Directory to save the output files")
    parser.add_argument("genome_id", help="Genome ID for metadata")
    parser.add_argument(
        "--output_depth",
        help="Optional directory to save the depth files",
        default=None,
    )
    parser.add_argument(
        "--window_size",
        type=int,
        help="Window size for calculating the non-overlapping window average",
        default=100,
    )

    args = parser.parse_args()

    split_depth_file(
        args.input_file,
        args.output_dir,
        args.genome_id,
        args.output_depth,
        args.window_size,
    )


if __name__ == "__main__":
    main()
