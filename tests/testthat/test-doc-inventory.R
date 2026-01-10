test_that("inventory script generates a valid CSV", {
  # Temporarily switch to project root
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))
  
  inventory_path <- "conductor/tracks/doc_consolidation_20260110/inventory.csv"
  script_path <- "tools/inventory_docs.R"
  
  expect_true(file.exists(script_path), "Inventory script should exist")
  
  # Run the script
  source(script_path, local = TRUE)
  
  expect_true(file.exists(inventory_path), "Inventory CSV should be created")
  
  df <- read.csv(inventory_path)
  expect_true(all(c("Source", "Filename", "Path") %in% names(df)), "CSV should have Source, Filename, Path columns")
  expect_gt(nrow(df), 0)
})
