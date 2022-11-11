d3.json("salaries.json").then (salaries) ->

    d3.json("titles.json").then (titles) ->


        d3.json("divisions.json").then (divisions) ->

            dropdown = d3.select("body").select("select#division")

            opts = dropdown.selectAll("option")
                           .data(divisions)
                           .enter()
                           .append("option")
                           .text((d) -> d)
                           .attr("value", (d) -> d)

            # insert title into salaries dataset
            salaries.forEach((d) -> d.title = titles[d.JobCode])

            # create object that has title -> job codes
            jobcodes = {}
            for x of titles
                title = titles[x]
                if !(jobcodes[title]?)
                    jobcodes[title] = []
                jobcodes[title].push(x)


            # add
            d3.select("button")
              .on("click", () -> plot_data(salaries, divisions, jobcodes))

plot_data = (salaries, divisions, jobcodes) ->
    # grab form data
    last_name = d3.select("input#last_name").property("value")
    first_name = d3.select("input#first_name").property("value")
    # division
    selected_div = d3.select("select#division option:checked").text()
    # scope
    scope_across = d3.select("input#across").property("checked")
    scope = if scope_across then "across" else "within"

    d3.select("div#chart")
      .text("hello #{first_name} #{last_name} (#{selected_div}) - #{scope}")

# look for matching record
# find the job codes for that person's title
# look for other people with one of those job codes (overall, or within that division)
# dotplot of those points
# add boxplot over the dotplot
