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
