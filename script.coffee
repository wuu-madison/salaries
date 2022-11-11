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
    last_name = d3.select("input#last_name").property("value")
    first_name = d3.select("input#first_name").property("value")
    # division
    selected_div = d3.select("select#division option:checked").text()
    # scope
    scope_across = d3.select("input#across").property("checked")
    scope = if scope_across then "across" else "within"

    # look for the person in the data
    this_person = [first_name, last_name, divisions.indexOf(selected_div)+1].join("|").toUpperCase()
    console.log(this_person)

    index_in_data = person_index.find((d) -> d.name == this_person)

    if index_in_data?  # individual was found
        # if multiple records for that person: pick a random one?
        all_indices = person_index.filter((d) -> d.name == this_person)

        if all_indices.length > 1 # pick a random one
            index_in_data = all_indices[ Math.floor( Math.random() * all_indices.length ) ]

    console.log(index_in_data)

#    result = (v for v in x when v.a==2 and v.b==4)

    d3.select("div#chart")
      .text("hello #{first_name} #{last_name} (#{selected_div}) - #{scope}")



# look for matching record
# find the job codes for that person's title
# look for other people with one of those job codes (overall, or within that division)
# dotplot of those points
# add boxplot over the dotplot
