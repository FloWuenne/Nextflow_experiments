#!/bin/bash
#SBATCH --job-name=gpu_test
#SBATCH --cpus-per-task=4
#SBATCH --nodes=1

nextflow run . -c nextflow.config