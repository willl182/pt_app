test_that("inventory script generates a valid CSV", {
  # Temporarily switch to project root
  old_wd <- setwd("../..")
  on.exit(setwd(old_wd))
  
  inventory_path <- tempfile(fileext = ".csv")
  script_path <- "scripts/documentacion/generar_inventario_entregables.R"
  on.exit(unlink(inventory_path), add = TRUE)
  
  expect_true(file.exists(script_path), "Inventory script should exist")
  
  # Run without rewriting the controlled inventory used by later tests.
  status <- system2(
    "Rscript",
    c(script_path, ".", inventory_path),
    stdout = FALSE,
    stderr = FALSE
  )
  expect_equal(status, 0L)
  
  expect_true(file.exists(inventory_path), "Inventory CSV should be created")
  
  df <- read.csv(inventory_path, check.names = FALSE)
  expect_true(
    all(c("ruta", "tamano_bytes", "sha256") %in% names(df)),
    "CSV should contain the controlled inventory columns"
  )
  expect_gt(nrow(df), 0)
})
