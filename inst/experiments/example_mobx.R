library(crosstalk)
library(htmltools)
library(tibble)
library(dplyr)

mtcars_tbl <- as_tibble(mtcars) %>%
  rownames_to_column()
sd <- SharedData$new(mtcars_tbl, key=~rowname, group="grp1")


mobx <- htmlDependency(
  name="mobx",
  version="2.6.3",
  src=c(href="https://cdnjs.cloudflare.com/ajax/libs/mobx/2.6.3/"),
  script="mobx.umd.js"
)

browsable(
  attachDependencies(
    tagList(
      crosstalk::filter_select(
        "select-car",
        "Car",
        sd,
        "rowname"
      ),
      tags$script(
"
var ct_filter = new crosstalk.FilterHandle('grp1');

var xv = mobx.extendObservable(
  crosstalk.group('grp1').var('filter'),{_value:this._value}
);

mobx.autorun(function(){
  console.log(
    typeof(xv._value)==='undefined' || xv._value===null ? null : xv._value.toJS()
  )
});
"
      )
    ),
    mobx
  )
)

browsable(
  attachDependencies(
    tagList(
      crosstalk::filter_select(
        "select-car",
        "Car",
        sd,
        "rowname"
      ),
      crosstalk::filter_select(
        "select-cyl",
        "Cyl",
        sd,
        "cyl"
      )
    ),
    mobx
  )
)
