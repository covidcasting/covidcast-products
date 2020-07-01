#!/bin/bash
#SBATCH --partition=covid
#SBATCH --job-name=summarize

module load R miniconda
source activate covidcast

Rscript summarize.R $@ # Forward all arguments
