# tools/inventory_docs.R

# Ensure we are in project root or handle relative paths
# This script assumes it is run from the project root

sources <- c("gem_docs", "claude_docs", "glm_docs")
# Ensure output directory exists
output_dir <- "conductor/tracks/doc_consolidation_20260110"
if (!dir.exists(output_dir)) {
    # Try to find it relative to current location if we are not in root
    # But for now assume root
    warning("Output directory not found: ", output_dir)
}

output_file <- file.path(output_dir, "inventory.csv")

all_files <- data.frame(Source = character(), Filename = character(), Path = character(), stringsAsFactors = FALSE)

for (src in sources) {
  if (dir.exists(src)) {
    files <- list.files(src, recursive = TRUE, full.names = FALSE)
    # Filter for markdown files only
    files <- files[grep("\\.md$", files)]
    
    if (length(files) > 0) {
      src_df <- data.frame(
        Source = src,
        Filename = files,
        Path = file.path(src, files),
        stringsAsFactors = FALSE
      )
      all_files <- rbind(all_files, src_df)
    }
  } else {
      warning("Source directory not found: ", src)
  }
}

write.csv(all_files, output_file, row.names = FALSE)
message("Inventory created at ", output_file)

