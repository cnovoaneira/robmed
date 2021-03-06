% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/run_shiny_app.R
\name{run_shiny_app}
\alias{run_shiny_app}
\title{Shiny app: simulation for mediation analysis with outliers}
\usage{
run_shiny_app()
}
\description{
Compare various bootstrap methods for mediation analysis on simulated data.
}
\details{
The default settings follow the simulation design of Zu & Yuan (2010).  You
can adjust the total number of observations, the values of the coefficients
in the mediation model, the number of outliers, as well as the expected
distance of the outliers from the main point cloud.

As this simulation is just for illustration, the bootstrap procedures use
only 1000 replicates.  For each selected methods, the bootstrap distribution
of the indirect effect is shown together with a shaded area representing the
95\% confidence interval.
}
\examples{
\dontrun{
run_shiny_app()
}

}
\seealso{
\code{\link{test_mediation}}
}
\author{
Andreas Alfons
}
\keyword{documentation}
