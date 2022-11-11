# convert data to JSON files
library(readxl)
library(jsonlite)

x <- readxl::read_excel("Updated August 2022 All Faculty and Staff Title and Salary Information.xlsx")
x <- as.data.frame(x)

# remove $0 cases
x <- x[x$"Current Annual Contracted Salary">0,]

# reduce columns
x <- x[,c("First Name", "Last Name", "Division", "Title", "Salary Grade",
          "Current Annual Contracted Salary", "Job Code")]
colnames(x) <- c("FirstName", "LastName", "Division", "Title", "SalaryGrade", "AnnualSalary", "JobCode")

# remove duplicates
z <- apply(x, 1, paste, collapse="|")
m <- match(z, z)
x <- x[unique(m),]

# save unique Division
div <- sort(unique(x$Division))
cat(div, file="divisions.json")

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
