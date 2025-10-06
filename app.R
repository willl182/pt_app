# ===================================================================
# Shiny App for PT Data Analysis (Homogeneity and Stability)
#
# This app implements the procedures from test_homog.R and pt_analysis.R
# in an interactive web interface using Shiny.
#
# Based on the design from ui_test.md.
# ===================================================================

# 1. Load necessary libraries
library(shiny)
library(tidyverse)
library(vroom)
library(DT)
library(rmarkdown) # Library for report generation

# ===================================================================
# I. User Interface (UI)
# ===================================================================
ui <- fluidPage(

  # 1. Application Title
  titlePanel("Evaluación de Homogeneidad y Estabilidad para Ítems de EP"),

  # 2. Main Layout: Sidebar
  sidebarLayout(

    # 2.1. Input Panel (Sidebar)
    sidebarPanel(
      width = 3,
      h4("1. Proporcionar Datos"),
      radioButtons("input_method", "Método de entrada:",
                   choices = c("Subir Archivo" = "upload", "Pegar Texto" = "paste"),
                   selected = "upload", inline = TRUE),

      conditionalPanel(
        condition = "input.input_method == 'upload'",
        fileInput("datafile", NULL,
                  accept = c(".csv", ".tsv", ".txt"),
                  placeholder = "Seleccione un archivo CSV/TSV")
      ),

      conditionalPanel(
        condition = "input.input_method == 'paste'",
        p("Haga clic en la tabla de abajo y pegue sus datos (Ctrl+V). La tabla se expandirá automáticamente."),
        DTOutput("pasted_table"),
        hr()
      ),
      hr(),

      h4("2. Seleccionar Parámetros"),
      # Dynamic UI to select the level
      uiOutput("level_selector"),



      h4("3. Ejecutar Análisis"),
      h4("3. Run Analysis"),
      # Button to run the analysis
      actionButton("run_analysis", "Ejecutar Análisis",
                   class = "btn-primary btn-block"),

      hr(),
      p("Esta aplicación evalúa la homogeneidad y estabilidad de los ítems de EP de acuerdo con los principios de la norma ISO 13528:2022."),
      h4("4. Download Report"),
      downloadButton("download_report", "Download HTML Report",
                     class = "btn-success btn-block"),

      hr(),
      p("This app assesses homogeneity and stability of PT items according to ISO 13528:2022 principles.")
    ),

    # 2.2. Main Panel for Results
    mainPanel(
      width = 9,
      # Outputs organized in tabs
      tabsetPanel(
        id = "analysis_tabs",

        # Tab 1: Data Preview
        tabPanel("Vista Previa de Datos",
                 h4("Vista Previa de Datos Cargados"),
                 p("Esta tabla muestra las primeras 10 filas de sus datos cargados."),
                 dataTableOutput("raw_data_preview"),
                 hr(),
                 h4("Distribución de Datos"),
                 p("El histograma y el diagrama de caja a continuación muestran la distribución de todos los resultados de las columnas 'sample_*' para el nivel seleccionado."),
                 fluidRow(
                   column(width = 6,
                          plotOutput("results_histogram")
                   ),
                   column(width = 6,
                          plotOutput("results_boxplot")
                   )
                 ),
                 hr(),
                 h4("Validación de Datos"),
                 verbatimTextOutput("validation_message")
        ),

        # Tab 2: Homogeneity Assessment (Combined)
        tabPanel("Homogeneity Assessment",
                 h4("Homogeneity Conclusion"),
                 uiOutput("homog_conclusion"),
                 hr(),
                 h4("Variance Components"),
                 p("Estimated standard deviations from the manual calculation."),
                 tableOutput("variance_components"),
                 hr(),
                 h4("Per-Item Calculations"),
                 p("This table shows calculations for each item (row) in the dataset for the selected level, including the average and range of measurements."),
                 tableOutput("details_per_item_table"),
                 hr(),
                 h4("Estadísticas de Resumen"),
                 p("Esta tabla muestra las estadísticas generales utilizadas para la evaluación de la homogeneidad."),
                 tableOutput("details_summary_stats_table")
        ),

        # Tab 3: Stability Assessment
        tabPanel("Stability Assessment",
                 h4("Conclusion"),
                 uiOutput("stability_conclusion"),
                 hr(),
                 h4("Detalles del Análisis de Estabilidad"),
                 p("Comparación de medias entre dos períodos de medición (simulados dividiendo los datos)."),
                 verbatimTextOutput("stability_details"),
                 hr(),
                 h4("Prueba T para Estabilidad"),
                 p("Una prueba t de dos muestras para verificar diferencias estadísticamente significativas."),
                 verbatimTextOutput("stability_ttest")
        )
      )
    )
  )
)

