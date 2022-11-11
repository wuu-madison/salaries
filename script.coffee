d3.json("divisions.json", (div) ->
    submit = d3.select("div#form select.submit")
    submit.append("option")
          .attr("value", "hello")
    submit.append("option")
          .attr("value", "karl")
)
