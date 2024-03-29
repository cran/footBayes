% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/foot_abilities.R
\name{foot_abilities}
\alias{foot_abilities}
\title{Plot football abilities from Stan and MLE models}
\usage{
foot_abilities(object, data, type = c("attack", "defense", "both"), team, ...)
}
\arguments{
\item{object}{An object either of class \code{stanfit} as given by \code{stan_foot} function or class
\code{\link{list}} containing the Maximum Likelihood Estimates (MLE) for the model parameters fitted
 with \code{mle_foot}.}

\item{data}{A data frame, or a matrix containing the following mandatory items: home team, away team,
home goals, away goals.}

\item{type}{Type of ability in Poisson models: one among \code{"defense"}, \code{"attack"} or \code{"both"}.}

\item{team}{Valid team names.}

\item{...}{Optional graphical parameters.}
}
\value{
Abilities plots for the selected teams: for Poisson models only, red denotes the attack,
blue the defense.
}
\description{
Depicts teams' abilities either from the Stan models fitted via the \code{stan_foot} function
or from MLE models fitted via the \code{mle_foot} function.
}
\examples{
\dontrun{
require(dplyr)
require(tidyverse)

data("italy")
italy <- as_tibble(italy)

### no dynamics, no prediction

italy_2000_2002<- italy \%>\%
 dplyr::select(Season, home, visitor, hgoal, vgoal) \%>\%
 dplyr::filter(Season=="2000" |  Season=="2001" | Season =="2002")

fit1 <- stan_foot(data = italy_2000_2002,
                model="double_pois") # double poisson

fit2 <- stan_foot(data = italy_2000_2002,
                model="biv_pois")    # bivariate poisson

fit3 <- stan_foot(data = italy_2000_2002,
                model="skellam")     # skellam

fit4 <- stan_foot(data = italy_2000_2002,
                model="student_t")   # student_t

foot_abilities(fit1, italy_2000_2002)
foot_abilities(fit2, italy_2000_2002)
foot_abilities(fit3, italy_2000_2002)
foot_abilities(fit4, italy_2000_2002)

### seasonal dynamics, predict the last season

fit5 <-stan_foot(data = italy_2000_2002,
                       model="biv_pois", predict =306,
                       dynamic_type = "seasonal")   # bivariate poisson
foot_abilities(fit5, italy_2000_2002)

}
}
\author{
Leonardo Egidi \email{legidi@units.it}
}
