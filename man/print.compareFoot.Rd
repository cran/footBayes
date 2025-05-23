% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/print_fun_foot.R
\name{print.compareFoot}
\alias{print.compareFoot}
\title{Print method for compareFoot objects}
\usage{
\method{print}{compareFoot}(x, digits = 3, ...)
}
\arguments{
\item{x}{An object of class \code{compareFoot} returned by \code{\link{compare_foot}}.}

\item{digits}{Number of digits to use when printing numeric values for the metrics. Default is \code{3}.}

\item{...}{Additional arguments passed to \code{print}.}
}
\description{
Provides a formatted output when printing objects of class \code{compareFoot}, displaying the predictive performance metrics and, if available, the confusion matrices for each model or probability matrix.
}
\author{
Roberto Macrì Demartino \email{roberto.macridemartino@deams.units.it}
}
