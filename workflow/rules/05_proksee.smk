rule prepare_proksee:
    input:
        assembly = 'data/processed/{strains}/03_trycycler_consensus/{strains}.fna',
        depth = 'data/processed/{strains}/04_final_qc/{strains}_depth.txt'
    output:
        proksee_input = directory('data/interim/05_proksee/{strains}/05_proksee_{strains}'),
        output_depth = directory('data/processed/{strains}/05_proksee_{strains}/')
    threads: 4
    log:
        "logs/05_proksee/proksee-{strains}.log"
    conda:
        "../envs/proksee.yaml"
    shell:
        """
        # Step 1: Split fasta files per contigs
        input_fasta={input.assembly}

        # Initialize variables
        output_file=""
        contig_name=""

        # Read the input FASTA file line by line
        while IFS= read -r line; do
            if [[ $line == ">"* ]]; then
                # If the line starts with '>', it's a header line
                # Close the previous output file if it exists
                if [ -n "$output_file" ]; then
                    exec 3>&-
                fi
                # Extract the contig name and create a new output file
                contig_name=$(echo "$line" | sed 's/>//; s/ .*//')

                output_directory="{output.proksee_input}/$contig_name/fasta"
                mkdir -p "$output_directory"

                output_file="$output_directory/$contig_name.fasta"
                exec 3>"$output_file"
                echo "$line" >&3
            else
                # Write the sequence line to the current output file
                echo "$line" >&3
            fi
        done < "$input_fasta"

        # Close the last output file
        if [ -n "$output_file" ]; then
            exec 3>&-
        fi

        echo "Splitting fasta completed. Fasta files are saved in $output_directory" >> {log}

        # Step 2: Split depth table per contig
        python workflow/scripts/proksee_prepare.py {input.depth} {output.proksee_input} {wildcards.strains} --output_depth {output.output_depth} 2>> {log}

        # echo "Splitting depth table completed. Depth files are saved in $output_directory" >> {log}
        """

rule run_proksee:
    input:
        proksee_input = 'data/interim/05_proksee/{strains}/05_proksee_{strains}'
    output:
        proksee_output = directory('data/processed/{strains}/05_proksee_{strains}_output')
    log:
        "logs/05_proksee/proksee-run-{strains}.log"
    conda:
        "../envs/proksee.yaml"
    shell:
        """
        proksee-batch --input {input.proksee_input} --output {output.proksee_output} 2>> {log}
        """
