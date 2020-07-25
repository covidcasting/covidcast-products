#!/bin/bash
#SBATCH --partition=covid
#SBATCH --account=covid
#SBATCH --job-name=s3
#SBATCH --mem-per-cpu=2G
#SBATCH --time=5

module load awscli

set -o nounset # No undefined variables
set -o errexit # Error ASAP

aws s3 cp --recursive movies s3://covidestim/movies --acl public-read
