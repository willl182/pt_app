# Open a file to sink the output
log_file <- file("shiny_app.log", open = "wt")
sink(log_file, type = "output")
sink(log_file, type = "message")

# Announce that logging has started
cat("Logging started.\n")

# Load the shiny library and run the app
tryCatch({
    cat("Loading shiny library...\n")
    library(shiny)
    cat("Shiny library loaded. Starting app...\n")
    shiny::runApp('app.R', port = 8080)
}, error = function(e) {
    # Log any errors during startup
    cat("An error occurred during app startup:\n")
    cat(e$message, "\n")
}, finally = {
    # Close the sink
    cat("Closing log file.\n")
    sink(type = "message")
    sink(type = "output")
    close(log_file)
})