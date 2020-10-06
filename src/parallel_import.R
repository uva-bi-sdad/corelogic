library(foreach)
library(doParallel)
library(RPostgreSQL)
library(magrittr)

get_db_conn <-
  function(db_name = "sdad",
           db_host = "postgis1",
           db_port = "5432",
           db_user = Sys.getenv("db_usr"),
           db_pass = Sys.getenv("db_pwd")) {
    RPostgreSQL::dbConnect(
      drv = RPostgreSQL::PostgreSQL(),
      dbname = db_name,
      host = db_host,
      port = db_port,
      user = db_user,
      password = db_pass
    )
  }

file_paths <- list.files(path = "/project/biocomplexity/sdad/projects_data/usda/bb/original/Corelogic_June_2020_Files/splits", full.names = T)

tbl <- data.table::fread(file_paths[1], colClasses = "character")
db_col_names <- dataplumbr::name.standard_col_names(colnames(tbl)) %>%
  stringr::str_replace("^_", "") %>%
  stringr::str_replace("_$", "")
colnames(tbl) <- db_col_names
con <- get_db_conn()
tbl[, sale_amount := as.numeric(sale_amount)]
tbl[, tax_amount := as.numeric(tax_amount)]
tbl[, inter_family := as.logical(inter_family)]
tbl[, property_level_latitude := as.numeric(property_level_latitude)]
tbl[, property_level_longitude := as.numeric(property_level_longitude)]
tbl[, bedrooms := as.numeric(bedrooms)]
tbl[, total_baths := as.numeric(total_baths)]
tbl[, total_value_calculated := as.numeric(total_value_calculated)]
tbl[, land_value_calculated := as.numeric(land_value_calculated)]
tbl[, acres := as.numeric(acres)]
tbl[, land_square_footage := as.numeric(land_square_footage)]
tbl[, building_square_feet := as.numeric(building_square_feet)]
tbl[, gross_square_feet := as.numeric(gross_square_feet)]
dbWriteTable(con, c("corelogic_usda", "testtable2"), tbl, overwrite = T, row.names = F)
dbDisconnect(con)

rm(tbl)

cl <- makeForkCluster(10, outfile = "src/parlog")
doParallel::registerDoParallel(cl)
#system.time(
res <- foreach(i = 201:297) %dopar% {
  con <- get_db_conn()
  print(paste("reading", file_paths[i]))
  dt <- data.table::fread(file_paths[i], colClasses = "character")
  colnames(dt) <- db_col_names
  dt[, sale_amount := as.numeric(sale_amount)]
  dt[, tax_amount := as.numeric(tax_amount)]
  dt[, inter_family := as.logical(inter_family)]
  dt[, property_level_latitude := as.numeric(property_level_latitude)]
  dt[, property_level_longitude := as.numeric(property_level_longitude)]
  dt[, bedrooms := as.numeric(bedrooms)]
  dt[, total_baths := as.numeric(total_baths)]
  dt[, total_value_calculated := as.numeric(total_value_calculated)]
  dt[, land_value_calculated := as.numeric(land_value_calculated)]
  dt[, acres := as.numeric(acres)]
  dt[, land_square_footage := as.numeric(land_square_footage)]
  dt[, building_square_feet := as.numeric(building_square_feet)]
  dt[, gross_square_feet := as.numeric(gross_square_feet)]
  res <- dbWriteTable(con, c("corelogic_usda", "testtable2"), dt, append = T, row.names = F)
  print(paste(res, "written", file_paths[i]))
  dbDisconnect(con)
}
#)
parallel::stopCluster(cl)

