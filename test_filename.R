# Mock inputs
input <- list(
    report_format = "word",
    report_n_lab = "13",
    report_metric = "zeta",
    report_method = "2a",
    report_metrological_compatibility = "2a"
)

# Logic from app.R
filename_gen <- function() {
    ext <- switch(input$report_format,
        html = "html",
        word = "docx"
    )

    fname <- paste0(
        "Informe_EA_", Sys.Date(), "_",
        input$report_n_lab, "-",
        input$report_metric, "-",
        input$report_method, "-",
        input$report_metrological_compatibility
    )

    paste0(fname, ".", ext)
}

# Test
generated <- filename_gen()
expected_start <- paste0("Informe_EA_", Sys.Date(), "_13-zeta-2a-2a.docx")

print(paste("Generated:", generated))
print(paste("Expected :", expected_start))

if (generated == expected_start) {
    print("PASS: Filename format is correct.")
} else {
    stop("FAIL: Filename format mismatch.")
}
