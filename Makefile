# R options (--vanilla, but without --no-environ)
R_OPTS=--no-save --no-restore --no-init-file --no-site-file

salaries.json: prep_data.R Updated\ August\ 2022\ All\ Faculty\ and\ Staff\ Title\ and\ Salary\ Information.xlsx
	R CMD BATCH $(R_OPTS) $<
