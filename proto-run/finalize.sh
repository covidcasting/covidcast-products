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

# copy the .pack file to the root directory, so that after merging into master
# it will be the new .pack file that the website looks to for data
cp summary.pack ../current_summary.pack

git checkout draft || { echo "Checking out the 'draft' branch failed" >&2; exit 1; }
git add data.csv summary.csv summary.pack ../current_summary.pack
git commit -m "Summary files for $(basename $(dirname $(pwd)))" \
           --author "CovidEstimBot <marcusrussi+covidestim@gmail.com>" || \
  { echo "Commiting results failed" >&2; exit 1; }

git push origin draft
git checkout master
