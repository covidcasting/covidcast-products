matrix_run := 2020-05-26-matrix
current_run := 2020-05-24-ctp-allstates-smoothed

$(matrix_run)/warnings.html: $(matrix_run)/results.rds src/warnings.R
	Rscript src/warnings.R --output $@ "$<"
	mv output.html $@

$(current_run)/warnings.html: $(current_run)/longrun.rds src/warnings.R
	Rscript src/warnings.R --output $@ ../$<