# ===================================================================
# II. Server Logic
# ===================================================================
server <- function(input, output, session) {

  # --- Server Logic for Pasted Data Table ---

  # Reactive value to store the data from the pasted table.
  # Initialize with a blank data frame to provide a paste-able area.
  pasted_data_rv <- reactiveVal({
    data.frame(
      level = rep(NA_character_, 20), # Start with 20 empty rows
      sample_1 = rep(NA_real_, 20),
      sample_2 = rep(NA_real_, 20),
      stringsAsFactors = FALSE
    )
  })

  # Render the editable data table for pasting
  output$pasted_table <- renderDT({
    datatable(pasted_data_rv(),
              editable = TRUE,
              options = list(
                dom = 't', # Show table only, no search or other DT features
                pageLength = 100, # Allow for many rows to be pasted at once
                ordering = FALSE
              ),
              rownames = FALSE
    )
  })

  # Observer for cell edits (this is how pasting is handled by DT)
  observeEvent(input$pasted_table_cell_edit, {
    info <- input$pasted_table_cell_edit
    df <- pasted_data_rv()

    # If the pasted data exceeds the current number of rows, expand the data frame
    if (info$row > nrow(df)) {
      rows_to_add <- info$row - nrow(df)
      # Create a data frame of NAs to append
      empty_rows <- data.frame(
        level = rep(NA_character_, rows_to_add),
        sample_1 = rep(NA_real_, rows_to_add),
        sample_2 = rep(NA_real_, rows_to_add),
        stringsAsFactors = FALSE
      )
      df <- rbind(df, empty_rows)
    }

    # Update the value in the data frame.
    # Note: DT's cell edit provides a character value, so it needs coercion.
    # The 'level' column is the first column (character).
    if (info$col == 1) {
      df[info$row, info$col] <- as.character(info$value)
    } else { # The sample columns should be numeric.
      # Use suppressWarnings to handle cases where non-numeric data is pasted
      df[info$row, info$col] <- suppressWarnings(as.numeric(info$value))
    }

    pasted_data_rv(df)
  })

  # R1: Initial Data Loading and Processing
  raw_data <- reactive({
    if (input$input_method == "upload") {
      req(input$datafile)
      ext <- tools::file_ext(input$datafile$name)
      switch(ext,
             csv = vroom::vroom(input$datafile$datapath, delim = ","),
             tsv = vroom::vroom(input$datafile$datapath, delim = "\t"),
             txt = vroom::vroom(input$datafile$datapath, delim = ","), # Assuming txt is csv
             validate("Tipo de archivo no válido. Por favor, suba un archivo .csv o .tsv.")
      )
    } else { # "paste"
      # Use the data from the reactive DT table
      df <- pasted_data_rv()
      # Remove rows where all values are NA (often happens with pasting)
      df_clean <- df[rowSums(is.na(df)) < ncol(df), ]
      req(nrow(df_clean) > 0) # Ensure there's some data to process
      df_clean
    }
  })

  # R2: Dynamic Generation of the Level Selector
  output$level_selector <- renderUI({
    data <- raw_data()
    if ("level" %in% names(data)) {
      levels <- unique(data$level)
      selectInput("target_level", "2. Seleccionar Nivel de EP", choices = levels, selected = levels[1])
    } else {
      p("No se encontró la columna 'level' en los datos cargados.")
    }
  })

  # R3: Homogeneity Execution (Triggered by button)
  homogeneity_run <- eventReactive(input$run_analysis, {
    req(raw_data(), input$target_level)
    data <- raw_data()
    target_level <- input$target_level

    # Prepare data for analysis
    level_data <- data %>%
      filter(level == target_level) %>%
      select(starts_with("sample_"))

    g <- nrow(level_data)
    m <- ncol(level_data)

    if (m < 2) {
        return(list(error = "No hay suficientes réplicas (se requieren al menos 2) para la evaluación de la homogeneidad."))
    }
    if (g < 2) {
        return(list(error = "No hay suficientes ítems (se requieren al menos 2) para la evaluación de la homogeneidad."))
    }

    # Create the intermediate calculations table data
    intermediate_df <- if (m == 2) {
      s1 <- level_data[[1]]
      s2 <- level_data[[2]]
      level_data %>%
        mutate(
          Item = row_number(),
          promedio = (s1 + s2) / 2,
          rango = abs(s1 - s2)
        ) %>%
        select(Item, everything())
    } else {
      level_data %>%
        mutate(
          Item = row_number(),
          promedio = rowMeans(., na.rm = TRUE),
          rango = apply(., 1, function(x) max(x, na.rm=TRUE) - min(x, na.rm=TRUE))
        ) %>%
        select(Item, everything())
    }

    # Now create the long data format for calculations
    hom_data <- level_data %>%
      mutate(Item = factor(row_number())) %>%
      pivot_longer(
        cols = -Item,
        names_to = "replicate",
        values_to = "Result"
      )

    # Calculate sigma_pt as MADe from the first sample column ('sample_1')
    if (!"sample_1" %in% names(level_data)) {
        return(list(error = "No se encontró la columna 'sample_1'. Es necesaria para calcular sigma_pt."))
    }
    first_sample_results <- level_data %>% pull(sample_1)
    median_val <- median(first_sample_results, na.rm = TRUE)
    abs_diff_from_median <- abs(first_sample_results - median_val)
    median_abs_diff <- median(abs_diff_from_median, na.rm = TRUE)
    mad_e <- 1.483 * median_abs_diff

    # Robust statistics (for Alternative Method 2 and for display)
    n_robust <- length(first_sample_results)
    u_xpt <- 1.25 * mad_e / sqrt(n_robust)



# --- Manual ANOVA Calculation ---
    # Calculate mean, variance, and range (difference) for each item
    item_stats <- hom_data %>%
      group_by(Item) %>%
      summarise(
        mean = mean(Result, na.rm = TRUE),
        var = var(Result, na.rm = TRUE),
        diff = max(Result, na.rm = TRUE) - min(Result, na.rm = TRUE)
      )

    # Grand mean
    x_t_bar <- mean(item_stats$mean, na.rm = TRUE)

    # Variance of item means
    s_x_bar_sq <- var(item_stats$mean, na.rm = TRUE)
    s_xt <- sqrt(s_x_bar_sq)

    # Mean of item variances (within-sample variance)

    wt = abs(item_stats$diff)
    sw <- sqrt(sum(wt^2) / (2 * length(wt)))

    # Between-sample variance
    # User requested ABS; standard practice is max(0, ...)
    ss_sq <- abs(s_xt^2 - ((sw^2) / 2))
    ss <- sqrt(ss_sq)

    # For display purposes, we can create a data frame that mimics the ANOVA table
    anova_summary_df <- data.frame(
      "Df" = c(g - 1, g * (m - 1)),
      "Suma Cuad." = c(s_x_bar_sq * m * (g - 1), sw^2 * g * (m - 1)),
      "Media Cuad." = c(s_x_bar_sq * m, sw^2),
      "Sum Sq" = c(s_x_bar_sq * m * (g - 1), sw^2 * g * (m - 1)),
      "Mean Sq" = c(s_x_bar_sq * m, sw^2),
      check.names = FALSE
    )

    rownames(anova_summary_df) <- c("Ítem", "Residuales")

    # For the list returned by the reactive
    anova_summary <- anova_summary_df

    # Assessment Criterion (for ANOVA method)

    sigma_pt <- mad_e
    hom_criterion_value <- 0.3 * sigma_pt
    sigma_allowed_sq <- hom_criterion_value^2

    # New criterion c
    c_criterion <- sqrt(sigma_allowed_sq * 1.88 + (sw^2) * 1.01)

    # First comparison: ss vs 0.3 * sigma_pt
    if (ss <= hom_criterion_value) {
      conclusion1 <- sprintf("ss (%.4f) <= 0.3 * sigma_pt (%.4f): CUMPLE", ss, hom_criterion_value)
      conclusion_class <- "alert alert-success"
    } else {
      conclusion1 <- sprintf("ss (%.4f) > 0.3 * sigma_pt (%.4f): NO CUMPLE CRITERIO HOMOGENEIDAD", ss, hom_criterion_value)
      conclusion_class <- "alert alert-warning"
    }

    # Second comparison: ss vs c
    if (ss <= c_criterion) {
      conclusion2 <- sprintf("ss (%.4f) <= c (%.4f): CUMPLE", ss, c_criterion)
    } else {
      conclusion2 <- sprintf("ss (%.4f) > c (%.4f): NO CUMPLE", ss, c_criterion)
    }

    # Combine conclusions
    conclusion <- paste(conclusion1, conclusion2, sep = "<br>")
    list(
      summary = anova_summary,
      ss = ss,
      sw = sw,
      conclusion = conclusion,
      conclusion_class = conclusion_class,
      g = g,
      m = m,
      sigma_allowed_sq = sigma_allowed_sq,
      c_criterion = c_criterion,
      sigma_pt = sigma_pt,
      median_val = median_val,
      median_abs_diff = median_abs_diff,
      u_xpt = u_xpt,
      n_robust = n_robust,
      hom_criterion_value = hom_criterion_value,
      item_means = item_stats$mean,
      general_mean = x_t_bar,
      sd_of_means = s_xt,
      s_x_bar_sq = s_x_bar_sq,
      s_w_sq = sw^2,
      intermediate_df = intermediate_df,
      error = NULL
    )
  })
  # R4: Stability Execution (Triggered by button)
  stability_run <- eventReactive(input$run_analysis, {
    # Depend on homogeneity_run to get the calculated sigma_pt
    req(homogeneity_run())
    hom_results <- homogeneity_run()
    data <- raw_data()
    target_level <- input$target_level
    sigma_pt <- hom_results$sigma_pt

    stab_data_all <- data %>%
      filter(level == target_level) %>%
      select(starts_with("sample_"))

    n_runs <- nrow(stab_data_all)
    if (n_runs < 2) {
      return(list(
          error = "No hay suficientes réplicas (se requieren al menos 2) para realizar una verificación de estabilidad.",
          conclusion = "",
          details = "",
          ttest = ""
          ))
    }

    # Split data to simulate time points
    split_point <- floor(n_runs / 2)
    data_t1 <- stab_data_all %>%
      slice(1:split_point) %>%
      pivot_longer(everything(), values_to = "Result")
    data_t2 <- stab_data_all %>%
      slice((split_point + 1):n_runs) %>%
      pivot_longer(everything(), values_to = "Result")

    y1 <- mean(data_t1$Result, na.rm = TRUE)
    y2 <- mean(data_t2$Result, na.rm = TRUE)
    diff_observed <- abs(y1 - y2)

    # Primary Assessment Criterion
    stab_criterion_value <- 0.3 * sigma_pt

    # Dynamic format for decimal places
    fmt <- "%.9f"

    details_text <- sprintf(
      paste("Media 'Antes' (y1):", fmt, "(usando las primeras %d corridas)\nMedia 'Después' (y2):", fmt, "(usando las últimas %d corridas)\nDiferencia Absoluta Observada:", fmt, "\nCriterio de Estabilidad (0.3 * sigma_pt):", fmt),
      y1, split_point, y2, n_runs - split_point, diff_observed, stab_criterion_value
    )

    if (diff_observed <= stab_criterion_value) {
      conclusion <- "Conclusión (Criterio B.5.1): Los ítems de EP son adecuadamente estables."
      conclusion_class <- "alert alert-success"
    } else {
      conclusion <- "Conclusión (Criterio B.5.1): ADVERTENCIA: Los ítems de EP pueden mostrar una deriva inaceptable."
      conclusion_class <- "alert alert-warning"
    }

    # T-test
    t_test_result <- t.test(data_t1$Result, data_t2$Result)

    if (t_test_result$p.value > 0.05) {
      ttest_conclusion <- "Prueba T: No se detectó diferencia estadísticamente significativa (p > 0.05), lo que respalda la estabilidad."
    } else {
      ttest_conclusion <- "Prueba T: Se detectó una diferencia estadísticamente significativa (p <= 0.05), lo que indica una posible inestabilidad."
    }

    list(
      conclusion = conclusion,
      conclusion_class = conclusion_class,
      details = details_text,
      ttest_summary = t_test_result,
      ttest_conclusion = ttest_conclusion,
      error = NULL
    )
  })

  # --- Outputs ---

  # Output: Data Preview
  output$raw_data_preview <- renderDataTable({
    # Ensure we have data and the decimal place input before rendering
    req(raw_data())

    df <- head(raw_data(), 10)

    # Identify numeric columns to format
    numeric_cols <- names(df)[sapply(df, is.numeric)]

    # Create the format string based on user input
    fmt <- "%.9f"

    # Apply formatting to all numeric columns
    df <- df %>%
      mutate(across(all_of(numeric_cols), ~ sprintf(fmt, .x)))

    datatable(df, options = list(scrollX = TRUE))
  })

  # Output: Validation Message
  output$validation_message <- renderPrint({
    data <- raw_data()
    cat("Datos cargados con éxito.\n")
    cat(paste("Dimensiones:", paste(dim(data), collapse = " x "), "\n"))

    required_cols <- c("level")
    has_samples <- any(str_detect(names(data), "sample_"))

    if(!all(required_cols %in% names(data))) {
        cat(paste("ERROR: Falta(n) la(s) siguiente(s) columna(s) requerida(s):", paste(setdiff(required_cols, names(data)), collapse=", "), "\n"))
    } else {
        cat("Se encontró la columna 'level'.\n")
    }

    if(!has_samples) {
        cat("ERROR: No se encontraron columnas con el prefijo 'sample_'. Son necesarias para el análisis.\n")
    } else {
        cat("Se encontraron columnas 'sample_*'.\n")
    }
  })

  # Reactive expression for plotting data
  plot_data_long <- reactive({
    req(raw_data(), input$target_level)
    raw_data() %>%
      filter(level == input$target_level) %>%
      select(starts_with("sample_")) %>%
      pivot_longer(everything(), names_to = "sample", values_to = "result")
  })

  # Output: Histogram
  output$results_histogram <- renderPlot({
    req(plot_data_long())
    ggplot(plot_data_long(), aes(x = result)) +
      geom_histogram(aes(y = after_stat(density)), color = "black", fill = "skyblue", bins = 20) +
      geom_density(alpha = 0.4, fill = "lightblue") +
      labs(title = paste("Distribución para el Nivel:", input$target_level),
           x = "Resultado", y = "Densidad") +
      theme_minimal()
  })

  # Output: Boxplot
  output$results_boxplot <- renderPlot({
    req(plot_data_long())
    ggplot(plot_data_long(), aes(x = result)) +
      geom_boxplot(fill = "lightgreen", outlier.colour = "red") +
      labs(title = paste("Diagrama de Caja para el Nivel:", input$target_level),
           x = "Resultado") +
      theme_minimal() +
      theme(axis.text.y=element_blank(),
            axis.ticks.y=element_blank(),
            axis.title.y=element_blank())
  })



  # Output: Variance Components
  output$variance_components <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
        df <- data.frame(
          Componente = c("Valor Asignado (xpt)",
                        "DE Robusta (sigma_pt)",
                        "Incertidumbre del Valor Asignado (u_xpt)",
                        "DE Entre Muestras (ss)",
                        "DE Dentro de la Muestra (sw)",
                        "---",
                        "0.3 * Sigma PT",
                        "Sigma Permitida Cuad.",
                        "Criterio c"),
          Valor = c(
            format(c(res$median_val, res$sigma_pt, res$u_xpt, res$ss, res$sw), digits = 15, scientific = FALSE),
            "",
            format(c(res$hom_criterion_value, res$sigma_allowed_sq, res$c_criterion), digits = 15, scientific = FALSE)
          )
        )
        df
    }
  })

  # Output: Stability Conclusion
  output$stability_conclusion <- renderUI({
    res <- stability_run()
    if (!is.null(res$error)) {
        div(class = "alert alert-danger", res$error)
    } else {
        div(class = res$conclusion_class, res$conclusion)
    }
  })

  # Output: Stability Details
  output$stability_details <- renderPrint({
      res <- stability_run()
      if (is.null(res$error)) {
          cat(res$details)
      }
  })

  # Output: Stability T-test
  output$stability_ttest <- renderPrint({
      res <- stability_run()
      if (is.null(res$error)) {
          cat(res$ttest_conclusion, "\n\n")
          print(res$ttest_summary, digits = 9)
      }
  })

  # Output: Details per item table
  output$details_per_item_table <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      res$intermediate_df
    }
  }, spacing = "l", digits = 15)

  # Output: Details summary stats table
  output$details_summary_stats_table <- renderTable({
    res <- homogeneity_run()
    if (is.null(res$error)) {
      data.frame(
        Parámetro = c("Media General",
                      "DE de las Medias",
                      "Varianza de las Medias (s_x_bar_sq)",
                      "sw",
                      "Varianza Dentro de la Muestra (s_w_sq)",
                      "ss",
                      "---",
                      "Valor Asignado (xpt)",
                      "Mediana de las Diferencias Absolutas",
                      "Número de Réplicas (n_robust)",
                      "DE Robusta (MADe)",
                      "Incertidumbre del Valor Asignado (u_xpt)",
                      "---",
                      "0.3 * sigma_pt",
                      "Criterio c"),
        Valor = c(
          format(c(res$general_mean, res$sd_of_means, res$s_x_bar_sq, res$sw, res$s_w_sq, res$ss), digits = 15, scientific = FALSE),
          "",
          format(c(res$median_val, res$median_abs_diff, res$n_robust, res$sigma_pt, res$u_xpt), digits = 15, scientific = FALSE),
          "",
          format(c(res$hom_criterion_value, res$c_criterion), digits = 15, scientific = FALSE)
        )
      )
    }
  }, spacing = "l")

  # R5: Download Handler for the Report
  output$download_report <- downloadHandler(
    filename = function() {
      paste0("pt_analysis_report-", Sys.Date(), ".html")
    },
    content = function(file) {
      # Create a temporary Rmd file
      temp_report <- file.path(tempdir(), "report.Rmd")

      # Create a template Rmd file for the report
      writeLines(
'---
title: "PT Analysis Report"
output: html_document
params:
  homogeneity_results: NA
  stability_results: NA
  target_level: NA
  data_preview: NA
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE)
library(knitr)
```

## Data Preview

```{r}
knitr::kable(params$data_preview, caption = "Preview of the first 10 rows of data.")
```

## Homogeneity Assessment

**Target Level:** `r params$target_level`

**Conclusion:** `r params$homogeneity_results$conclusion`

### Variance Components

```{r}
# Custom table for variance components
var_comp <- data.frame(
  Component = c("Between-Sample SD (ss)", "Within-Sample SD (sw)", "Robust SD (sigma_pt)", "0.3 * sigma_pt"),
  Value = c(params$homogeneity_results$ss, params$homogeneity_results$sw, params$homogeneity_results$sigma_pt, params$homogeneity_results$hom_criterion_value)
)
knitr::kable(var_comp, caption = "Key variance components.")
```

## Stability Assessment

**Conclusion:** `r params$stability_results$conclusion`

### Stability Details

```
`r params$stability_results$details`
```

### T-test Summary

```
`r capture.output(print(params$stability_results$ttest_summary))`
```

',
        temp_report
      )

      # Get the results from the reactive expressions
      hom_res <- homogeneity_run()
      stab_res <- stability_run()

      # Set up parameters to pass to the Rmd file
      params <- list(
        homogeneity_results = hom_res,
        stability_results = stab_res,
        target_level = input$target_level,
        data_preview = head(raw_data(), 10)
      )

      # Render the Rmd file
      rmarkdown::render(temp_report,
                        output_file = file,
                        params = params,
                        envir = new.env(parent = globalenv()))
    }
  )

}

# ===================================================================
# III. Run the Application
# ===================================================================
shinyApp(ui = ui, server = server)
