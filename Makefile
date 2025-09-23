# R options (--vanilla, but without --no-environ)
R_OPTS=--no-save --no-restore --no-init-file --no-site-file

all: salaries.json script.js salary_ranges.json

salaries.json: prep_data.R ../salary_data/Updated\ 2025-09\ All\ Faculty\ and\ Staff\ Title\ and\ Salary\ Information.xlsx
	R CMD BATCH $(R_OPTS) $<

script.js: script.coffee
	coffee -ctb $<

salary_ranges.json: convert_ranges.R salary_ranges.csv
	R CMD BATCH $(R_OPTS) $<
