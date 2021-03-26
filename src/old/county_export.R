library(RPostgreSQL)
library(xlsx)
library(zip)
library(data.table)
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
con <- get_db_conn()

counties <- merge(setDT(tigris::states()), setDT(tigris::counties()), by = "STATEFP") %>%
  .[, .(abbrv_st = STUSPS, name_co = NAMELSAD, geoid_co = GEOID.y)]

counties <- counties[abbrv_st=="IN",]

for (i in 1:nrow(counties)) {
  qry <-
    paste0("SELECT
    geoid_cnty,
    p_id_iris_frmtd,
    sale_date,
    sale_price,
    sale_code,
    transaction_type,
    bldg_code,
    building_square_feet,
    living_square_feet,
    year_built,
    effective_year_built,
    bedrooms,
    full_baths,
    \"1qtr_baths\",
    \"3qtr_baths\",
    half_baths,
    total_baths,
    property_indicator,
    zoning,
    acres,
    land_square_footage,
    property_centroid_longitude,
    property_centroid_latitude,
    pri_cat_code,
    \"BIP\",
    \"CC\",
    \"RC\",
    \"TCF\",
    \"TCI\"
  FROM
    corelogic_usda.broadband_variables_tax_2020_06_27_unq_prog
  WHERE geoid_cnty = '", counties[i,]$geoid_co,"'
    AND property_indicator='10'")

  rows <- dbGetQuery(con, qry)
  file_name <- paste0(counties[i,]$abbrv_st,
                      "_",
                      counties[i,]$geoid_co,
                      "_",
                      gsub(" ", "_", counties[i,]$name_co))
  csv_path <- paste0("src/www/county_data/",
                    file_name,
                    ".csv")
  # xlsx_path <- paste0("data/county_data/",
  #                    file_name,
  #                    ".xlsx")
  zip_path <- paste0("src/www/county_data/",
                     file_name,
                     ".zip")
  write.csv(rows, csv_path)
  # write.xlsx(rows, xlsx_path)
  zip(zip_path, csv_path)
  unlink(csv_path)
}

dbDisconnect(con)





