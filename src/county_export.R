library(RPostgreSQL)
library(xlsx)
library(zip)
library(data.table)
library(magrittr)
source("R/functions.R")



con <- get_db_conn(db_host = "localhost", db_port = 5434)

counties <- merge(setDT(tigris::states()), setDT(tigris::counties()), by = "STATEFP") %>%
  .[, .(abbrv_st = STUSPS, name_co = NAMELSAD, geoid_co = GEOID.y)]

# counties <- counties[abbrv_st=="IN",]

for (i in 3001:3233) {
  qry <-
    paste0("SELECT
    geoid_cnty,
    geoid_blk,
    p_id_iris_frmtd,
    property_indicator,
    acres,
    land_square_footage,
    bldg_code,
    building_square_feet,
    living_square_feet,
    year_built,
    effective_year_built,
    bedrooms,
    baths_appraised,
    situs_address property_address,
    sale_price,
    sale_date,
    sale_year,
    transaction_type,
    property_centroid_latitude,
    property_centroid_longitude
  FROM
    corelogic_usda.current_tax_200627_latest_all_add_vars_add_progs_geom_blk
  WHERE geoid_cnty = '", counties[i,]$geoid_co, "'")

  rows <- dbGetQuery(con, qry)
  file_name <- paste0(counties[i,]$abbrv_st,
                      "_",
                      counties[i,]$geoid_co,
                      "_",
                      gsub(" ", "_", counties[i,]$name_co))
  csv_path <- paste0("src/dashboard/www/county_data/",
                    file_name,
                    ".csv")
  # xlsx_path <- paste0("data/county_data/",
  #                    file_name,
  #                    ".xlsx")
  zip_path <- paste0("src/dashboard/www/county_data/",
                     file_name,
                     ".zip")
  write.csv(rows, csv_path)

  write.csv(rows, csv_path)
  # write.xlsx(rows, xlsx_path)
  zip(zip_path, csv_path)
  unlink(csv_path)
}

DBI::dbDisconnect(con)





