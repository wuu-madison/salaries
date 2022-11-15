d3.json("salaries.json").then (salaries) ->

    d3.json("titles.json").then (titles) ->

        d3.json("salary_ranges.json").then (salary_ranges) ->

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

                # index of people: vector with {name: first|last|div, index: numeric index}
                person_division = ([v.FirstName, v.LastName, v.Division].join("|") for v in salaries)
                person_index = []
                for i of person_division
                    person_index.push({name:person_division[i], index:i})

                # button click -> make plot
                d3.select("button")
                  .on("click", () -> plot_data(salaries, divisions, jobcodes, salary_ranges, person_index))

plot_data = (salaries, divisions, jobcodes, salary_ranges, person_index) ->
    d3.select("div#chart svg").remove()
    d3.selectAll("g.d3panels-tooltip").remove()
    d3.select("div#text_output").html("")

    # grab form data
    last_name = d3.select("input#last_name").property("value").toUpperCase()
    first_name = d3.select("input#first_name").property("value").toUpperCase()
    # division
    selected_div = d3.select("select#division option:checked").text()

    # look for the person in the data
    this_person = [first_name, last_name, divisions.indexOf(selected_div)+1].join("|")

    index_in_data = person_index.find((d) -> d.name == this_person)

    if index_in_data?  # individual was found
        d3.select("div#chart").text("") # clear text in div

        # if multiple records for that person: pick a random one?
        all_indices = person_index.filter((d) -> d.name == this_person)

        if all_indices.length > 1 # pick a random one
            index_in_data = all_indices[ Math.floor( Math.random() * all_indices.length ) ]

        this_record = salaries[index_in_data.index]
        title = this_record.title
        salary = this_record.AnnualSalary
        target_jobcodes = jobcodes[title]

        # across campus
        salaries_subset = salaries.filter((d) -> target_jobcodes.indexOf(d.JobCode) >= 0)
        comp_salaries = (d.AnnualSalary for d in salaries_subset)
        labels = (d.FirstName + " " + d.LastName + " $" + d.AnnualSalary for d in salaries_subset)
        group = (2 for d in salaries_subset)
        this_index = (i for i of salaries_subset when salaries_subset[i].FirstName==first_name and salaries_subset[i].LastName==last_name)
        if this_index >= 0
            group[this_index] = 1
        data_to_plot = {x:(1 for d in comp_salaries), y:comp_salaries, indID:labels, group:group}

        # within division
        salaries_division = salaries_subset.filter((d) -> d.Division == this_record.Division)
        data_to_plot.x = data_to_plot.x.concat(2 for d in salaries_division)
        comp_salaries_division = (d.AnnualSalary for d in salaries_division)
        data_to_plot.y = data_to_plot.y.concat(comp_salaries_division)
        data_to_plot.indID = data_to_plot.indID.concat(d.FirstName + " " + d.LastName + " $" + d.AnnualSalary for d in salaries_division)
        group = (2 for d in salaries_division)
        this_index = (i for i of salaries_division when salaries_division[i].FirstName==first_name and salaries_division[i].LastName==last_name)
        if this_index >= 0
            group[this_index] = 1
        data_to_plot.group = data_to_plot.group.concat(group)

        # within department
        salaries_dept = salaries_division.filter((d) -> d.Department == this_record.Department)
        data_to_plot.x = data_to_plot.x.concat(3 for d in salaries_dept)
        data_to_plot.y = data_to_plot.y.concat(d.AnnualSalary for d in salaries_dept)
        data_to_plot.indID = data_to_plot.indID.concat(d.FirstName + " " + d.LastName + " $" + d.AnnualSalary for d in salaries_dept)
        group = (2 for d in salaries_dept)
        this_index = (i for i of salaries_dept when salaries_dept[i].FirstName==first_name and salaries_dept[i].LastName==last_name)
        if this_index >= 0
            group[this_index] = 1
        data_to_plot.group = data_to_plot.group.concat(group)

        salary_range = salary_ranges[this_record.SalaryGrade]

        # this individual
        data_to_plot.x.push(4)
        data_to_plot.y.push(salary)
        data_to_plot.indID.push(first_name + " " + last_name + " $" + salary)
        data_to_plot.group.push(1)

        ymin = d3.min(data_to_plot.y)
        ymin = d3.min([ymin, salary_range.min]) unless salary_range.min == "NA"
        ymax = d3.max(data_to_plot.y)
        ymax = d3.max([ymax, salary_range.max]) unless salary_range.max == "NA"

        mychart = d3panels.dotchart({
            xlab:"",
            ylab:"Annual Salary ($)",
            title:title,
            height:600,
            width:900,
            ylim:[ymin*0.95,ymax*1.05],
            margin: {left:160, top:40, right:160, bottom:40, inner:3},
            xcategories: [1, 2, 3, 4],
            xcatlabels: ["everyone", "your school/division", "your department", "you"],
            horizontal:true})

        mychart(d3.select("div#chart"), data_to_plot)

        mychart.points()
            .on "mouseover", (d) -> d3.select(this).attr("r", 6)
            .on "mouseout", (d) -> d3.select(this).attr("r", 3)

        green = "#2ECC40"
        orange = "#FF851B"
        orange_text = "#dF650B"

        summary = five_number_summary(comp_salaries)

        y1 = mychart.yscale()(1)
        y2 = mychart.yscale()(2)

        make_boxplot(summary, d3.select("div#chart svg"),
                     mychart.xscale(), y1*0.67+y2*0.33, (y2-y1)/3,
                     3, green)


        summary_div = five_number_summary(comp_salaries_division)

        y3 = mychart.yscale()(3)

        make_boxplot(summary_div, d3.select("div#chart svg"),
                     mychart.xscale(), y2*0.67+y3*0.33, (y2-y1)/3,
                     3, green)


        yd = (y2-y1)/24
        ypos = mychart.yscale()(4) + yd*3

        g_range = d3.select("div#chart svg").append("g").attr("id", "salary_range")
        range_min = if salary_range.min == "NA" then summary[0] else salary_range.min
        range_max = if salary_range.max == "NA" then summary[4] else salary_range.max
        g_range.append("line")
          .style("stroke-width", 3)
          .style("stroke", orange)
          .attr("x1", (d) -> mychart.xscale()(range_min))
          .attr("x2", (d) -> mychart.xscale()(range_max))
          .attr("y1", ypos)
          .attr("y2", ypos)
        range = [range_min, range_max]
        sr_range = [salary_range.min, salary_range.max]
        for i in [0,1]
            val = range[i]
            if sr_range[i] != "NA"
                g_range.append("line")
                  .style("stroke-width", 3)
                  .style("stroke", orange)
                  .attr("x1", mychart.xscale()(val))
                  .attr("x2", mychart.xscale()(val))
                  .attr("y1", ypos-yd)
                  .attr("y2", ypos+yd)
            else
                g_range.append("line")
                  .style("stroke-width", 3)
                  .style("stroke", orange)
                  .attr("x1", mychart.xscale()(val))
                  .attr("x2", mychart.xscale()(val) + (1-i*2)*(y2-y1)*0.1)
                  .attr("y1", ypos)
                  .attr("y2", ypos+yd)
                g_range.append("line")
                  .style("stroke-width", 3)
                  .style("stroke", orange)
                  .attr("x1", mychart.xscale()(val))
                  .attr("x2", mychart.xscale()(val) + (1-i*2)*(y2-y1)*0.1)
                  .attr("y1", ypos)
                  .attr("y2", ypos-yd)
        g_range.append("text")
               .text("salary range for title")
               .attr("fill", orange_text)
               .attr("x", mychart.xscale()(range[1]))
               .attr("y", ypos + 3*yd)
               .style("dominant-baseline", "top")
               .style("text-anchor", "end")

        # min and max salary for title
        if salary_range.min=="NA"
            start_range_text = "There is no minimum salary for your title;"
        else
            start_range_text = "The minimum salary for your title is $#{salary_range.min};"
        if salary_range.max=="NA"
            end_range_text = " there is no maximum salary for your title."
        else
            end_range_text = " the maximum salary for your title is $#{salary_range.max}."
        if salary_range.min=="NA" and salary_range.max=="NA"
            range_text = "Your title has neither a minimum nor maximum salary."
        else
            range_text = start_range_text + end_range_text;

        d3.select("div#text_output")
          .html("<p>Your title is #{title} in #{this_record.Department}, #{selected_div}. " +
                "Your annual salary (adjusted for FTE) is $#{salary}. " +
                range_text +
                "<p>On top, the plot shows the actual salaries of all other employees (blue dots) " +
                "that have the same job title as you " +
                "(across campus, in your school/division, and in your department). " +
                "<p>The green boxes represent the range from the 25th to 75th percentile with " +
                "a central line at the median, across campus and within your school/division. " +
                "<p>The orange line indicates the salary range for your title; " +
                "arrowheads on the left or right indicate no minimum or maximum salary, respectively.")

    else

        d3.select("div#chart")
          .text("#{first_name} #{last_name} not found in #{selected_div}")

