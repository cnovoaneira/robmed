% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/summary.R
\name{summary.test_mediation}
\alias{summary.test_mediation}
\alias{summary.boot_test_mediation}
\alias{summary.sobel_test_mediation}
\title{Summary of results from (robust) mediation analysis}
\usage{
\method{summary}{boot_test_mediation}(object, other = c("boot",
  "theory"), ...)

\method{summary}{sobel_test_mediation}(object, ...)
}
\arguments{
\item{object}{an object inheriting from class
\code{"\link{test_mediation}"} containing results from (robust) mediation
analysis.}

\item{other}{a character string specifying how to summarize the effects
other than the indirect effect(s).  Possible values are \code{"boot"} (the
default) to compute significance tests using the normal approximation of the
bootstrap distribution (i.e., to assume a normal distribution of the
corresponding effect with the standard deviation computed from the bootstrap
replicates), or \code{"theory"} to compute significance tests via
statistical theory (e.g., t-tests if the coefficients are estimated via
regression).  Note that this is only relevant for mediation analysis via a
bootstrap test, where significance of the indirect effect is always assessed
via a percentile-based confidence interval due to the asymmetry of its
distribution.}

\item{\dots}{additional arguments are currently ignored.}
}
\value{
An object of class \code{"summary_test_mediation"} with the
following components:
\item{object}{the \code{object} passed to the \code{summary} method, which
contains the results from testing the indirect effect.}
\item{summary}{an object containing all necessary information to summarize
the effects other than the indirect effect.}
}
\description{
Summarize results from (robust) mediation analysis for proper interpretation.
}
\examples{
data("BSG2014")
test <- test_mediation(BSG2014,
                       x = "ValueDiversity",
                       y = "TeamCommitment",
                       m = "TaskConflict")
summary(test)

}
\seealso{
\code{\link{test_mediation}}
}
\author{
Andreas Alfons
}
\keyword{utilities}
