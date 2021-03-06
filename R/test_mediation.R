# --------------------------------------
# Author: Andreas Alfons
#         Erasmus Universiteit Rotterdam
# --------------------------------------

#' (Robust) mediation analysis
#'
#' Perform (robust) mediation analysis via a (fast and robust) bootstrap test
#' or Sobel's test.
#'
#' If \code{method} is \code{"regression"}, \code{robust} is \code{TRUE} and
#' \code{median} is \code{FALSE} (the defaults), the tests are based on robust
#' regressions with \code{\link[robustbase]{lmrob}}.  The bootstrap test is
#' thereby performed via the fast and robust bootstrap.
#'
#' Note that the regression estimator implemented in
#' \code{\link[robustbase]{lmrob}} can be seen as weighted least squares
#' estimator, where the weights are dependent on how much an observation is
#' deviating from the rest.  The trick for the fast and robust bootstrap is
#' that on each bootstrap sample, first a weighted least squares estimator
#' is computed (using those robustness weights from the original sample)
#' followed by a linear correction of the coefficients.  The purpose of this
#' correction is to account for the additional uncertainty of obtaining the
#' robustness weights.
#'
#' If \code{method} is \code{"regression"}, \code{robust} is \code{TRUE} and
#' \code{median} is \code{TRUE}, the tests are based on median regressions with
#' \code{\link[quantreg]{rq}} and the standard bootstrap ().  Unlike the robust
#' regressions described above, median regressions are not robust against
#' outliers in the explanatory variables, and the standard bootstrap can suffer
#' from oversampling of outliers in the bootstrap samples.
#'
#' If \code{method} is \code{"covariance"} and \code{robust} is \code{TRUE},
#' the tests are based on a Huber M-estimator of location and scatter.  For the
#' bootstrap test, the M-estimates are used to first clean the data via a
#' transformation.  Then the standard bootstrap is performed with the cleaned
#' data.  Note that this covariance-based approach is less robust than the
#' approach based on robust regressions described above.  Furthermore, the
#' bootstrap does not account for the variability from cleaning the data.
#'
#' \code{robmed} is a wrapper function for performing robust mediation analysis
#' via regressions and the fast and robust bootstrap.
#'
#' \code{indirect} is a wrapper function for performing non-robust mediation
#' analysis via regressions and the bootstrap (inspired by Preacher & Hayes'
#' \code{SPSS} macro \code{INDIRECT}).
#'
#' @aliases print.boot_test_mediation print.sobel_test_mediation
#'
#' @param data  a data frame containing the variables.  Alternatively, this can
#' be a mediation model fit as returned by \code{\link{fit_mediation}}.
#' @param x  a character string, an integer or a logical vector specifying the
#' column of \code{data} containing the independent variable.
#' @param y  a character string, an integer or a logical vector specifying the
#' column of \code{data} containing the dependent variable.
#' @param m  a character, integer or logical vector specifying the columns of
#' \code{data} containing the hypothesized mediator variables.
#' @param covariates  optional; a character, integer or logical vector
#' specifying the columns of \code{data} containing additional covariates to be
#' used as control variables.
#' @param test  a character string specifying the test to be performed for
#' the indirect effect.  Possible values are \code{"boot"} (the default) for
#' the bootstrap, or \code{"sobel"} for Sobel's test.  Currently, Sobel's test
#' is not implemented for more than one hypothesized mediator variable.
#' @param alternative  a character string specifying the alternative hypothesis
#' in the test for the indirect effects.  Possible values are \code{"twosided"}
#' (the default), \code{"less"} or \code{"greater"}.
#' @param R  an integer giving the number of bootstrap replicates.  The default
#' is to use 5000 bootstrap replicates.
#' @param level  numeric; the confidence level of the confidence interval in
#' the bootstrap test.  The default is to compute a 95\% confidence interval.
#' @param type  a character string specifying the type of confidence interval
#' to be computed in the bootstrap test.  Possible values are \code{"bca"} (the
#' default) for the bias-corrected and accelerated bootstrap, or \code{"perc"}
#' for the percentile bootstrap.
#' @param method  a character string specifying the method of estimation for
#' the mediation model.  Possible values are \code{"regression"} (the default)
#' to estimate the effects via regressions, or \code{"covariance"} to estimate
#' the effects via the covariance matrix.  Note that the effects are
#' always estimated via regressions if more than one hypothesized mediator is
#' supplied in \code{m}, or if control variables are specified via
#' \code{covariates}.
#' @param robust  a logical indicating whether to perform a robust test
#' (defaults to \code{TRUE}).
#' @param median  a logical indicating if the effects should be estimated via
#' median regression (defaults to \code{FALSE}).  This is ignored unless
#' \code{method} is \code{"regression"} and \code{robust} is \code{TRUE}.
#' @param control  a list of tuning parameters for the corresponding robust
#' method.  For robust regression (\code{method = "regression"},
#' \code{robust = TRUE} and \code{median = FALSE}), a list of tuning
#' parameters for \code{\link[robustbase]{lmrob}} as generated by
#' \code{\link{reg_control}}.  For Huberized covariance matrix estimation
#' (\code{method = "covariance"} and \code{robust = TRUE}), a list of tuning
#' parameters for \code{\link{cov_Huber}} as generated by
#' \code{\link{cov_control}}.  No tuning parameters are necessary for median
#' regression (\code{method = "regression"}, \code{robust = TRUE} and
#' \code{median = TRUE}).
#' @param \dots  additional arguments to be passed down.  For the bootstrap
#' tests, those can be used to specify arguments of \code{\link[boot]{boot}},
#' for example for parallel computing.
#'
#' @return An object inheriting from class \code{"test_mediation"} (class
#' \code{"boot_test_mediation"} if \code{test} is \code{"boot"} or
#' \code{"sobel_test_mediation"} if \code{test} is \code{"sobel"}) with the
#' following components:
#' \item{ab}{a numeric vector containing the point estimates of the indirect
#' effects.}
#' \item{ci}{a numeric vector of length two or a matrix of two columns
#' containing the bootstrap confidence intervals for the indirect effects
#' (only \code{"boot_test_mediation"}).}
#' \item{reps}{an object of class \code{"\link[boot]{boot}"} containing
#' the bootstrap replicates of the effects (only \code{"boot_test_mediation"}).}
#' \item{se}{numeric; the standard error of the indirect effect according
#' to Sobel's formula (only \code{"sobel_test_mediation"}).}
#' \item{statistic}{numeric; the test statistic for Sobel's test (only
#' \code{"sobel_test_mediation"}).}
#' \item{p_value}{numeric; the p-value from Sobel's test (only
#' \code{"sobel_test_mediation"}).}
#' \item{alternative}{a character string specifying the alternative
#' hypothesis in the test for the indirect effects.}
#' \item{R}{an integer giving the number of bootstrap replicates (only
#' \code{"boot_test_mediation"}).}
#' \item{level}{numeric; the confidence level of the bootstrap confidence
#' interval (only \code{"boot_test_mediation"}).}
#' \item{type}{a character string specifying the type of bootstrap
#' confidence interval (only \code{"boot_test_mediation"}).}
#' \item{fit}{an object inheriting from class
#' \code{"\link{fit_mediation}"} containing the estimation results for the
#' direct effect and the total effect in the mediation model.}
#'
#' @note For the fast and robust bootstrap, the simpler correction of
#' Salibian-Barrera & Van Aelst (2008) is used rather than the originally
#' proposed correction of Salibian-Barrera & Zamar (2002).
#'
#' @author Andreas Alfons
#'
#' @references
#' Alfons, A., Ates, N.Y. and Groenen, P.J.F. (2018) A robust bootstrap test
#' for mediation analysis.  \emph{ERIM Report Series in Management}, Erasmus
#' Research Institute of Management.  URL
#' \url{https://hdl.handle.net/1765/109594}.
#'
#' Preacher, K.J. and Hayes, A.F. (2004) SPSS and SAS procedures for estimating
#' indirect effects in simple mediation models. \emph{Behavior Research Methods,
#' Instruments, & Computers}, \bold{36}(4), 717--731.
#'
#' Preacher, K.J. and Hayes, A.F. (2008) Asymptotic and resampling strategies
#' for assessing and comparing indirect effects in multiple mediator models.
#' \emph{Behavior Research Methods}, \bold{40}(3), 879--891.
#'
#' Salibian-Barrera, M. and Van Aelst, S. (2008) Robust model selection using
#' fast and robust bootstrap. \emph{Computational Statistics & Data Analysis},
#' \bold{52}(12), 5121--5135
#'
#' Salibian-Barrera, M. and Zamar, R. (2002) Bootstrapping robust estimates of
#' regression. \emph{The Annals of Statistics}, \bold{30}(2), 556--582.
#'
#' Sobel, M.E. (1982) Asymptotic confidence intervals for indirect effects in
#' structural equation models. \emph{Sociological Methodology}, \bold{13},
#' 290--312.
#'
#' Yuan, Y. and MacKinnon, D.P. (2014) Robust mediation analysis based on
#' median regression. \emph{Psychological Methods}, \bold{19}(1),
#' 1--20.
#'
#' Zu, J. and Yuan, K.-H. (2010) Local influence and robust procedures for
#' mediation analysis. \emph{Multivariate Behavioral Research}, \bold{45}(1),
#' 1--44.
#'
#' @seealso \code{\link{fit_mediation}}
#'
#' \code{\link[=coef.test_mediation]{coef}},
#' \code{\link[=confint.test_mediation]{confint}},
#' \code{\link[=fortify.test_mediation]{fortify}} and
#' \code{\link[=plot_mediation]{plot}} methods, \code{\link{p_value}}
#'
#' \code{\link[boot]{boot}}, \code{\link[robustbase]{lmrob}},
#' \code{\link[stats]{lm}}, \code{\link{cov_Huber}}, \code{\link{cov_ML}}
#'
#' @examples
#' data("BSG2014")
#' test <- test_mediation(BSG2014,
#'                        x = "ValueDiversity",
#'                        y = "TeamCommitment",
#'                        m = "TaskConflict")
#' summary(test)
#'
#' @keywords multivariate
#'
#' @import boot
#' @import robustbase
#' @importFrom quantreg rq.fit
#' @export

