library(vroom)
library(RPostgreSQL)
library(magrittr)
library(data.table)
<<<<<<< HEAD
library(dplyr)
=======
>>>>>>> 979b5dd3e9bbcfa19174827e8013ad3992efebfb

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


deeds_all <- vroom("data/Corelogic_USDA_Deed_2020_06_27_20M.txt")

deeds_all <- vroom("/project/biocomplexity/sdad/projects_data/usda/bb/original/Corelogic_June_2020_Files/Corelogic_USDA_Deed_2020_06_27_10M.txt")

deeds_all <- fread("/project/biocomplexity/sdad/projects_data/usda/bb/original/Corelogic_June_2020_Files/Corelogic_USDA_Deed_2020_06_27_50M.txt")

deeds_cols <- fread("/project/biocomplexity/sdad/projects_data/usda/bb/original/Corelogic_June_2020_Files/Corelogic_USDA_Deed_2020_06_27_10M.txt", nrows = 1)

colnames(deeds_all) <- colnames(deeds_cols)

deeds_all[`RECORDING DATE (YYYYMMDD)` %like% "^2018", .N]


deeds_all <- fread("data/tail1M.txt")

db_col_names <- dataplumbr::name.standard_col_names(colnames(deed100k)) %>%
  stringr::str_replace("^_", "") %>%
  stringr::str_replace("_$", "")

colnames(deeds_all) <- colnames(deed100k)

deeds_all[`SALE DATE (YYYYMMDD)` %like% "^2018", .N]

deed100k <- vroom("data/deed100k.txt")

eighteen <- deed100k %>% filter("sale_date_yyyymmdd" == 20050719) %>% select("sale_date_yyyymmdd")

setDT(deeds_all)
deeds_all[sale_date_yyyymmdd %like% "^2018", ]

deed100k[700:720, c("sale_date_yyyymmdd", "recording_date_yyyymmdd")]

deeds_all %>% filter(`RECORDING DATE (YYYYMMDD)` %like% "^2015") %>% count()

library(dplyr)
mydata <- mtcars

# subset the rows of dataframe with condition
Mydata1 %>% filter(cyl==6) %>% count()
Mydata1








cols <- c("geoid_cnty",
  "p_id_iris_frmtd",
  "sale_date",
  "sale_price",
  "sale_code",
  "transaction_type",
  "bldg_code",
  "building_square_feet",
  "living_square_feet",
  "year_built",
  "effective_year_built",
  "bedrooms",
  "full_baths",
  "\"1qtr_baths\"",
  "\"3qtr_baths\"",
  "half_baths",
  "total_baths",
  "address",
  "property_indicator",
  "zoning",
  "acres",
  "land_square_footage",
  "property_centroid_longitude",
  "property_centroid_latitude",
  "geometry")


paste(paste0("MAX(", cols, ") ", cols), collapse = ", ")
