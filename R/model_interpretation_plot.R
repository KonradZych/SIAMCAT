#!/usr/bin/Rscript
### SIAMCAT - Statistical Inference of Associations between
### Microbial Communities And host phenoTypes R flavor EMBL
### Heidelberg 2012-2018 GNU GPL 3.0

#' @title Model Interpretation Plot
#' 
#' @description Produces a plot for model interpretation, displaying feature
#'     weights, robustness of feature weights, and features scores across
#'     patients.
#'     
#' @usage model.interpretation.plot(siamcat, fn.plot, color.scheme = "BrBG",
#' consens.thres = 0.5,heatmap.type = c("zscore", "fc"), 
#' norm.models = FALSE, limits = c(-3, 3), detect.lim = 1e-06, 
#' max.show = 50, verbose = 1)
#'     
#' @param siamcat object of class \link{siamcat-class}
#' 
#' @param fn.plot string, filename for the pdf-plot
#' 
#' @param color.scheme color scheme for the heatmap, defaults to \code{'BrBG'}
#' 
#' @param consens.thres minimal ratio of models incorporating a feature in order
#'     to include it into the heatmap, defaults to \code{0.5}
#'     Note that for \code{'randomForest'} models, this cutoff specifies the
#'     minimum median Gini coefficient for a feature to be included and
#'     should therefore be much lower, e.g. \code{0.01}
#'     
#' @param heatmap.type type of the heatmap, can be either \code{'fc'} or
#'     \code{'zscore'}, defaults to \code{'zscore'}
#'     
#' @param norm.models boolean, should the feature weights be normalized across
#'     models?, defaults to \code{FALSE}
#'     
#' @param limits vector, cutoff for extreme values in the heatmap,
#'     defaults to \code{c(-3, 3)}
#'     
#' @param detect.lim float, pseudocount to be added before log-transformation
#'     of features, defaults to \code{1e-06}
#'     
#' @param max.show integer, maximum number of features to be shown in the model
#'     interpretation plot, defaults to 50
#'     
#' @param verbose control output: \code{0} for no output at all, \code{1}
#'     for only information about progress and success, \code{2} for normal
#'     level of information and \code{3} for full debug information,
#'     defaults to \code{1}
#'     
#' @keywords SIAMCAT model.interpretation.plot
#' 
#' @return Does not return anything, but produces the model interpretion plot.
#' 
#' @export
#' 
#' @details Produces a plot consisting of \itemize{
#'     \item a barplot showing the feature weights and their robustness (i.e. in
#'     what proportion of models have they been incorporated)
#'     \item a heatmap showing the z-scores of the metagenomic features across
#'     patients
#'     \item another heatmap displaying the metadata categories (if applicable)
#'     \item a boxplot displaying the poportion of weight per model that is
#'     actually shown for the features that are incorporated into more than
#'     \code{consens.thres} percent of the models.
#'}
#'
#' @examples
#'
#'     data(siamcat_example)
#'     # simple working example
#'     model.interpretation.plot(siamcat_example, fn.plot='./interpretion,pdf',
#'     heatmap.type='zscore')
#'
model.interpretation.plot <-
    function(siamcat,
        fn.plot,
        color.scheme = "BrBG",
        consens.thres = 0.5,
        heatmap.type = c("zscore", "fc"),
        norm.models = FALSE,
        limits = c(-3, 3),
        detect.lim = 1e-06,
        max.show = 50,
        verbose = 1) {
        if (verbose > 1)
            message("+ starting model.evaluation.plot")
        s.time <- proc.time()[3]
        label <- label(siamcat)
        model.type <- model_type(siamcat)
        models <- models(siamcat)
# #########################################################################
# some color pre-processing
        if (verbose > 2)
            message("+++ preprocessing color scheme")
        if (!color.scheme %in% row.names(brewer.pal.info)) {
            warning(
                "Not a valid RColorBrewer palette name, defaulting to BrBG...\n
                See brewer.pal.info for more information about 
                RColorBrewer palettes."
            )
            color.scheme <- "BrBG"
        }
        color.scheme <-
            rev(colorRampPalette(
                brewer.pal(brewer.pal.info[color.scheme, "maxcolors"], 
                    color.scheme))(100))
        
# #########################################################################
# get model type from model
        if (verbose > 2)
            message("+++ retrieving model type")
        W.mat <- get.weights.matrix(models, verbose = verbose)
# remove possible intercept parameters, but keep possible meta data
# included in the model
        all.weights <- W.mat[union(row.names(features(siamcat)),
            grep("META", row.names(W.mat), value = TRUE)), ]
        rel.weights <- t(t(all.weights) / colSums(abs(all.weights)))
# #########################################################################
# preprocess models
        if (verbose > 2)
            message("+++ preprocessing models")
        sel.idx <-
            model.interpretation.select.features(
                weights = all.weights,
                model.type = model.type,
                consens.thres = consens.thres,
                label = label,
                norm.models = norm.models,
                max.show = max.show,
                verbose = verbose
            )
        num.sel.f <- length(sel.idx)
# #########################################################################
# aggreate predictions and sort
# patients by score aggregate predictions of several models if more than
# one is given
        mean.agg.pred <- rowMeans(pred_matrix(siamcat))
# idx to sort samples according to their class membership and prediction
# score
        srt.idx <-
            sort(label$label + mean.agg.pred, index.return = TRUE)$ix
# #########################################################################
# prepare heatmap
        if (verbose > 2)
            message("+++ preparing heatmap")
        if (heatmap.type == "zscore") {
            feat <- get.features.matrix(siamcat)
            img.data <- model.interpretation.prepare.heatmap.zscore(
                heatmap.data = feat[sel.idx, srt.idx],
                limits = limits,
                verbose = verbose
            )
        } else if (heatmap.type == "fc") {
            feat <- get.orig_feat.matrix(siamcat)
            if (is.null(detect.lim)) {
                warning(
                    "WARNING: Pseudo-count before log-transformation
                    not supplied! Estimating it as 5% percentile..."
                )
                detect.lim <- quantile(feat[feat != 0], 0.05)
            }
            img.data <- model.interpretation.prepare.heatmap.fc(
                heatmap.data = feat[, srt.idx],
                sel.feat = names(sel.idx),
                limits = limits,
                meta = meta(siamcat),
                label = label,
                detect.lim = detect.lim,
                verbose = verbose
            )
        } else {
            stop("! unknown heatmap.type: ", heatmap.type)
        }
        
# #########################################################################
# start plotting model properties
        if (verbose > 2)
            message("+++ plotting model properties")
        pdf(
            fn.plot,
            paper = "special",
            height = 8.27,
            width = 11.69,
            onefile = TRUE
        )
        
### plot layout
        sel.f.cex <- max(0.3, 0.8 - 0.01 * num.sel.f)
        lmat <- rbind(c(1, 2, 3, 4), c(5, 6, 0, 7), c(0, 8, 0, 0))
        h_t <- 0.1
        h_m <- ifelse(is.null(meta(siamcat)), 0.8,
            max(0.5, 0.7 - 0.01 * ncol(meta(siamcat))))
        h_b <- 1 - h_t - h_m
        message(paste0("Layout height values: ", h_t, ", ", h_m, ", ", h_b))
        layout(lmat,
            widths = c(0.14, 0.58, 0.1, 0.14),
            heights = c(h_t, h_m, h_b))
        par(oma = c(3, 4, 3, 4))
        
### header row
#########################################################################
# Title of Feature Weights
        if (verbose > 2)
            message("+++ plotting titles")
        par(mar = c(0, 1.1, 3.1, 1.1))
        plot(
            NULL,
            type = "n",
            xlim = c(-0.1, 0.1),
            xaxt = "n",
            xlab = "",
            ylim = c(-0.1, 0.1),
            yaxt = "n",
            ylab = "",
            bty = "n"
        )
        mtext(
            "Feature Weights",
            side = 3,
            line = 2,
            at = 0.04,
            cex = 1,
            adj = 0.5
        )
        
# #########################################################################
# Title of heatmap and brackets for classes
        par(mar = c(0, 4.1, 3.1, 5.1))
        hm.label <- label$label[srt.idx]
        plot(
            NULL,
            type = "n",
            xlim = c(0, length(hm.label)),
            xaxs = "i",
            xaxt = "n",
            ylim = c(-0.5, 0.5),
            yaxs = "i",
            yaxt = "n",
            xlab = "",
            ylab = "",
            bty = "n"
        )
        ul <- unique(hm.label)
        for (l in seq_along(ul)) {
            idx <- which(ul[l] == hm.label)
            lines(c(idx[1] - 0.8, idx[length(idx)] - 0.2), c(0, 0))
            lines(c(idx[1] - 0.8, idx[1] - 0.8), c(-0.2, 0))
            lines(c(idx[length(idx)] - 0.2, idx[length(idx)] - 0.2), c(-0.2, 0))
            h <- (idx[1] + idx[length(idx)]) / 2
            t <- gsub("_", " ",
                names(label$info$class.descr)[label$info$class.descr == ul[l]])
            t <- paste(t, " (n=", length(idx), ")", sep = "")
            mtext(
                t,
                side = 3,
                line = -0.5,
                at = h,
                cex = 0.7,
                adj = 0.5
            )
        }
        mtext(
            "Metagenomic Features",
            side = 3,
            line = 2,
            at = length(hm.label) / 2,
            cex = 1,
            adj = 0.5
        )
        
# #########################################################################
# Heatmap legend
        if (verbose > 2)
            message("+++ plotting legend")
        par(mar = c(3.1, 1.1, 1.1, 1.1))
        barplot(
            as.matrix(rep(1, 100)),
            col = color.scheme,
            horiz = TRUE,
            border = 0,
            ylab = "",
            axes = FALSE
        )
        if (heatmap.type == "fc") {
            key.ticks <- seq(round(min(img.data, na.rm = TRUE), digits = 1),
                round(max(img.data, na.rm = TRUE), digits = 1),
                length.out = 7)
            key.label <- "Feature fold change over controls"
        } else if (heatmap.type == "zscore") {
            key.ticks <- seq(limits[1], limits[2], length.out = 7)
            key.label <- "Feature z-score"
        }
        axis(
            side = 1,
            at = seq(0, 100, length.out = 7),
            labels = key.ticks
        )
        mtext(
            key.label,
            side = 3,
            line = 0.5,
            at = 50,
            cex = 0.7,
            adj = 0.5
        )
        
# #########################################################################
# Model header (model sensitive)
        par(mar = c(0, 6.1, 3.1, 1.1))
        plot(
            NULL,
            type = "n",
            xlim = c(-0.1, 0.1),
            xaxt = "n",
            xlab = "",
            ylim = c(-0.1, 0.1),
            yaxt = "n",
            ylab = "",
            bty = "n"
        )
        mtext(
            paste0(model.type, " model"),
            side = 3,
            line = 2,
            at = 0.04,
            cex = 0.7,
            adj = 0.5
        )
        mtext(
            paste("(|W| = ", num.sel.f, ")", sep = ""),
            side = 3,
            line = 1,
            at = 0.04,
            cex = 0.7,
            adj = 0.5
        )
        
# #########################################################################
# Feature weights ( model sensitive)
        if (verbose > 2)
            message("+++ plotting feature weights")
        model.interpretation.feature.weights.plot(
            rel.weights = rel.weights,
            sel.idx = sel.idx,
            mod.type = model.type,
            label = label
        )
        
# #########################################################################
# Heatmap
        if (verbose > 2)
            message("+++ plotting heatmap")
        if (model.type != "RandomForest") {
            model.interpretation.heatmap.plot(
                image.data = img.data,
                limits = limits,
                color.scheme = color.scheme,
                effect.size = rowMedians(rel.weights[sel.idx,]),
                verbose = verbose
            )
        } else {
            auroc.effect <- apply(
                img.data,
                2,
                FUN = function(f) {
                    roc(
                        predictor = f,
                        response = label$label,
                        direction = "<"
                    )$auc
                }
            )
            bin.auroc.effect <- ifelse(auroc.effect >= 0.5, 1, 0)
            model.interpretation.heatmap.plot(
                image.data = img.data,
                limits = limits,
                color.scheme = color.scheme,
                effect.size = NULL,
                verbose = verbose
            )
        }
        
# #########################################################################
# Proportion of weights shown
        if (verbose > 2)
            message("+++ plotting proportion of weights shown")
        model.interpretation.proportion.of.weights.plot(
            selected.weights = all.weights[sel.idx, ],
            all.weights = all.weights,
            verbose = verbose
        )
        
# #########################################################################
# Metadata and prediction
        if (verbose > 2)
            message("+++ plotting metadata and predictions")
        model.interpretation.pred.and.meta.plot(
            prediction = mean.agg.pred[srt.idx],
            label = label,
            meta = meta(siamcat)[srt.idx,],
            verbose = verbose
        )
        
        tmp <- dev.off()
        e.time <- proc.time()[3]
        if (verbose > 1)
            message(paste(
                "+ finished model.interpretation.plot in",
                formatC(e.time - s.time, digits = 3),
                "s"
            ))
        if (verbose == 1)
            message(paste(
                "Plotted associations between features and label
                successfully to:",
                fn.plot
            ))
        }

