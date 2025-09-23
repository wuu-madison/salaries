# convert data to JSON files
library(jsonlite)

# salary range info see https://github.com/wuu-madison/salary_ranges
# also https://github.com/vgXhc/TTC

salary_range_file <- "salary_ranges.csv"


######################################################################
# salary ranges
salary_ranges <- read.csv(salary_range_file)
salary_ranges$salary_grade <- sprintf("%03d", salary_ranges$salary_grade)

v <- vector("list", nrow(salary_ranges))
names(v) <- salary_ranges[,1]
for(i in seq_along(v)) {
    v[[i]] <- list(min=salary_ranges[i,2], max=salary_ranges[i,3])
}

cat(toJSON(v, auto_unbox=TRUE), file="salary_ranges.json")
