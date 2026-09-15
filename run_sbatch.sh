#!/bin/bash

input_csv=/mnt/NAS_PROJECT/vol_Thinhteam/DATA_VYNGUYEN3/nextflow/metagenomics/fastq/test.csv
output_dir=/mnt/NAS_PROJECT/vol_Thinhteam/DATA_VYNGUYEN3/nextflow/metagenomics/test
resources_dir=/mnt/NAS_PROJECT/vol_Thinhteam/DATA_VYNGUYEN3/nextflow/metagenomics/ref

bash ./run.sh \
    -i $input_csv \
    -o $output_dir \
    -r $resources_dir \
    -j ncbi \