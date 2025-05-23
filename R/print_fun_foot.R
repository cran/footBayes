#' Print Method for stanFoot Objects
#'
#' Provides detailed posterior summaries for the Stan football model parameters.
#'
#' @param x An object of class \code{stanFoot}.
#' @param pars Optional character vector specifying parameters to include in the summary. This can be specific parameter names (e.g., \code{"att"}, \code{"def"}, \code{"att_raw"}, \code{"def_raw"}, \code{"home"}, \code{"sigma_att"}, \code{"sigma_def"}, \code{"rho"}, and \code{"beta"}). If \code{NULL}, all parameters are included.
#' @param teams Optional character vector specifying team names whose \code{"att"}, \code{"def"}, \code{"att_raw"}, \code{"def_raw"} parameters should be displayed.
#' @param digits Number of digits to use when printing numeric values. Default is \code{3}.
#' @param true_names Logical value indicating whether to display team names in parameter summaries. Default is \code{TRUE}.
#' @param ... Additional arguments passed.
#' @method print stanFoot
#'
#' @importFrom stats setNames
#' @importFrom dplyr across
#' @importFrom dplyr where
#'
#' @author Roberto Macrì Demartino \email{roberto.macridemartino@deams.units.it}
#'
#' @export
print.stanFoot <- function(x, pars = NULL, teams = NULL, digits = 3, true_names = TRUE, ...) {
  # if (!inherits(x, "stanFoot")) {
  #   stop("The object must be of class 'stanFoot'.")
  # }

  if (!is.numeric(digits) || digits <= 0) {
    stop("'digits' must be a positive numeric value.")
  }

  cat("Summary of Stan football model\n")
  cat("------------------------------\n\n")


  if (!inherits(x$fit, "CmdStanFit")) {
    stop("The 'fit' component must be a 'CmdStanFit' object.")
  }

  # Extract all parameter names from the 'CmdStanFit' object
  all_param_names <- x$fit$metadata()$stan_variables

  # Initialize 'final_pars' based on 'pars' argument
  if (!is.null(pars)) {
    matched_pars_list <- lapply(pars, function(p) {
      matched <- grep(paste0("^", p, "(\\[|$)"), all_param_names, value = TRUE)
      if (length(matched) == 0) {
        warning(sprintf("No parameters found for group '%s'.", p))
      }
      matched
    })
    final_pars <- unique(unlist(matched_pars_list))

    # Check for non-empty 'final_pars'
    if (length(final_pars) == 0) {
      stop("No valid parameters specified in 'pars'.")
    }
  } else {
    final_pars <- NULL
  }

  # Extract unique team names from data
  teams_all <- unique(c(as.character(x$data$home_team), as.character(x$data$away_team)))

  # If 'teams' is specified, validate and filter them
  if (!is.null(teams)) {
    invalid_teams <- setdiff(teams, teams_all)
    if (length(invalid_teams) > 0) {
      teams <- setdiff(teams, invalid_teams)
      if (length(teams) == 0) {
        stop("No valid teams specified in 'teams'.")
      } else {
        warning("The following teams are not in the data: ", paste(invalid_teams, collapse = ", "))
      }
    }
    # Create a mapping from team names to indices
    team_map <- setNames(seq_along(teams_all), teams_all)
  }

  # Parameters to exclude from name replacement
  exclude_params <- all_param_names[!all_param_names %in% c("att_raw", "def_raw", "att", "def")]

  # Extract posterior summaries
  cat("Posterior summaries for model parameters:\n")

  if (is.null(final_pars)) {
    stan_summary <- x$fit$summary()
  } else {
    stan_summary <- x$fit$summary(variables = unique(final_pars))
  }

  is_dynamic <- x$stan_data$ntimes > 1

  # If 'teams' is specified, filter parameters related to these teams
  if (!is.null(teams)) {
    if (is_dynamic) {
      # Dynamic model
      patterns_team <- unlist(lapply(teams, function(team) {
        idx <- team_map[[team]]
        c(
          paste0("^att_raw\\[\\d+,", idx, "\\]$"),
          paste0("^def_raw\\[\\d+,", idx, "\\]$"),
          paste0("^att\\[\\d+,", idx, "\\]$"),
          paste0("^def\\[\\d+,", idx, "\\]$")
        )
      }))
    } else {
      # Static model
      patterns_team <- unlist(lapply(teams, function(team) {
        idx <- team_map[[team]]
        c(
          paste0("^att_raw\\[", idx, "\\]$"),
          paste0("^def_raw\\[", idx, "\\]$"),
          paste0("^att\\[", idx, "\\]$"),
          paste0("^def\\[", idx, "\\]$")
        )
      }))
    }

    # Define patterns for global parameters
    patterns_global <- "^(home|rho|sigma_att|sigma_def|theta|y_rep|log_lik|gamma|beta|diff_y_rep|lp__|lp_approx__)$"

    # Combine all patterns into a single string
    combined_patterns <- paste(c(patterns_team, patterns_global), collapse = "|")

    # Filter 'stan_summary' to include both team-specific and global parameters
    stan_summary <- stan_summary[grep(combined_patterns, as.factor(stan_summary$variable)), , drop = FALSE]
  }

  # Replace parameter names with team names if 'true_names' is TRUE
  if (true_names && !is.null(stan_summary) && nrow(stan_summary) > 0) {
    # Create reverse mapping from index to team names
    team_map_rev <- setNames(teams_all, as.character(seq_along(teams_all)))

    # Apply the corrected 'team_names_2' function
    stan_summary_names <- team_names(stan_summary$variable, exclude_params, team_map_rev)

    if (!is_dynamic) {
      # Remove trailing commas before the closing bracket
      stan_summary_names <- gsub(",\\]", "]", stan_summary_names)
    }

    # Assign the cleaned names back to the summary
    stan_summary$variable <- stan_summary_names
  }

  # Check if there are parameters to display
  if (!is.null(stan_summary) && nrow(stan_summary) > 0) {
    # Round the summary to the specified number of digits and print
    print(stan_summary %>%
      mutate(across(where(is.numeric), ~ round(., digits))))
  } else {
    cat("No parameters to display.\n")
  }

  invisible(x)
}