# function to plot the feature weights
#' @keywords internal
model.interpretation.feature.weights.plot <-
    function(rel.weights,
        sel.idx,
        mod.type,
        label,
        verbose = 0) {
        if (verbose > 2)
            message("+ model.interpretation.feature.weights.plot")
        if (mod.type != "RandomForest") {
            relative.weights <- rel.weights[sel.idx, ]
        } else {
            relative.weights <- -rel.weights[sel.idx, ]
        }
        med <- rowMedians(relative.weights)
        low.qt <- rowQuantiles(relative.weights, probs = 0.25)
        upp.qt <- rowQuantiles(relative.weights, probs = 0.75)
        
        if (mod.type != "RandomForest") {
            par(mar = c(0.1, 1.1, 0, 1.1))
            mi = min(-med - (abs(low.qt - upp.qt)))
            mx = max(-med + (abs(low.qt - upp.qt)))
            
            barplot(
                -med,
                horiz = TRUE,
                width = 1,
                space = 0,
                yaxs = "i",
                col = "gray30",
                xlim = c(-max(abs(mi), abs(mx)),
                    max(abs(mi), max(mx))),
                ylim = c(0, dim(relative.weights)[1]),
                xlab = "",
                ylab = "",
                yaxt = "n"
            )
            x <- par("usr")
            rect(x[1], x[3], x[2], x[4], col = "lightgray")
    # grid lines
            grid(NULL, NA, lty = 2, col = "gray99")
    # plot the barplot again due to the idiotic way of how to change the
    # background color of a plot in r
            barplot(
                -med,
                horiz = TRUE,
                width = 1,
                space = 0,
                yaxs = "i",
                col = "gray30",
                xlim = c(-max(abs(mi), abs(mx)),
                    max(abs(mi), max(mx))),
                ylim = c(0, dim(relative.weights)[1]),
                xlab = "",
                ylab = "",
                yaxt = "n",
                add = TRUE
            )
            
    # error bars
            arrows(
                y0 = c(seq_along(med)) - 0.5,
                x0 = -upp.qt,
                x1 = -low.qt,
                angle = 90,
                code = 3,
                length = 0.04
            )
            mtext(
                "median relative feat. weight",
                side = 1,
                line = 2,
                at = 0,
                cex = 0.7,
                adj = 0.5
            )
    # robustness indicated as percentage of models including a given
    # feature (to the right of the barplot)
            for (f in seq_along(sel.idx)) {
                t = paste(format(
                    100 * sum(rel.weights[sel.idx[f], ] != 0) /
                        dim(rel.weights)[2],
                    digits = 1,
                    scientific = FALSE
                ),
                    "%",
                    sep = "")
                mtext(
                    t,
                    side = 4,
                    line = 2.5,
                    at = (f - 0.5),
                    cex = max(0.3, 0.8 - 0.01 * length(sel.idx)),
                    las = 2,
                    adj = 1
                )
            }
            
    # label cancer/healthy
            mtext(
                gsub("_", " ", label$n.lab),
                side = 2,
                at = floor(length(sel.idx) / 2),
                line = -2
            )
            mtext(
                gsub("_", " ", label$p.lab),
                side = 4,
                at = floor(length(sel.idx) / 2),
                line = -2
            )
            
            mtext(
                "effect size",
                side = 3,
                line = 1,
                at = (mx / 2),
                cex = 0.7,
                adj = 1
            )
            mtext(
                "robustness",
                side = 3,
                line = 1,
                at = mx,
                cex = 0.7,
                adj = 0
            )
        } else {
            par(mar = c(0.1, 1.1, 0, 1.1))
            mx = max(-med + (abs(low.qt - upp.qt)))
            
            barplot(
                -med,
                horiz = TRUE,
                width = 1,
                space = 0,
                yaxs = "i",
                col = "gray30",
                xlim = c(0, mx),
                ylim = c(0,
                    dim(relative.weights)[1]),
                xlab = "",
                ylab = "",
                yaxt = "n"
            )
            x <- par("usr")
            rect(x[1], x[3], x[2], x[4], col = "lightgray")
    # grid lines
            grid(NULL, NA, lty = 2, col = "gray99")
    # plot the barplot again due to the idiotic way of how to change the
    # background color of a plot in r
            barplot(
                -med,
                horiz = TRUE,
                width = 1,
                space = 0,
                yaxs = "i",
                col = "gray30",
                xlim = c(0, mx),
                ylim = c(0,
                    dim(relative.weights)[1]),
                xlab = "",
                ylab = "",
                yaxt = "n",
                add = TRUE
            )
            
    # error bars
            arrows(
                y0 = c(seq_along(med)) - 0.5,
                x0 = -upp.qt,
                x1 = -low.qt,
                angle = 90,
                code = 3,
                length = 0.04
            )
    # labels
            mtext(
                "median relative Gini coefficient",
                side = 1,
                line = 2,
                at = mx / 2,
                cex = 0.7,
                adj = 0.5
            )
            mtext(
                "effect size",
                side = 3,
                line = 1,
                at = (mx / 2),
                cex = 0.7,
                adj = 0.5
            )
        }
        
        box(lwd = 1)
        if (verbose > 2)
            message("+ finished model.interpretation.feature.weights.plot")
    }

