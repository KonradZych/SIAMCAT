% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/siamcat_class_accessors.R
\docType{methods}
\name{orig_feat}
\alias{orig_feat}
\alias{orig_feat,ANY-method}
\alias{orig_feat,orig_feat-method}
\title{Retrieve a \link[phyloseq]{otu_table-class} object from orig_feat slot.}
\usage{
orig_feat(siamcat)

\S4method{orig_feat}{ANY}(siamcat)

\S4method{orig_feat}{orig_feat}(siamcat)
}
\arguments{
\item{siamcat}{(Required). An instance of \link{siamcat-class}
that contains a label or instance of \link[phyloseq]{otu_table-class}.}
}
\value{
The \link[phyloseq]{otu_table-class} object or NULL.
}
\description{
Retrieve a \link[phyloseq]{otu_table-class} object from orig_feat slot.
}
\examples{
    data(siamcat_example)
    data_split(siamcat_example)
}
