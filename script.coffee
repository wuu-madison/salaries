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

            # index of people: vector with {name: first|last|div, index: numeric index}
            person_division = ([v.FirstName, v.LastName, v.Division].join("|") for v in salaries)
            person_index = []
            for i of person_division
                person_index.push({name:person_division[i], index:i})

            # add
            d3.select("button")
              .on("click", () -> plot_data(salaries, divisions, jobcodes, person_index))

plot_data = (salaries, divisions, jobcodes, person_index) ->
    # grab form data
    last_name = d3.select("input#last_name").property("value").toUpperCase()
    first_name = d3.select("input#first_name").property("value").toUpperCase()
    # division
    selected_div = d3.select("select#division option:checked").text()
    # scope
    scope_across = d3.select("input#across").property("checked")
    scope = if scope_across then "across" else "within"

    # look for the person in the data
    this_person = [first_name, last_name, divisions.indexOf(selected_div)+1].join("|")

    index_in_data = person_index.find((d) -> d.name == this_person)

    if index_in_data?  # individual was found
        # if multiple records for that person: pick a random one?
        all_indices = person_index.filter((d) -> d.name == this_person)

        if all_indices.length > 1 # pick a random one
            index_in_data = all_indices[ Math.floor( Math.random() * all_indices.length ) ]

        d3.select("div#chart")
          .text("Yay we found #{first_name} #{last_name} in #{selected_div}")

        this_record = salaries[index_in_data.index]
        title = this_record.title
        salary = this_record.AnnualSalary
        target_jobcodes = jobcodes[title]

        salaries_subset = salaries.filter((d) -> target_jobcodes.indexOf(d.JobCode) >= 0)

        if scope=="within" # subset by division
            salaries_subset = salaries_subset.filter((d) -> d.Division == this_record.Division)

        comp_salaries = (d.AnnualSalary for d in salaries_subset)
        labels = (d.FirstName + " " + d.LastName for d in salaries_subset)

        # different color for the identified individual
        group = (2 for d in salaries_subset)
        this_index = (i for i of salaries_subset when salaries_subset[i].FirstName==first_name and salaries_subset[i].LastName==last_name)
        if this_index >= 0
            group[this_index] = 1

        mychart = d3panels.dotchart({
            xlab:"",
            ylab:"Salaries",
            title:"",
            height:300,
            width:800,
            horizontal:true})

        data_to_plot = {x:(" " for d in comp_salaries), y:comp_salaries, indID:labels, group:group}
        mychart(d3.select("div#chart"), data_to_plot)

        mychart.points()
            .on "mouseover", (d) -> d3.select(this).attr("r", 6)
            .on "mouseout", (d) -> d3.select(this).attr("r", 3)

    else
        d3.select("div#chart")
          .text("#{first_name} #{last_name} not found in #{selected_div}")

# dotplot of those points
# add boxplot over the dotplot