# function to plot the predictions and metadata
#' @keywords internal
model.interpretation.pred.and.meta.plot <-
    function(prediction,
        label,
        meta = NULL,
        verbose = 0) {
        if (verbose > 2)
            message("+ model.interpretation.pred.and.meta.plot")
        par(mar = c(1.1, 4.1, 0.3, 5.1))
        img.data = as.matrix(prediction)
        colnames(img.data) = "Classification result"
        img.data.processed <- NULL
        if (!is.null(meta)) {
            img.data = cbind(meta[, ncol(meta):1], img.data)
    ### transform any categorial column into a numeric one
            for (m in seq_len(ncol(img.data))) {
                cur.processed.data <- NULL
                if (all(is.numeric(img.data[, m]))) {
                    cur.processed.data = (img.data[, m] - min(img.data[, m],
                        na.rm = TRUE))
                    if (max(img.data[, m], na.rm = TRUE) != 0) {
                        cur.processed.data = cur.processed.data /
                            max(cur.processed.data, na.rm = TRUE)
                    }
                } else if (all(is.factor(img.data[, m]))) {
                    if (length(levels(img.data[, m])) < 10) {
                        cur.processed.data <- img.data[, m]
                    } else {
                        message(
                            "Metadata ",
                            colnames(img.data)[m],
                            " contains too many
                            levels and will not be shown!"
                        )
                    }
                    }
                img.data.processed <-
                    cbind(img.data.processed, cur.processed.data)
                }
        }
        
        grays = rev(gray(seq(0, 1, length.out = 100)))
        image(
            as.matrix(img.data),
            col = grays,
            xaxt = "n",
            yaxt = "n",
            xlab = "",
            ylab = "",
            bty = "n"
        )
        box(lwd = 1)
# add deliminator between the different classes
        abline(v = length(which(label$label == label$negative.lab)) /
                length(label$label),
            col = "red")
        
        meta.cex = max(0.3, 0.7 - 0.01 * ncol(img.data))
        for (m in seq_len(ncol(img.data))) {
            t = colnames(img.data)[m]
            t = gsub("\\.|_", " ", t)
            mtext(
                t,
                side = 4,
                line = 1,
                at = (m - 1) / (dim(img.data)[2] - 1),
                cex = meta.cex,
                las = 2
            )
        }
# mark missing values
        for (m in seq_len(ncol(img.data))) {
            idx = which(is.na(img.data[, m]))
            for (i in idx) {
                x = (i - 1) / (dim(img.data)[1] - 1)
                y = (m - 1) / (dim(img.data)[2] - 1)
                text(x, y, "NA", col = "red", cex = 0.4)
            }
        }
        if (verbose > 2)
            message("+ finished model.interpretation.pred.and.meta.plot")
    }

