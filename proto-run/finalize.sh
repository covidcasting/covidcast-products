#!/bin/bash
#SBATCH --partition=covid
#SBATCH --job-name=finalize
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5g

module load miniconda
source activate covidcast

set -o nounset # No undefined variables
set -o errexit # Error ASAP

Rscript RtLiveConvert.R # Convert summary.csv to summary.json

# json2msgpack needs to be in $PATH. It can be easily installed from GitHub
json2msgpack -bli summary.json -o summary.pack

# copy the .pack and the .csv file to the root directory, so that after merging into master
# it will be the new .pack/.csv files that the website looks to for data
cp summary.pack ../current_summary.pack
cp summary.csv ../current_summary.csv

git checkout draft || { echo "Checking out the 'draft' branch failed" >&2; exit 1; }
git add data.csv summary.csv summary.pack ../current_summary.pack ../current_summary.csv
git commit -m "Summary files for $(basename $(dirname $(pwd)))" \
           --author "CovidEstimBot <marcusrussi+covidestim@gmail.com>" || \
  { echo "Commiting results failed" >&2; exit 1; }

git push origin draft

# Update RDS and SQLite files
cd ..
find . \ 
  -maxdepth 1 \
  -regex '.*2020-0[789]-[0-9][0-9]-allstates-ctp.*' \
  -type d |
  xargs Rscript sqlLoad.R --file=summary.csv --sqlite=dailyRuns.db --rds=dailyRuns.RDS

git checkout master