test_mediation <- function(data, ...) UseMethod("test_mediation")


#' @rdname test_mediation
#' @method test_mediation default
#' @export

test_mediation.default <- function(data, x, y, m, covariates = NULL,
                                   test = c("boot", "sobel"),
                                   alternative = c("twosided", "less", "greater"),
                                   R = 5000, level = 0.95,
                                   type = c("bca", "perc"),
                                   method = c("regression", "covariance"),
                                   robust = TRUE, median = FALSE, control,
                                   ...) {
  ## fit mediation model
  fit <- fit_mediation(data, x = x, y = y, m = m, covariates = covariates,
                       method = method, robust = robust, median = median,
                       control = control)
  ## call method for fitted model
  test_mediation(fit, test = test, alternative = alternative,
                 R = R, level = level, type = type, ...)
}


#' @rdname test_mediation
#' @method test_mediation fit_mediation
#' @export

test_mediation.fit_mediation <- function(data, test = c("boot", "sobel"),
                                         alternative = c("twosided", "less", "greater"),
                                         R = 5000, level = 0.95,
                                         type = c("bca", "perc"),
                                         ...) {
  ## initializations
  test <- match.arg(test)
  alternative <- match.arg(alternative)
  p_m <- length(data$m)
  if (p_m > 1L && test == "sobel") {
    test <- "boot"
    warning("Sobel test not available with multiple mediators; ",
            "using bootstrap test")
  }
  ## perform mediation analysis
  if (test == "boot") {
    # further inizializations
    level <- rep(as.numeric(level), length.out = 1)
    if (is.na(level) || level < 0 || level > 1) level <- formals()$level
    type <- match.arg(type)
    # perform bootstrap test
    boot_test_mediation(data, alternative = alternative, R = R,
                        level = level, type = type, ...)
  } else if (test == "sobel") {
    # perform Sobel test
    sobel_test_mediation(data, alternative = alternative)
  } else stop("test not implemented")
}


