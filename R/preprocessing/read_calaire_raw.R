read_calaire_raw <- function(path) {
  if (!file.exists(path)) stop("File not found: ", path)

  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lines <- lines[nchar(trimws(lines)) > 0]

  if (length(lines) < 2) stop("File has fewer than 2 non-empty lines: ", path)

  # Auto-detect delimiter: semicolon, comma, tab, or whitespace
  count_delim <- function(line, d, fixed = TRUE) {
    length(strsplit(line, d, fixed = fixed)[[1]])
  }
  n_semicolon <- count_delim(lines[1], ";")
  n_comma <- count_delim(lines[1], ",")
  n_tab <- count_delim(lines[1], "\t")
  n_space <- count_delim(lines[1], "\\s+", fixed = FALSE)

  is_regex <- FALSE
  delimiter <- if (n_semicolon > 2) {
    ";"
  } else if (n_comma > 2) {
    ","
  } else if (n_tab > 2) {
    "\t"
  } else {
    is_regex <- TRUE
    "\\s+"  # whitespace regex
  }

  # Split header using appropriate method
  if (is_regex) {
    header_raw <- strsplit(lines[1], "\\s+")[[1]]
    second_raw <- strsplit(lines[2], "\\s+")[[1]]
  } else {
    header_raw <- strsplit(lines[1], delimiter, fixed = TRUE)[[1]]
    second_raw <- strsplit(lines[2], delimiter, fixed = TRUE)[[1]]
  }

  date_pattern <- "^[0-9]{1,2}/[0-9]{1,2}/([0-9]{2}|[0-9]{4})$"
  has_units_row <- !grepl(date_pattern, trimws(second_raw[1]))
  units_raw <- if (has_units_row) second_raw else rep(NA_character_, length(header_raw))

  data_lines <- if (has_units_row) lines[-(1:2)] else lines[-1]
  con <- textConnection(paste(data_lines, collapse = "\n"))
  df <- tryCatch({
    if (is_regex) {
      # Use default sep (any whitespace) for whitespace-delimited files
      read.table(con, header = FALSE, stringsAsFactors = FALSE,
                 colClasses = "character", fill = TRUE, quote = "\"")
    } else {
      read.table(con, sep = delimiter, header = FALSE, stringsAsFactors = FALSE,
                 colClasses = "character", fill = TRUE, quote = "\"")
    }
  }, finally = {
    close(con)
  })

  n_cols <- length(header_raw)
  if (ncol(df) < n_cols) {
    for (i in seq(ncol(df) + 1, n_cols)) df[[paste0("V", i)]] <- NA_character_
  } else if (ncol(df) > n_cols) {
    df <- df[, seq_len(n_cols), drop = FALSE]
  }
  colnames(df) <- make.names(trimws(header_raw), unique = TRUE)

  list(
    data   = df,
    header = trimws(header_raw),
    units  = setNames(trimws(units_raw), trimws(header_raw)),
    n_rows = nrow(df),
    path   = path
  )
}
