read_calaire_raw <- function(path) {
  if (!file.exists(path)) stop("File not found: ", path)

  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lines <- lines[nchar(trimws(lines)) > 0]

  if (length(lines) < 2) stop("File has fewer than 2 non-empty lines: ", path)

  header_raw <- strsplit(lines[1], ";")[[1]]
  second_raw <- strsplit(lines[2], ";")[[1]]
  has_units_row <- !grepl("^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$", trimws(second_raw[1]))
  units_raw <- if (has_units_row) second_raw else rep(NA_character_, length(header_raw))

  data_lines <- if (has_units_row) lines[-(1:2)] else lines[-1]
  con <- textConnection(paste(data_lines, collapse = "\n"))
  df <- tryCatch({
    read.table(con, sep = ";", header = FALSE, stringsAsFactors = FALSE,
               colClasses = "character", fill = TRUE, quote = "")
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
