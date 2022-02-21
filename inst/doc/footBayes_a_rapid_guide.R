## ----setup,  include = FALSE--------------------------------------------------
NOT_CRAN <- identical(tolower(Sys.getenv("NOT_CRAN")), "true")
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  purl = NOT_CRAN,
  eval = NOT_CRAN
)
knitr::opts_chunk$set(fig.align = 'center', 
                      warning=FALSE, message=FALSE, fig.asp=0.625, fig.height =10, fig.width = 8, 
                      out.width='750px', dpi=200, 
                      global.par = TRUE,
                      dev='png',  
                      dev.args=list(pointsize=10)
                      ,fig.path = 'figs/'
                      )