# function to plot the proportion of weights
#' @keywords internal
model.interpretation.proportion.of.weights.plot <-
    function(selected.weights,
        all.weights, verbose = 0) {
        if (verbose > 2)
            message("+ model.interpretation.proportion.of.weights.plot")
        par(mar = c(0.1, 6.1, 0, 1.1))
        boxplot(colSums(abs(selected.weights)) / colSums(abs(all.weights)),
            ylim = c(0, 1))
        mtext(
            "proportion of",
            side = 1,
            line = 1,
            at = 1,
            adj = 0.5,
            cex = 0.7
        )
        mtext(
            "weight shown",
            side = 1,
            line = 2,
            at = 1,
            adj = 0.5,
            cex = 0.7
        )
        if (verbose > 2)
            message(
                "+ finished model.interpretation.proportion.of.weights.plot")
    }

# function to plot the percentage of features
#' @keywords internal
plot.percentage.of.features.plot <-
    function(selected.weights, all.weights,
        verbose = 0) {
        if (verbose > 2)
            message("+ plot.percentage.of.features")
        par(mar = c(0.1, 6.1, 0, 1.1))
        boxplot(dim(selected.weights)[1] / colSums(all.weights != 0),
            ylim = c(0, 1))
        mtext(
            "percentage of",
            side = 1,
            line = 1,
            at = 1,
            adj = 0.5,
            cex = 0.7
        )
        mtext(
            "features shown",
            side = 1,
            line = 2,
            at = 1,
            adj = 0.5,
            cex = 0.7
        )
        if (verbose > 2)
            message("+ finished plot.percentage.of.features")
    }

