# R options (--vanilla, but without --no-environ)
R_OPTS=--no-save --no-restore --no-init-file --no-site-file

all: salaries.json script.js

salaries.json: prep_data.R Updated\ 2024-04\ All\ Faculty\ and\ Staff\ Title\ and\ Salary\ Information.xlsx salary_ranges_jan_2024.csv
	R CMD BATCH $(R_OPTS) $<

script.js: script.coffee
	coffee -ctb $<
