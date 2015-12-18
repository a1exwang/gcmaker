var margin = {top: 20, right: 80, bottom: 30, left: 50},
    width = 960 - margin.left - margin.right,
    height = 500 - margin.top - margin.bottom;

var x = d3.scale.linear()
    .range([0, width]);

var y = d3.scale.linear()
    .range([height, 0]);

var color = d3.scale.category10();

var xAxis = d3.svg.axis()
    .scale(x)
    .orient("bottom");

var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left");

var line = d3.svg.line()
    .interpolate("basis")
    .x(function(d) { return x(d.time); })
    .y(function(d) { return y(d.value); });

var svg = d3.select("#graphContainer").append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

var tasksSvg;

var data = [];

function repaint(curves) {
    //var curves = [ { name: 'wav', values: values } ];
    x.domain(d3.extent(curves[0].values, function(d) { return d.time; }));

    y.domain([
        d3.min(curves, function(c) { return d3.min(c.values, function(v) { return v.value; }); }),
        d3.max(curves, function(c) { return d3.max(c.values, function(v) { return v.value; }); })
    ]);

    svg.append("g")
        .attr("id", "x-axis")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + height + ")")
        .call(xAxis)
        .append("text")
        .style("text-anchor", "start")
        .attr("x", 820)
        .text("time/ms");

    svg.append("g")
        .attr("id", "y-axis")
        .attr("class", "y axis")
        .call(yAxis)
        .append("text")
        .attr("transform", "rotate(-90)")
        .attr("y", 6)
        .attr("dy", ".71em")
        .style("text-anchor", "end")
        .text("magnitude");

    tasksSvg = svg.selectAll(".city")
        .data(curves)
        .enter();

    tasksSvg.append("path")
        .attr("class", "line")
        .attr("d", function(d) { return line(d.values); })
        .style("stroke", function(d) { return color(d.name); });

    // remark on a line
    tasksSvg.append("text")
        .datum(function(d) { return { name: d.name, value: d.values[d.values.length - 1]}; })
        .attr("transform", function(d) { return "translate(" + x(d.value.time) + "," + y(d.value.value) + ")"; })
        .attr("x", 3)
        .attr("dy", ".35em")
        .text(function(d) { return d.name; });
}

d3.json("data/graph.json", function(error, json) {
    if (error) throw error;
    var period = json['period'];
    var c = json['curves'];

    var curves = [];
    for (var j = 0; j < c.length; ++j) {
        var current = [];
        for (var i = 0; i < c[j]['values'].length; ++i) {
            current.push({
                time: i * period * 1000,
                value: c[j]['values'][i]
            });
        }
        curves.push({
            name: c[j]['name'],
            values: current
        })
    }

    repaint(curves);
});