# calculate min, 25 %ile, median, 75 %ile, max
five_number_summary = (x) ->
    return null if !x?

    # drop missing values
    x = (xv for xv in x when xv?)

    n = x.length
    return null unless n > 0
    return [x[0], x[0], x[0], x[0], x[0]] unless n > 1

    x.sort((a,b) -> a-b)
    if n % 2 == 1
        median = x[(n-1)/2]
    else
        median = (x[n/2] + x[(n/2)-1])/2

    min = x[0]
    max = x[n-1]

    # calculate lower and upper quartile
    quarter = (n-1)*0.25
    below = Math.floor(quarter)
    above = Math.ceil(quarter)
    weight1 = quarter - below
    weight2 = 1-weight1

    lower = (x[below]*weight2 + x[below+1]*weight1)
    upper = (x[n-below-2]*weight1 + x[n-below-1]*weight2)

    [min, lower, median, upper, max]

make_boxplot = (values, selection, xscale, ypos, boxheight, stroke_width, stroke) ->

        g = selection.append("g").attr("id", "boxplot")

        g.append("line")
         .attr("x1", xscale(values[0]))
         .attr("x2", xscale(values[1]))
         .attr("y1", ypos)
         .attr("y2", ypos)
         .style("stroke-width", stroke_width)
         .style("stroke", stroke)
        g.append("line")
         .attr("x1", xscale(values[3]))
         .attr("x2", xscale(values[4]))
         .attr("y1", ypos)
         .attr("y2", ypos)
         .style("stroke-width", stroke_width)
         .style("stroke", stroke)
        g.append("line")
         .attr("x1", xscale(values[1]))
         .attr("x2", xscale(values[3]))
         .attr("y1", ypos + boxheight/4)
         .attr("y2", ypos + boxheight/4)
         .style("stroke-width", stroke_width)
         .style("stroke", stroke)
        g.append("line")
         .attr("x1", xscale(values[3]))
         .attr("x2", xscale(values[1]))
         .attr("y1", ypos - boxheight/4)
         .attr("y2", ypos - boxheight/4)
         .style("stroke-width", stroke_width)
         .style("stroke", stroke)

        vert_line_labels = ["min", "25th %ile", "median", "75th %ile", "max"]

        vert_lines = g.append("g").selectAll("empty")
                      .data(values)
                      .enter()
                      .append("line")
                      .style("stroke-width", stroke_width)
                      .style("stroke", stroke)
                      .attr("x1", xscale)
                      .attr("x2", xscale)
                      .attr("y1", (d,i) ->
                          if i==0 or i==4
                              return ypos-boxheight/8
                          else
                              return ypos-boxheight/4)
                      .attr("y2", (d,i) ->
                          if i==0 or i==4
                              return ypos+boxheight/8
                          else
                              return ypos+boxheight/4)

        # add tool tip
        vert_lines_tooltip = d3panels.tooltip_create(d3.select("body"), vert_lines,
                                               {tipclass:"tooltip"},
                                               (d,i) ->
                                                   "#{vert_line_labels[i]} = $#{Math.round(d)}")
