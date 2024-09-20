import argparse
import logging
from pathlib import Path

import pandas as pd


def process_logs(log_dir):
    logs = sorted([log for log in Path(log_dir).glob("*/subsample-*.log")])
    summary = {}
    for log in logs:
        strain = log.stem.strip("subsample-")

        with open(log, "r") as f:
            data = f.readlines()
        logging.info(f"Processing {strain}, {len(data)} lines")

        if data[0].startswith("--genome_size"):
            total = data[9].strip()
            n50 = data[10].strip().strip("N50 = ")
            estimated_genome_size = data[0].strip().replace("--genome_size ", "")
            if estimated_genome_size[-1] == "m":
                estimated_genome_size = f'{float(estimated_genome_size.replace("m", "")) * 1_000_000:,.0f} bp*'
            total_depth = data[20].strip().strip("Total read depth: ")
            mean_read_length = data[21].strip().strip("Mean read length: ")
            subset_depth = data[25].strip().strip("= ")
        else:
            total = data[8].strip()
            n50 = data[9].strip().strip("N50 = ")
            estimated_genome_size = data[27].strip().strip("Estimated genome size: ")
            total_depth = data[33].strip().strip("Total read depth: ")
            mean_read_length = data[34].strip().strip("Mean read length: ")

            if len(data) > 37:
                subset_depth = data[38].strip().strip("= ")
            else:
                subset_depth = "Not enough depth after filtering (>1kb)"

        dataset = {
            "Reads": total,
            "N50": n50,
            "Mean read length": mean_read_length,
            "Estimated genome size": estimated_genome_size,
            "Total depth": total_depth,
            "Subset depth": subset_depth,
        }
        summary[strain] = dataset

    return summary


def main():
    parser = argparse.ArgumentParser(description="Process Trycycler subsample logs.")
    parser.add_argument("log_dir", type=str, help="Directory containing the log files")
    parser.add_argument(
        "--output_csv",
        type=str,
        default="summary.csv",
        help="Output CSV file for the summary (default: summary.csv)",
    )
    parser.add_argument(
        "--output_md",
        type=str,
        default="summary.md",
        help="Output Markdown file for the summary (default: summary.md)",
    )
    parser.add_argument(
        "--log",
        type=str,
        default="process_logs.log",
        help="Log file (default: process_logs.log)",
    )
    args = parser.parse_args()

    # Set up logging
    logging.basicConfig(
        filename=args.log,
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )

    logging.info("Starting log processing")
    summary = process_logs(args.log_dir)
    logging.info("Finished log processing")

    # Convert summary to DataFrame
    df = pd.DataFrame.from_dict(summary).T

    # Write to CSV file
    df.to_csv(args.output_csv)
    logging.info(f"Summary written to {args.output_csv}")

    # Convert DataFrame to Markdown
    markdown_output = df.to_markdown()

    # Write to Markdown file
    with open(args.output_md, "w") as f:
        f.write(markdown_output)
    logging.info(f"Summary written to {args.output_md}")


if __name__ == "__main__":
    main()
