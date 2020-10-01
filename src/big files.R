library(vroom)
library(RPostgreSQL)
library(magrittr)
library(data.table)

get_db_conn <-
  function(db_name = "sdad",
           db_host = "localhost",
           db_port = "5434",
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
con <- get_db_conn()

file_path <- "data/deed_sm.txt"
vrm <- vroom(file_path)

db_col_names <- dataplumbr::name.standard_col_names(colnames(vrm)) %>%
  stringr::str_replace("^_", "") %>%
  stringr::str_replace("_$", "")

colnames(vrm) <- db_col_names

dbWriteTable(con, c("corelogic_usda", "corelogic_usda_deed_2020_06_27_17_18_19"), vrm, row.names = F, overwrite = T)

# first_line <- readLines(file_path, n = 1)
# col_delim_num <- stringr::str_count(first_line, "\\|")
# col_num <- col_delim_num + 1

deeds_all <- vroom("/project/biocomplexity/sdad/projects_data/usda/bb/original/Corelogic_June_2020_Files/Corelogic_USDA_Deed_2020_06_27_10M.txt")

deeds_all <- fread("/project/biocomplexity/sdad/projects_data/usda/bb/original/Corelogic_June_2020_Files/Corelogic_USDA_Deed_2020_06_27_50M.txt")

deeds_cols <- fread("/project/biocomplexity/sdad/projects_data/usda/bb/original/Corelogic_June_2020_Files/Corelogic_USDA_Deed_2020_06_27_10M.txt", nrows = 1)

colnames(deeds_all) <- colnames(deeds_cols)

deeds_all[`RECORDING DATE (YYYYMMDD)` %like% "^2018", .N]

db_col_names <- dataplumbr::name.standard_col_names(colnames(deeds_all)) %>%
  stringr::str_replace("^_", "") %>%
  stringr::str_replace("_$", "")

colnames(deeds_all) <- db_col_names