#' Print Method for btdFoot Objects
#'
#' Provides detailed posterior summaries for the Bayesian Bradley-Terry-Davidson model parameters.
#'
#' @param x An object of class \code{btdFoot}.
#' @param pars Optional character vector specifying parameters to include in the summary (e.g., \code{"logStrength"}, \code{"logTie"}, \code{"home"}, \code{"log_lik"}, and \code{"y_rep"}).
#' @param teams Optional character vector specifying team names whose \code{logStrength} parameters should be displayed.
#' @param digits Number of digits to use when printing numeric values. Default is \code{3}.
#' @param true_names Logical value indicating whether to display team names in parameter summaries. Default is \code{TRUE}.
#' @param display Character string specifying which parts of the output to display. Options are \code{"both"}, \code{"rankings"}, or \code{"parameters"}. Default is \code{"both"}.
#' @param ... Additional arguments passed.
#' @method print btdFoot
#'
#' @importFrom stats setNames
#' @importFrom dplyr across
#' @importFrom dplyr where
#'
#' @author Roberto Macrì Demartino \email{roberto.macridemartino@deams.units.it}
#'
#' @export

print.btdFoot <- function(x, pars = NULL, teams = NULL, digits = 3, true_names = TRUE,
                          display = "both", ...) {
  # if (!inherits(x, "btdFoot")) {
  #   stop("The object must be of class 'btdFoot'.")
  # }

  if (!is.numeric(digits) || digits <= 0) {
    stop("'digits' must be a positive numeric value.")
  }

  display <- match.arg(display, c("both", "rankings", "parameters"))

  cat("Bayesian Bradley-Terry-Davidson model\n")
  cat("------------------------------------------------\n")
  cat("Rank measure used:", x$rank_measure, "\n\n")

  if (display %in% c("both", "rankings")) {
    # Display the ranking table
    cat("Top teams based on relative log-strengths:\n")
    top_teams <- x$rank[order(-x$rank$log_strengths), ]
    print(utils::head(top_teams, 10), digits = digits)
    cat("\n")
  }

  if (display %in% c("both", "parameters")) {
    if (!inherits(x$fit, "CmdStanFit")) {
      stop("The 'fit' component must be a 'CmdStanFit' object.")
    }

    # Extract all parameter names from the 'CmdStanFit' object
    all_param_names <- x$fit$metadata()$stan_variables

    # Initialize 'final_pars' based on 'pars' argument
    if (!is.null(pars)) {
      matched_pars_list <- lapply(pars, function(p) {
        matched <- grep(paste0("^", p, "(\\[|$)"), all_param_names, value = TRUE)
        if (length(matched) == 0) {
          warning(sprintf("No parameters found for group '%s'.", p))
        }
        matched
      })
      final_pars <- unique(unlist(matched_pars_list))

      # Check for non-empty 'final_pars'
      if (length(final_pars) == 0) {
        stop("No valid parameters specified in 'pars'.")
      }
    } else {
      final_pars <- NULL
    }

    # Extract unique team names from data
    teams_all <- unique(c(as.character(x$data$home_team), as.character(x$data$away_team)))

    # If 'teams' is specified, validate and filter them
    if (!is.null(teams)) {
      invalid_teams <- setdiff(teams, teams_all)
      if (length(invalid_teams) > 0) {
        teams <- setdiff(teams, invalid_teams)
        if (length(teams) == 0) {
          stop("No valid teams specified in 'teams'.")
        } else {
          warning("The following teams are not in the data: ", paste(invalid_teams, collapse = ", "))
        }
      }

      team_map <- setNames(seq_along(teams_all), teams_all)
    }

    team_map_rev <- setNames(teams_all, as.character(seq_along(teams_all)))

    # Parameters to exclude from name replacement
    exclude_params <- c("log_lik", "y_rep")

    # Extract posterior summaries
    cat("Posterior summaries for model parameters:\n")
    if (is.null(final_pars)) {
      stan_summary <- x$fit$summary()
    } else {
      stan_summary <- x$fit$summary(variables = unique(final_pars))
    }

    param_names <- as.factor(stan_summary$variable)
    logStrength_pattern <- "^logStrength"

    is_logStrength <- grepl(logStrength_pattern, param_names)
    logStrength_params <- stan_summary[is_logStrength, , drop = FALSE]
    other_params <- stan_summary[!is_logStrength, , drop = FALSE]

    # Determine if the model is dynamic or static
    is_dynamic <- !is.null(x$stan_data$ntimes_rank)

    # Filter logStrength_params by 'teams' if provided
    if (!is.null(teams) && nrow(logStrength_params) > 0) {
      if (length(teams) > 0) {
        # Map team names to indices
        team_indices <- team_map[teams]
        # Create patterns to match logStrength parameters for the specified teams
        if (is_dynamic) {
          # Dynamic model
          patterns <- paste0("logStrength\\[\\d+,", team_indices, "\\]")
        } else {
          # Static model
          patterns <- paste0("logStrength\\[", team_indices, "\\]")
        }

        # Combine patterns
        pattern <- paste0("^", patterns, "$", collapse = "|")

        # Filter logStrength_params
        logStrength_param_names <- logStrength_params$variable
        logStrength_params <- logStrength_params[grep(pattern, logStrength_param_names), , drop = FALSE]
      } else {
        logStrength_params <- NULL
      }
    }

    # Combine logStrength_params and other_params back
    if (!is.null(logStrength_params) && !is.null(other_params)) {
      stan_summary <- rbind(logStrength_params, other_params)
    } else if (!is.null(logStrength_params)) {
      stan_summary <- logStrength_params
    } else if (!is.null(other_params)) {
      stan_summary <- other_params
    } else {
      stan_summary <- NULL
    }

    # Replace parameter names with team names if true_names is TRUE
    if (true_names && !is.null(stan_summary) && nrow(stan_summary) > 0) {
      stan_summary_names <- team_names(stan_summary$variable, exclude_params, team_map_rev)

      # Remove trailing commas in static model parameter names
      if (!is_dynamic) {
        stan_summary_names <- gsub(",\\]", "]", stan_summary_names)
      }
      stan_summary$variable <- stan_summary_names
    }

    if (!is.null(stan_summary) && nrow(stan_summary) > 0) {
      print(stan_summary %>%
        mutate(across(where(is.numeric), ~ round(., digits))))
    } else {
      cat("No parameters to display.\n")
    }
  }

  invisible(x)
}





