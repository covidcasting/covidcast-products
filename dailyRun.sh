#!/usr/bin/env bash

# Load R, conda, and the `covidcast` conda env so that R packages needed for
# running the submission script are available in the environment
module load R miniconda 
source activate covidcast

set -o nounset # No undefined variables
set -o errexit # Error ASAP

COVIDESTIM_SOURCES='git@github.com:covidestim/covidestim-sources'

# Directory that will be created to hold the daily run
DIRRESULTS=$(date '+%Y-%m-%d')-allstates-ctp
DIRPROTO="proto-run" # Directory containing the prototype scripts/etc for run
DIRTEMP="CES_tmp"

GITCONFIG="-c user.name=CovidEstimBot -c user.email=marcusrussi+covidestim@gmail.com"

# Create the directory for the new run
echo Creating directory "'$DIRRESULTS'"
mkdir -p "$DIRRESULTS"

# Build the latest model input data. This follows instructions available in
# `covidestim-sources/README.md` on how to get the smoothed CTP data
echo Building input data
git clone $GITCONFIG "$COVIDESTIM_SOURCES" $DIRTEMP && cd $DIRTEMP
git submodule init && git submodule update
make -B data-products/covidtracking-smoothed.csv \
  || { echo "Preparing CTP data failed" >&2; exit 1; }
mv data-products/covidtracking-smoothed.csv "../$DIRRESULTS/data.csv"

# If these data are different, then commit the result using CovidEstimBot
if ! git diff-index --quiet HEAD; then
  git commit -am "Data for $DIRRESULTS" || \
    { echo "Committing to covidestim-sources failed" >&2; exit 1; } 
  git push origin master || \
    { echo "Pushing to covidestim-sources failed" >&2; exit 1; }
fi
cd .. && rm -rf $DIRTEMP # Don't need this repo anymore

# Copy over all the prototype files, enter dir
echo Copying prototype scripts
cp -R $DIRPROTO/* $DIRRESULTS/ 
cd $DIRRESULTS

Rscript rslurm.R \
  --cpus-per-task=3 \
  --id-vars=state \
  --partition=covid \
  --summarize \
  --time=240 \
  --name=ctp_daily \
  data.csv || \
  { echo "Preparing rslurm setup failed" >&2; exit 1; }

cd _rslurm* || { echo "Couldn't enter the _rslurm directory" >&2; exit 1; }

mkdir logs # Where Stan logs will be stored
jid1=$(../sbatch submit.sh) # Submit the script

echo "Job array submitted; jobid=$jid1"
cd .. # Now in the base directory for the run, ex. 2020-06-30/

# Submit the summarizing script
jid2=$(./sbatch --afterany:$jid1 --mem-per-cpu=40g --time=30 summarize.sh --id-vars=state sjob.RDS)

echo "Summarization script submitted; jobid=$jid2"

# Submit the finalizing script
jid3=$(./sbatch --afterok:$jid2 --mem-per-cpu=2g --time=10 finalize.sh)

echo "Finalization script submitted; jobid=$jid3"
