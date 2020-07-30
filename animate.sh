#!/bin/bash
#SBATCH --partition=covid
#SBATCH --account=covid
#SBATCH --job-name=animate
#SBATCH --cpus-per-task=18
#SBATCH --mem-per-cpu=2G
#SBATCH --time=30

module load miniconda parallel foss/2018b FFmpeg
conda activate covidcast

set -o nounset # No undefined variables
set -o errexit # Error ASAP

mkdir -p movies

parallel -j$SLURM_CPUS_PER_TASK Rscript animate.R --state={} -o movies/{}.mp4 dailyRuns.RDS :::: states.txt