# function to plot the heatmap
#' @keywords internal
model.interpretation.heatmap.plot <-
    function(image.data,
        limits,
        color.scheme,
        effect.size,
        verbose = 0) {
        if (verbose > 2)
            message("+ model.interpretation.heatmap.plot")
        par(mar = c(0.1, 4.1, 0, 5.1))
        image(
            image.data,
            zlim = limits,
            col = color.scheme,
            xaxt = "n",
            yaxt = "n",
            xlab = "",
            ylab = "",
            bty = "n"
        )
        if (!is.null(effect.size)) {
            for (f in seq_len(ncol(image.data))) {
                mtext(
                    colnames(image.data)[f],
                    side = 4,
                    line = 1,
                    at = (f - 1) / (dim(image.data)[2] - 1),
                    las = 2,
                    cex = max(0.3, 0.8 - 0.01 * dim(image.data)[2]),
                    col = ifelse(effect.size[f] > 0,
                        color.scheme[1 + 4], color.scheme[length(color.scheme) -
                                4])
                )
            }
        } else {
            for (f in seq_len(ncol(image.data))) {
                mtext(
                    colnames(image.data)[f],
                    side = 4,
                    line = 1,
                    at = (f - 1) /
                        (dim(image.data)[2] - 1),
                    las = 2,
                    cex = max(0.3,
                        0.8 - 0.01 * dim(image.data)[2]),
                    col = "black"
                )
            }
        }
        box(lwd = 1)
        if (verbose > 2)
            message("+ finished model.interpretation.heatmap.plot")
    }

