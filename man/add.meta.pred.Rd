% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/add_meta_pred.r
\name{add.meta.pred}
\alias{add.meta.pred}
\title{Add metadata as predictors}
\usage{
add.meta.pred(siamcat, pred.names = NULL, std.meta =
    TRUE, verbose = 1)
}
\arguments{
\item{siamcat}{object of class \link{siamcat-class}}

\item{pred.names}{vector of names of the variables within the metadata to be
added to the feature matrix as predictors}

\item{std.meta}{boolean, should added metadata features be standardized?,
defaults to \code{TRUE}}

\item{verbose}{control output: \code{0} for no output at all, \code{1} for
only information about progress and success, \code{2} for normal level of
information and \code{3} for full debug information, defaults to \code{1}}
}
\value{
an object of class \link{siamcat-class} with metadata added to the
    features
}
\description{
This function adds metadata to the feature matrix to be later
    used as predictors
}
\examples{
    data(siamcat_example)
    # Add the Age of the patients as potential predictor
    siamcat_age_added <- add.meta.pred(siamcat_example, pred.names=c('age'))

    # Add Age, BMI, and Gender as potential predictors
    # Additionally, prevent standardization of the added features
    siamcat_meta_added <- add.meta.pred(siamcat_example, pred.names=c('age',
    'bmi', 'gender'), std.meta=FALSE)
}
\keyword{SIAMCAT}
\keyword{add.meta.pred}
