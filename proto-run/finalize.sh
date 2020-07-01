#!/bin/bash
#SBATCH --partition=covid
#SBATCH --job-name=finalize
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=2g

module load R miniconda
source activate covidcast

set -o nounset # No undefined variables
set -o errexit # Error ASAP

Rscript RtLiveConvert.R # Convert summary.csv to summary.json

# json2msgpack needs to be in $PATH. It can be easily installed from GitHub
json2msgpack -bli summary.json -o summary.pack

git checkout draft || { echo "Checking out the 'draft' branch failed" >&2; exit 1; }
git add summary.csv summary.pack
git commit -m "Summary files for $(basename $(dirname $(pwd)))" \
           --author "CovidEstimBot <marcusrussi+covidestim@gmail.com>" || \
  { echo "Commiting results failed" >&2; exit 1; }

git push origin draft
