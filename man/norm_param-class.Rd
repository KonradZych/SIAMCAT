% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/siamcat_all_class_definitions.R
\docType{class}
\name{norm_param-class}
\alias{norm_param-class}
\title{The S4 class for storing the normalization paramters}
\description{
The S4 class for storing the normalization paramters
}
\section{Slots}{

\describe{
\item{\code{.Data}}{inherited from \code{\link{list}} class, contains
a list with:
    \itemize{
    \item \code{norm.method} the normalization method used
    \item \code{retained.feat} the names of features retained after filtering
    \item \code{log.n0} pseudocount
    \item \code{n.p} vector norm
    \item \code{norm.margin} margin for the normalization
} and additional entries depending on the normalization method used.}
}}