# function to prepare the data to plot fold change heatmap
#' @keywords internal
model.interpretation.prepare.heatmap.fc <-
    function(heatmap.data,
        limits,
        sel.feat,
        meta = NULL,
        label,
        detect.lim,
        verbose = 0) {
        if (verbose > 2)
            message("+ model.interpretation.prepare.heatmap.fc")
        if (!any(grepl("META", sel.feat))) {
            feat.log <- log10(heatmap.data[sel.feat,] + detect.lim)
            img.data <- t(feat.log -
                    log10(rowMedians(heatmap.data[sel.feat, label$n.idx]) +
                            detect.lim))
        } else {
            img.data <- matrix(NA,
                nrow = length(sel.feat),
                ncol = ncol(heatmap.data))
            row.names(img.data) <- sel.feat
            if (verbose > 2)
                message("+ Selected features:")
            for (f in sel.feat) {
                if (verbose > 2)
                    message(paste("+++", f))
                if (!grepl("META", f)) {
                    median.ctr <-
                        suppressWarnings(median(as.numeric(
                            heatmap.data[f, label$n.idx])))
                    img.data[f, ] <-
                        log10(heatmap.data[f, ] + detect.lim) -
                        log10(median.ctr + detect.lim)
                } else {
                    meta.data <- meta[, grep(
                        strsplit(f, "_")[[1]][2],
                        colnames(meta),
                        ignore.case = TRUE,
                        value = TRUE
                    )]
            # transform metadata to zscores
                    meta.data <-
                        apply(meta.data, c(1, 2), as.numeric)
                    meta.data <-
                        (meta.data - mean(meta.data, na.rm = TRUE)) /
                        sd(meta.data, na.rm = TRUE)
                    img.data[f, ] <-
                        meta.data[colnames(heatmap.data)]
                }
            }
            img.data <- t(img.data)
        }
        img.data[img.data < limits[1]] = limits[1]
        img.data[img.data > limits[2]] = limits[2]
        if (verbose > 2)
            message("+ finished model.interpretation.heatmap.plot")
        return(img.data)
    }

