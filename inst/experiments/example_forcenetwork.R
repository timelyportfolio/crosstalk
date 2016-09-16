library(htmltools)
library(networkD3)


# demonstrate with experimental crosstalk
#  this will get much easier once we start converting
#  htmlwidgets to work natively with crosstalk

#devtoools::install_github("rstudio/crosstalk")
library(crosstalk)

data(MisLinks)
data(MisNodes)

# make a forceNetwork as shown in ?forceNetwork
fn <- forceNetwork(
  Links = MisLinks, Nodes = MisNodes, Source = "source",
  Target = "target", Value = "value", NodeID = "name",
  Group = "group", opacity = 0.4, zoom = TRUE
)

sd <- SharedData$new(MisNodes, key=~name, group="grp1" )

# no autocomplete so not the same
#  but will use this instead of writing something new
fs <- filter_select(
  id = "filter-node",
  label = "Search Nodes",
  sharedData = sd,
  group = ~name
)

fn <- htmlwidgets::onRender(
  fn,
'
function(el,x){
  // get the crosstalk group
  //  we used grp1 in the SharedData from R
  var ct_grp = crosstalk.group("grp1");
debugger;
  ct_grp
    .var("filter")
    .on("change", function(val){searchNode(val.value)});

  function searchNode(filter_nodes) {
    debugger;
    //find the node
    var selectedVal = filter_nodes? filter_nodes : [];
    var svg = d3.select(el).select("svg");
    var node = d3.select(el).selectAll(".node");

    if (selectedVal.length===0) {
      node.style("opacity", "1");
      svg.selectAll(".link").style("opacity","1");
    } else {
      var selected = node.filter(function (d, i) {
        return selectedVal.indexOf(d.name) >= 0;
      });
      node.style("opacity","0");
      selected.style("opacity", "1");
      var link = svg.selectAll(".link").style("opacity", "0");
      /*
      svg.selectAll(".node, .link").transition()
        .duration(5000)
        .style("opacity", 1);
      */
    }
  }
}
'
)

browsable(
  tagList(
    fs,
    fn
  )
)
