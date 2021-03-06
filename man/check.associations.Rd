% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/check_associations.r
\name{check.associations}
\alias{check.associations}
\title{Check and visualize associations between features and classes}
\usage{
check.associations(siamcat,fn.plot,color.scheme = "RdYlBu",
    alpha =0.05,mult.corr = "fdr", sort.by = "fc",detect.lim = 1e-06,
    pr.cutoff = 1e-6, max.show = 50, plot.type = "quantile.box",
    panels = c("fc","auroc"),verbose = 1)
}
\arguments{
\item{siamcat}{object of class \link{siamcat-class}}

\item{fn.plot}{filename for the pdf-plot}

\item{color.scheme}{valid R color scheme or vector of valid R colors (must be
of the same length as the number of classes), defaults to \code{'RdYlBu'}}

\item{alpha}{float, significance level, defaults to \code{0.05}}

\item{mult.corr}{multiple hypothesis correction method, see
\code{\link[stats]{p.adjust}}, defaults to \code{"fdr"}}

\item{sort.by}{string, sort features by p-value (\code{"p.val"}), by fold
change (\code{"fc"}) or by prevalence shift (\code{"pr.shift"}),
defaults to \code{"fc"}}

\item{detect.lim}{float, pseudocount to be added before log-transformation of
the data, defaults to \code{1e-06}}

\item{pr.cutoff}{float, cutoff for the prevalence computation, defaults to
\code{1e-06}}

\item{max.show}{integer, how many associated features should be shown,
defaults to \code{50}}

\item{plot.type}{string, specify how the abundance should be plotted, must be
one of these: \code{c("bean", "box", "quantile.box", "quantile.rect")},
defaults to \code{"quantile.box"}}

\item{panels}{vector, name of the panels to be plotted next to the log10-
transformed abundances, possible entries are \code{c("fc", "auroc",
"prevalence")}, defaults to \code{c("fc", "auroc")}}

\item{verbose}{control output: \code{0} for no output at all, \code{1} for
only information about progress and success, \code{2} for normal level of
information and \code{3} for full debug information, defaults to \code{1}}
}
\value{
Does not return anything, but produces an association plot
}
\description{
This function calculates for each feature a pseudo-fold change
    (geometrical mean of the difference between quantiles) between the
    different classes found in labels.

    Significance of the differences is computed for each feature using a
    Wilcoxon test followed by multiple hypothesis testing correction.

    Additionally, the Area Under the Receiver Operating Characteristic Curve
    (AU-ROC) and a prevalence shift are computed for the features found to be
    associated with the two different classes at a user-specified
    significance level \code{alpha}.

    Finally, the function produces a plot of the top \code{max.show}
    associated features, showing the distribution of the log10-transformed
    abundances for both classes, and user-selected panels for the effect
    (AU-ROC, Prevalence Shift, and Fold Change)
}
\examples{
# Example data
    data(siamcat_example)
# since the whole pipeline has been run in the example data, exchange the
# normalized features with the original features
    siamcat_example <- reset.features(siamcat_example)

# Simple example
    check.associations(siamcat_example, './assoc_plot.pdf')

# Plot associations as bean plot
    check.associations(siamcat_example, './assoc_plot_bean.pdf',
    plot.type='bean')

# Plot assocations as box plot
# Additionally, sort by p-value instead of by fold change
    check.associations(siamcat_example, './assoc_plot_fc.pdf',
    plot.type='box', sort.by='p.val')

# Custom colors
    check.associations(siamcat_example, './assoc_plot_blue_yellow.pdf',
    plot.type='box', color.scheme=c('cornflowerblue', '#ffc125'))
}
\keyword{SIAMCAT}
\keyword{check.associations}
