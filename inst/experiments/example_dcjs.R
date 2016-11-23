library(htmltools)
library(crosstalk)
library(igraph)
library(networkD3)

# Use igraph to make the graph and find membership
karate <- make_graph("Zachary")

# example from ?networkD3::igraph_to_networkD3
karate <- make_graph("Zachary")
wc <- cluster_walktrap(karate)
members <- membership(wc)
karate_d3 <- igraph_to_networkD3(karate, group = members)
fn <- forceNetwork(
  Links = karate_d3$links, Nodes = karate_d3$nodes,
  Source = 'source', Target = 'target', NodeID = 'name',
  Group = 'group',
  height = 400, width = 400
)

fn <- htmlwidgets::onRender(
  fn,
"
function(el,x) {
  // as a quick example of bidirectional communication
  //   filter force node if clicked and is source
  //   in dc heat chart
  d3.select(el).selectAll('.node').on('click.ct',function(d,i){
    heatChart.data().map(function(dd,ii){
      if(dd.key[0]==d.name){
        heatChart.filter(dd.key);
      }
    });
  });
}
"
)

browsable(
  attachDependencies(
    tagList(
      tags$head(
        tags$script(src="https://d3js.org/d3.v3.min.js"),
        tags$script(src="http://dc-js.github.io/dc.js/js/crossfilter.js"),
        tags$script(src="http://dc-js.github.io/dc.js/js/dc.js"),
        tags$link(
          href="http://dc-js.github.io/dc.js/css/dc.css",
          rel="stylesheet"
        )
      ),
      tags$div(id="chart-heat", style="display:inline-block;"),
      tags$div(as.tags(fn), style="display:inline-block"),
      tags$script(
        HTML(
          sprintf(
  "
  var data = %s;

  var ndx = crossfilter(data);
  var netDim = ndx.dimension(function(d){return [+d.from,+d.to]});
  var netGrp = netDim.group().reduceSum(function(d){return 1});

  var heatChart = dc.heatMap('#chart-heat')
  heatChart
    .width(400)
    .height(400)
    .dimension(netDim)
    .group(netGrp)
    .keyAccessor(function(d) { return +d.key[0]; })
    .valueAccessor(function(d) { return +d.key[1]; })
    .title(function(d) {
      return 'Source:   ' + d.key[0] + '\\n' +
      'Target:  ' + d.key[1] + '\\n'});// +
      //'Weight: ' + d.value;})

  heatChart.render();

  // we do not need crosstalk for this
  //   but use it anyways to demonstate and experiment
  //   with crosstalk as our holder for filter state
  var ct_grp = crosstalk.group('grp1');
  var ct_filter = crosstalk.filter.createHandle(ct_grp);

  // add a filter listener on our dc.js heatmap
  heatChart.on('filtered',function(chart){
    ct_filter.set(chart.filters());
  })

  // now make a function to highlight selected nodes and links
  function highlightForce(filters){
    var force_svg = d3.select('.forceNetwork svg');
    var force_nodes = force_svg.selectAll('.node');
    var force_links = force_svg.selectAll('.link');

    var matched = function(link){
      var found = false;
      for(i=0; i< filters.length; i++){
        if(filters[i][0] == link.source.name && filters[i][1] == link.target.name){
          found = true;
          break;
        }
      }
      return found;
    };

    force_links.each(function(link){
      if(matched(link)){
        d3.select(this).style('stroke-width',5);
      } else {
        d3.select(this).style('stroke-width',1);
      }
    });
  }

  // when crosstalk filter changes highlight
  ct_filter.on('change',function(val){
    highlightForce(val.value);
    heatChart.redrawGroup();
  })

",
            jsonlite::toJSON(
              get.data.frame(karate),
              dataframe="rows"
            )
          )
        )
      )
    ),
    crosstalk::crosstalkLibs()
  )
)
