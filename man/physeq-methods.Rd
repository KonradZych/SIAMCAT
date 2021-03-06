% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/siamcat_class_accessors.R
\docType{methods}
\name{physeq}
\alias{physeq}
\alias{physeq,ANY-method}
\alias{physeq,phyloseq-method}
\title{Retrieve a \link[phyloseq]{phyloseq-class} object from object.}
\usage{
physeq(siamcat)

\S4method{physeq}{ANY}(siamcat)

\S4method{physeq}{phyloseq}(siamcat)
}
\arguments{
\item{siamcat}{(Required). An instance of \link{siamcat-class}
that contains a label or instance of \link[phyloseq]{phyloseq-class}.}
}
\value{
The \link[phyloseq]{phyloseq-class} object or NULL.
}
\description{
Retrieve a \link[phyloseq]{phyloseq-class} object from object.
}
\examples{
    data(siamcat_example)
    physeq(siamcat_example)
}
