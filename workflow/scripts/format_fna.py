from Bio import SeqIO
import sys

def format_fna(strain_id, original_file, corrected_file):
    """
    Reformat trycycler contig ids
    """
    with open(original_file) as original, open(corrected_file, 'w') as corrected:
        records = SeqIO.parse(original_file, 'fasta')
        for num, record in enumerate(records):
            record.id = f"{strain_id}_{num+1}"
            SeqIO.write(record, corrected, 'fasta')
    return

if __name__ == "__main__":
    format_fna(sys.argv[1], sys.argv[2], sys.argv[3])