#' @rdname test_mediation
#' @export

robmed <- function(..., test = "boot", method = "regression",
                   robust = TRUE, median = FALSE) {
  test_mediation(..., test = "boot", method = "regression",
                 robust = TRUE, median = FALSE)
}


#' @rdname test_mediation
#' @export

indirect <- function(..., test = "boot", method = "regression",
                     robust = FALSE, median = FALSE) {
  test_mediation(..., test = "boot", method = "regression",
                 robust = FALSE, median = FALSE)
}


## internal function for bootstrap test
boot_test_mediation <- function(fit,
                                alternative = c("twosided", "less", "greater"),
                                R = 5000, level = 0.95, type = c("bca", "perc"),
                                ...) {
  p_m <- length(fit$m)  # number of mediators
  if (inherits(fit, "reg_fit_mediation")) {
    # indices of mediators in data matrix to be used in bootstrap
    j_m <- match(fit$m, names(fit$data)) + 1L
    # indices of covariates in data matrix to be used in bootstrap
    j_covariates <- match(fit$covariates, names(fit$data)) + 1L
    # combine data
    n <- nrow(fit$data)
    z <- cbind(rep.int(1, n), as.matrix(fit$data))
    # check if fast and robust bootstrap should be applied
    if(fit$robust) {

      # the fast and robust bootstrap does not work for median regression

      if (fit$median) {

        # define function for standard bootstrap for median regression
        if (p_m == 1L)  {
          # only one mediator
          median_bootstrap <- function(z, i) {
            # extract bootstrap sample from the data
            z_i <- z[i, , drop = FALSE]
            # compute coefficients from regression m ~ x + covariates
            x_i <- z_i[, c(1L, 2L, j_covariates)]
            m_i <- z_i[, 4L]
            coef_m_i <- rq.fit(x_i, m_i, tau = 0.5)$coefficients
            # compute coefficients from regression y ~ m + x + covariates
            mx_i <- z_i[, c(1L, 4L, 2L, j_covariates)]
            y_i <- z_i[, 3L]
            coef_y_i <- rq.fit(mx_i, y_i, tau = 0.5)$coefficients
            # compute effects
            a <- unname(coef_m_i[2L])
            b <- unname(coef_y_i[2L])
            c <- unname(coef_y_i[3L])
            ab <- a * b
            c_prime <- ab + c
            # compute effects of control variables if they exist
            covariates <- unname(coef_y_i[-seq_len(3L)])
            # return effects
            c(ab, a, b, c, c_prime, covariates)
          }
        } else{
          # multiple mediators
          median_bootstrap <- function(z, i) {
            # extract bootstrap sample from the data
            z_i <- z[i, , drop = FALSE]
            # compute coefficients from regressions m ~ x + covariates
            x_i <- z_i[, c(1L, 2L, j_covariates)]
            m_i <- z_i[, j_m]
            coef_m_i <- sapply(j_m, function(j) {
              m_i <- z_i[, j]
              coef_m_i <- rq.fit(x_i, m_i, tau = 0.5)$coefficients
            })
            # compute coefficients from regression y ~ m + x + covariates
            mx_i <- z_i[, c(1L, j_m, 2L, j_covariates)]
            y_i <- z_i[, 3L]
            coef_y_i <- rq.fit(mx_i, y_i, tau = 0.5)$coefficients
            # compute effects
            a <- unname(coef_m_i[2L, ])
            b <- unname(coef_y_i[1L + seq_len(p_m)])
            c <- unname(coef_y_i[2L + p_m])
            ab <- a * b
            sum_ab <- sum(ab)
            c_prime <- sum_ab + c
            # compute effects of control variables if they exist
            covariates <- unname(coef_y_i[-seq_len(2L + p_m)])
            # return effects
            c(sum_ab, ab, a, b, c, c_prime, covariates)
          }
        }
        # perform standard bootstrap
        bootstrap <- local_boot(z, median_bootstrap, R = R, ...)
        R <- nrow(bootstrap$t)  # make sure that number of replicates is correct

      } else {

        # This implementation uses the simpler approximation of
        # Salibian-Barrera & Van Aelst (2008) rather than that of
        # Salibian-Barrera & Zamar (2002).  The difference is that
        # the latter also requires a correction of the residual scale.

        # extract regression models
        fit_mx <- fit$fit_mx
        fit_ymx <- fit$fit_ymx
        # extract control object from robust regressions
        # (necessary to compute correction matrices)
        psi_control <- get_psi_control(fit_ymx)  # the same for all model fits
        if (p_m == 1L) {
          # only one mediator
          # extract (square root of) robustness weights and combine data
          w_m <- sqrt(weights(fit_mx, type = "robustness"))
          w_y <- sqrt(weights(fit_ymx, type = "robustness"))
          # compute matrices for linear corrections
          corr_m <- correction_matrix(z[, c(1L, 2L, j_covariates)],
                                      weights = w_m,
                                      residuals = residuals(fit_mx),
                                      scale = fit_mx$scale,
                                      control = psi_control)
          coef_m <- coef(fit_mx)
          corr_y <- correction_matrix(z[, c(1L, 4L, 2L, j_covariates)],
                                      weights = w_y,
                                      residuals = residuals(fit_ymx),
                                      scale = fit_ymx$scale,
                                      control = psi_control)
          coef_y <- coef(fit_ymx)
          # perform fast and robust bootstrap
          robust_bootstrap <- function(z, i, w_m, corr_m, coef_m,
                                       w_y, corr_y, coef_y) {
            # extract bootstrap sample from the data
            z_i <- z[i, , drop = FALSE]
            w_m_i <- w_m[i]
            w_y_i <- w_y[i]
            # check whether there are enough observations with nonzero weights
            if(sum(w_m_i > 0) <= 2 || sum(w_y_i > 0) <= 3) return(NA)
            # compute coefficients from weighted regression m ~ x + covariates
            weighted_x_i <- w_m_i * z_i[, c(1L, 2L, j_covariates)]
            weighted_m_i <- w_m_i * z_i[, 4L]
            coef_m_i <- solve(crossprod(weighted_x_i)) %*%
              crossprod(weighted_x_i, weighted_m_i)
            # compute coefficients from weighted regression y ~ m + x + covariates
            weighted_mx_i <- w_y_i * z_i[, c(1L, 4L, 2L, j_covariates)]
            weighted_y_i <- w_y_i * z_i[, 3L]
            coef_y_i <- solve(crossprod(weighted_mx_i)) %*%
              crossprod(weighted_mx_i, weighted_y_i)
            # compute corrected coefficients
            coef_m_i <- drop(coef_m + corr_m %*% (coef_m_i - coef_m))
            coef_y_i <- drop(coef_y + corr_y %*% (coef_y_i - coef_y))
            # compute effects
            a <- unname(coef_m_i[2L])
            b <- unname(coef_y_i[2L])
            c <- unname(coef_y_i[3L])
            ab <- a * b
            c_prime <- ab + c
            # compute effects of control variables if they exist
            covariates <- unname(coef_y_i[-(1L:3L)])
            # return effects
            c(ab, a, b, c, c_prime, covariates)
          }
        } else {
          # multiple mediators
          # extract (square root of) robustness weights and combine data
          w_m <- sqrt(sapply(fit_mx, weights, type = "robustness"))
          w_y <- sqrt(weights(fit_ymx, type = "robustness"))
          z <- cbind(rep.int(1, n), as.matrix(fit$data))
          # compute matrices for linear corrections
          corr_m <- lapply(fit$m, function(m, z) {
            correction_matrix(z, weights = w_m[, m],
                              residuals = residuals(fit_mx[[m]]),
                              scale = fit_mx[[m]]$scale,
                              control = psi_control)
          }, z = z[, c(1L, 2L, j_covariates)])
          coef_m <- lapply(fit_mx, coef)
          corr_y <- correction_matrix(z[, c(1L, j_m, 2L, j_covariates)],
                                      weights = w_y,
                                      residuals = residuals(fit_ymx),
                                      scale = fit_ymx$scale,
                                      control = psi_control)
          coef_y <- coef(fit_ymx)
          # perform fast and robust bootstrap
          robust_bootstrap <- function(z, i, w_m, corr_m, coef_m,
                                       w_y, corr_y, coef_y) {
            # extract bootstrap sample from the data
            z_i <- z[i, , drop = FALSE]
            w_m_i <- w_m[i, , drop = FALSE]
            w_y_i <- w_y[i]
            # check whether there are enough observations with nonzero weights
            if(any(colSums(w_m_i > 0) <= 2) || sum(w_y_i > 0) <= 3) return(NA)
            # compute coefficients from weighted regression m ~ x + covariates
            coef_m_i <- lapply(fit$m, function(m, x_i) {
              w_i <- w_m_i[, m]
              weighted_x_i <- w_i * x_i
              weighted_m_i <- w_i * z_i[, m]
              coef_m_i <- solve(crossprod(weighted_x_i)) %*%
                crossprod(weighted_x_i, weighted_m_i)
            }, x_i = z_i[, c(1L, 2L, j_covariates)])
            # compute coefficients from weighted regression y ~ m + x + covariates
            weighted_mx_i <- w_y_i * z_i[, c(1L, j_m, 2L, j_covariates)]
            weighted_y_i <- w_y_i * z_i[, 3L]
            coef_y_i <- solve(crossprod(weighted_mx_i)) %*%
              crossprod(weighted_mx_i, weighted_y_i)
            # compute corrected coefficients
            coef_m_i <- mapply(function(coef_m, coef_m_i, corr_m) {
              drop(coef_m + corr_m %*% (coef_m_i - coef_m))
            }, coef_m = coef_m, coef_m_i = coef_m_i, corr_m = corr_m)
            coef_y_i <- drop(coef_y + corr_y %*% (coef_y_i - coef_y))
            # compute effects
            a <- unname(coef_m_i[2L, ])
            b <- unname(coef_y_i[1L + seq_len(p_m)])
            c <- unname(coef_y_i[2L + p_m])
            ab <- a * b
            sum_ab <- sum(ab)
            c_prime <- sum_ab + c
            # compute effects of control variables if they exist
            covariates <- unname(coef_y_i[-seq_len(2L + p_m)])
            # return effects
            c(sum_ab, ab, a, b, c, c_prime, covariates)
          }
        }
        # perform fast and robust bootstrap
        bootstrap <- local_boot(z, robust_bootstrap, R = R, w_m = w_m,
                                corr_m = corr_m, coef_m = coef_m, w_y = w_y,
                                corr_y = corr_y, coef_y = coef_y, ...)
        R <- colSums(!is.na(bootstrap$t))  # adjust number of replicates for NAs

      }

    } else {

      # define function for standard bootstrap mediation test
      if (p_m == 1L)  {
        # only one mediator
        standard_bootstrap <- function(z, i) {
          # extract bootstrap sample from the data
          z_i <- z[i, , drop = FALSE]
          # compute coefficients from regression m ~ x + covariates
          x_i <- z_i[, c(1L, 2L, j_covariates)]
          m_i <- z_i[, 4L]
          coef_m_i <- drop(solve(crossprod(x_i)) %*% crossprod(x_i, m_i))
          # compute coefficients from regression y ~ m + x + covariates
          mx_i <- z_i[, c(1L, 4L, 2L, j_covariates)]
          y_i <- z_i[, 3L]
          coef_y_i <- drop(solve(crossprod(mx_i)) %*% crossprod(mx_i, y_i))
          # compute effects
          a <- unname(coef_m_i[2L])
          b <- unname(coef_y_i[2L])
          c <- unname(coef_y_i[3L])
          ab <- a * b
          c_prime <- ab + c
          # compute effects of control variables if they exist
          covariates <- unname(coef_y_i[-seq_len(3L)])
          # return effects
          c(ab, a, b, c, c_prime, covariates)
        }
      } else{
        # multiple mediators
        standard_bootstrap <- function(z, i) {
          # extract bootstrap sample from the data
          z_i <- z[i, , drop = FALSE]
          # compute coefficients from regressions m ~ x + covariates
          x_i <- z_i[, c(1L, 2L, j_covariates)]
          m_i <- z_i[, j_m]
          # coef_m_i <- sapply(j_m, function(j) {
          #   m_i <- z_i[, j]
          #   coef_m_i <- drop(solve(crossprod(x_i)) %*% crossprod(x_i, m_i))
          # })
          coef_m_i <- drop(solve(crossprod(x_i)) %*% crossprod(x_i, m_i))
          # compute coefficients from regression y ~ m + x + covariates
          mx_i <- z_i[, c(1L, j_m, 2L, j_covariates)]
          y_i <- z_i[, 3L]
          coef_y_i <- drop(solve(crossprod(mx_i)) %*% crossprod(mx_i, y_i))
          # compute effects
          a <- unname(coef_m_i[2L, ])
          b <- unname(coef_y_i[1L + seq_len(p_m)])
          c <- unname(coef_y_i[2L + p_m])
          ab <- a * b
          sum_ab <- sum(ab)
          c_prime <- sum_ab + c
          # compute effects of control variables if they exist
          covariates <- unname(coef_y_i[-seq_len(2L + p_m)])
          # return effects
          c(sum_ab, ab, a, b, c, c_prime, covariates)
        }
      }
      # perform standard bootstrap
      bootstrap <- local_boot(z, standard_bootstrap, R = R, ...)
      R <- nrow(bootstrap$t)  # make sure that number of replicates is correct
    }

  } else if(inherits(fit, "cov_fit_mediation")) {
    # extract data and variable names
    x <- fit$x
    y <- fit$y
    m <- fit$m
    data <- fit$data
    # check if the robust transformation of Zu & Yuan (2010) should be applied
    if(fit$robust) {
      cov <- fit$cov
      data[] <- mapply("-", data, cov$center, SIMPLIFY=FALSE, USE.NAMES=FALSE)
      data <- weights(cov, type="consistent") * data
    }
    # perform bootstrap
    bootstrap <- local_boot(data, function(z, i) {
      # extract bootstrap sample from the data
      z_i <- z[i, , drop=FALSE]
      # compute MLE of covariance matrix on bootstrap sample
      S <- cov_ML(z_i)$cov
      # compute effects
      a <- S[m, x] / S[x, x]
      det <- S[x, x] * S[m, m] - S[m, x]^2
      b <- (-S[m, x] * S[y, x] + S[x, x] * S[y, m]) / det
      c <- (S[m, m] * S[y, x] - S[m, x] * S[y, m]) / det
      c_prime <- S[y, x] / S[x, x]
      c(a*b, a, b, c, c_prime)
    }, R=R, ...)
    R <- nrow(bootstrap$t)  # make sure that number of replicates is correct
  } else stop("method not implemented")
  # extract indirect effect and confidence interval
  if(p_m == 1L) {
    # only one mediator
    ab <- mean(bootstrap$t[, 1L], na.rm = TRUE)
    ci <- confint(bootstrap, parm = 1L, level = level,
                  alternative = alternative, type = type)
  } else {
    # multiple mediators
    ab <- colMeans(bootstrap$t[, seq_len(1L + p_m)], na.rm = TRUE)
    ci <- lapply(seq_len(1L + p_m), function(j) {
      confint(bootstrap, parm = j, level = level,
              alternative = alternative, type = type)
    })
    ci <- do.call(rbind, ci)
    names(ab) <- rownames(ci) <- c("Total", fit$m)
  }
  # construct return object
  result <- list(ab = ab, ci = ci, reps = bootstrap, alternative = alternative,
                 R = as.integer(R[1L]), level = level, type = type, fit = fit)
  class(result) <- c("boot_test_mediation", "test_mediation")
  result
}

