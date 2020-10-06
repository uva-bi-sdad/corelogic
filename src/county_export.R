library(RPostgreSQL)
library(xlsx)


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

counties <- dbGetQuery(con, "select * from corelogic_usda.counties where \"GEOID\" like '51%'")

for (i in 1:nrow(counties[1:3,])) {
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
    pri_cat_code
  FROM
    corelogic_usda.broadband_variables_tax_2020_06_27_unq
  WHERE geoid_cnty = '", counties[i,]$GEOID,"'
    AND property_indicator='10'")

  rows <- dbGetQuery(con, qry)
  write.csv(rows, paste0("data/county_data/", counties[i,]$NAME, "_", counties[i,]$GEOID, ".csv"))
}

dbDisconnect(con)

#write.xlsx(rows, "data/prop1006037.xlsx")