#' Print method for compareFoot objects
#'
#' Provides a formatted output when printing objects of class \code{compareFoot}, displaying the predictive performance metrics and, if available, the confusion matrices for each model or probability matrix.
#'
#' @param x An object of class \code{compareFoot} returned by \code{\link{compare_foot}}.
#' @param digits  Number of digits to use when printing numeric values for the metrics. Default is \code{3}.
#' @param ... Additional arguments passed to \code{print}.
#' @method print compareFoot
#'
#' @author Roberto Macrì Demartino \email{roberto.macridemartino@deams.units.it}
#'
#' @export
#'
print.compareFoot <- function(x, digits = 3, ...) {
  cat("Predictive Performance Metrics\n")

  # Format the metrics data frame based on the specified number of digits
  formatted_metrics <- x$metrics
  metric_cols <- setdiff(names(formatted_metrics), "Model")

  # Apply rounding to the specified number of digits
  formatted_metrics[metric_cols] <- lapply(formatted_metrics[metric_cols], function(col) {
    if (is.numeric(col)) {
      format(round(col, digits), nsmall = digits)
    } else {
      col
    }
  })

  print(formatted_metrics, row.names = FALSE, ...)

  if (!is.null(x$confusion_matrix)) {
    cat("\nConfusion Matrices\n")
    for (model_name in names(x$confusion_matrix)) {
      cat("Model:", model_name, "\n\n")
      print(x$confusion_matrix[[model_name]], ...)
      cat("\n")
    }
  }
}
