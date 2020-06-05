movingavg_run := 2020-05-28-ctp-allstates-movingaverage
matrix_run := 2020-05-26-matrix
current_run := 2020-05-24-ctp-allstates-smoothed
run_06_03 := 2020-06-03-ctp-allstates

$(movingavg_run)/warnings.html: $(movingavg_run)/results.rds src/warnings.R
	Rscript src/warnings.R --output $@ "$<"
	mv output.html $@

$(matrix_run)/warnings.html: $(matrix_run)/results.rds src/warnings.R
	Rscript src/warnings.R --output $@ "$<"
	mv output.html $@

$(current_run)/warnings.html: $(current_run)/longrun.rds src/warnings.R
	Rscript src/warnings.R --output "$@" "$<"

$(run_06_03)/warnings.html: $(run_06_03)/results.rds src/warnings.R
	Rscript src/warnings.R --output "$@" "$<"
	mv output.html $@