## internal function for sobel test
sobel_test_mediation <- function(fit,
                                 alternative = c("twosided", "less", "greater"),
                                 ...) {
  # extract coefficients
  a <- fit$a
  b <- fit$b
  # compute standard errors
  summary <- get_summary(fit)
  sa <- summary$a[, 2L]
  sb <- summary$b[, 2L]
  # compute test statistic and p-Value
  ab <- a * b
  se <- sqrt(b^2 * sa^2 + a^2 * sb^2)
  z <- ab / se
  p_value <- p_value_z(z, alternative = alternative)
  # construct return item
  result <- list(ab = ab, se = se, statistic = z, p_value = p_value,
                 alternative = alternative, fit = fit)
  class(result) <- c("sobel_test_mediation", "test_mediation")
  result
}

## wrapper function for boot() that ignores unused arguments, but allows
## arguments for parallel computing to be passed down
local_boot <- function(..., sim, stype, L, m, ran.gen, mle) boot(...)

## get control arguments for psi function as used in a given model fit
get_psi_control <- function(object) object$control[c("tuning.psi", "psi")]

## compute matrix for linear correction
# (see Salibian-Barrera & Van Aelst, 2008)
# The definition of the weigths in Salibian-Barrera & Van Aelst (2008) does not
# include the residual scale, whereas the robustness weights in lmrob() do.
# Hence the residual scale shows up in Equation (16) of Salibian-Barrera & Van
# Aelst (2008), but here the residual scale is already included in the weights.
correction_matrix <- function(X, weights, residuals, scale, control) {
  tmp <- Mpsi(residuals/scale, cc=control$tuning.psi, psi=control$psi, deriv=1)
  solve(crossprod(X, tmp * X)) %*% crossprod(weights * X)
}

## internal function to compute p-value based on normal distribution
p_value_z <- function(z, alternative = c("twosided", "less", "greater")) {
  # initializations
  alternative <- match.arg(alternative)
  # compute p-value
  switch(alternative, twosided = 2 * pnorm(abs(z), lower.tail = FALSE),
         less = pnorm(z), greater = pnorm(z, lower.tail = FALSE))
}
