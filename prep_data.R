# convert data to JSON files
library(readxl)
library(jsonlite)

# salaries by ORR, emails and phone numbers removed
salary_file <- "Updated August 2022 All Faculty and Staff Title and Salary Information.xlsx"
# TTC info from https://github.com/vgXhc/TTC
salary_range_file <- "salary_ranges_sep2022.RDS"

x <- readxl::read_excel(salary_file)
x <- as.data.frame(x)

# remove $0 cases and FTE > 0.01
x <- x[x$"Current Annual Contracted Salary">1000 & x$"Full-time Equivalent" > 0.01,]

# reduce columns
x <- x[,c("First Name", "Last Name", "Division", "Department", "Title", "Salary Grade",
          "Current Annual Contracted Salary", "Job Code")]
colnames(x) <- c("FirstName", "LastName", "Division", "Department", "Title", "SalaryGrade", "AnnualSalary", "JobCode")

# remove duplicates
z <- apply(x, 1, paste, collapse="|")
m <- match(z, z)
x <- x[unique(m),]

# save unique Division
div <- sort(unique(x$Division))
cat(jsonlite::toJSON(div), file="divisions.json")

# replace division with division number (1 - no. divisions)
x$Division <- match(x$Division, div)

# force job codes to have unique titles
tab <- table(x$JobCode, x$Title)
dups <- which(rowSums(tab>0)>1)
if(length(dups) > 0) {
    for(dup in dups) {
        titles <- colnames(tab)[tab[dup,]>0]
        for(j in seq(along=titles)[-1]) {
            x$JobCode[x$Title==titles[j]] <- paste0(x$JobCode[x$Title==titles[j]][1], letters[j])
        }
    }
}

# save jobcode -> title relationship
ujobcode <- unique(x$JobCode)
utitles <- x$Title[match(ujobcode, x$JobCode)]
titles <- setNames(as.list(utitles), ujobcode)
titles <- jsonlite::toJSON(titles, auto_unbox=TRUE)
cat(titles, file="titles.json")

x <- x[, colnames(x) != "Title"]

# convert to JSON
y <- jsonlite::toJSON(x)
cat(y, file="salaries.json")

######################################################################
# salary ranges
salary_ranges <- readRDS(salary_range_file)
salary_ranges <- as.data.frame(salary_ranges)

v <- vector("list", nrow(salary_ranges))
names(v) <- salary_ranges[,1]
for(i in seq_along(v)) {
    v[[i]] <- list(min=salary_ranges[i,2], max=salary_ranges[i,3])
}

cat(toJSON(v, auto_unbox=TRUE), file="salary_ranges.json")