# function to prepare the data to plot zscore heatmap
#' @keywords internal
model.interpretation.prepare.heatmap.zscore <-
    function(heatmap.data, limits,
        verbose = 0) {
        if (verbose > 2)
            message("+ model.interpretation.prepare.heatmap.zscore")
# data is transposed and transformed to feature z-scores for display
        img.data <-
            (heatmap.data - rowMeans(heatmap.data)) / rowSds(heatmap.data)
        img.data[img.data < limits[1]] <- limits[1]
        img.data[img.data > limits[2]] <- limits[2]
        if (verbose > 2)
            message("+ finished model.interpretation.heatmap.plot")
        return(t(img.data))
    }

# function to select the features to plot on the heatmap
#' @keywords internal
model.interpretation.select.features <-
    function(weights,
        model.type,
        consens.thres,
        norm.models,
        label,
        max.show,
        verbose = 0) {
        message("+ model.interpretation.select.features")
# for linear models, select those that have been selected more than
# consens.thres percent of the models
        if (model.type != "RandomForest") {
    # normalize by overall model size
            if (norm.models) {
                weights <- t(t(weights) / colSums(abs(weights)))
            }
            sel.idx = which(rowSums(weights != 0) / ncol(weights) >= 
                consens.thres)
    # normalize by model size and order features by relative model weight
            weights.norm <- t(t(weights) / colSums(abs(weights)))
            med.weights <- rowMedians(weights.norm)
            median.sorted.features <-
                sort(med.weights[sel.idx],
                    decreasing = TRUE,
                    index.return = TRUE)
    # restrict to plot at maximum fifty features
            if (length(sel.idx) > max.show) {
                warning("WARNING: restricting amount of features to
                    be plotted to 50")
                median.sorted.features.abs <- sort(abs(med.weights),
                    decreasing = TRUE,
                    index.return = TRUE)
                idx <-
                    head(median.sorted.features.abs$ix, n = max.show)
                median.sorted.features <- sort(med.weights[idx],
                    decreasing = TRUE,
                    index.return = TRUE)
                sel.idx <- idx[median.sorted.features$ix]
            } else {
                sel.idx = sel.idx[median.sorted.features$ix]
            }
        } else {
    # for Random Forest, caluclate relative median feature weights and sort
    # by auroc as effect measure
            weights <- t(t(weights) / colSums(abs(weights)))
            median.sorted.features <-
                sort(rowMedians(weights),
                    decreasing = FALSE,
                    index.return = TRUE)
    # take the feature with median higher than consens.threshold
            sel.idx <-
                median.sorted.features$ix[which(median.sorted.features$x >=
                        consens.thres)]
            
            if (length(sel.idx) > max.show) {
                sel.idx <- tail(sel.idx, n = max.show)
            }
        }
        
        if (verbose > 2)
            message(paste(
                "+++ generating plot for a model with",
                length(sel.idx),
                "selected features"
            ))
        if (verbose > 2)
            message("+ finished model.interpretation.select.features")
        return(sel.idx)
    }

# function to get weights matrix from the model list
#' @keywords internal
get.weights.matrix <- function(models.list, verbose = 0) {
    if (verbose > 2)
        message("+ get.weights.matrix")
    W.mat <- as.numeric(models.list[[1]]$feat.weights)
    for (i in 2:length(models.list)) {
        W.mat <- cbind(W.mat, as.numeric(models.list[[i]]$feat.weights))
    }
    rownames(W.mat) <- models.list[[1]]$features
    colnames(W.mat) <- paste("M", seq_len(ncol(W.mat)), sep = "_")
    if (verbose > 2)
        message("+ finished get.weights.matrix")
    return(W.mat)
}
