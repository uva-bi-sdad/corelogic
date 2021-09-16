library(RPostgreSQL)
library(xlsx)
library(zip)
library(here)
library(data.table)
library(readr)
#library(magrittr)
#source("R/functions.R")
`%>%` <- magrittr::`%>%`

con <- dbConnect(PostgreSQL(), 
                 dbname = "sdad",
                 host = "postgis1", 
                 port = 5432, 
                 password = "password") #<-- enter password here


# con <- get_db_conn(db_host = "localhost", db_port = 5434)

counties <- merge(setDT(tigris::states()), setDT(tigris::counties()), 
                  by = "STATEFP") %>%
  .[, .(abbrv_st = STUSPS, name_co = NAMELSAD, geoid_co = GEOID.y)]

# counties <- counties[abbrv_st=="IN",]

fips <- dbGetQuery(con, "SELECT DISTINCT geoid_cnty
                   FROM corelogic_usda.current_tax_200627_latest_all_add_vars_add_progs_geom_blk")

counties <- merge(fips, counties, 
                       by.x="geoid_cnty", 
                       by.y="geoid_co", 
                       all.x = TRUE, all.y = FALSE)

for (i in 1:length(counties$abbrv_st)) {
# test
#for (i in 1:10) { 
  print(i)
  print(counties[i,]$abbrv_st)
  print(counties[i,]$name_co)
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
  WHERE  property_indicator = '10'
  AND    transaction_type != '9'
  AND geoid_cnty = '", counties[i,]$geoid_cnty, "'")

  rows <- dbGetQuery(con, qry)
  rows <- rows %>% filter(is.na(bldg_code) |
                            bldg_code == "001"|	#TYPE UNKNOWN
                            bldg_code == "A0G" | # House
                            bldg_code == "A0B" | # Building
                            bldg_code == "A0Z" | #RANCH
                            bldg_code == "AYG"|	#FARM HOUSE
                            bldg_code == 'GKH' |	#PUBLIC HOUSING
                            bldg_code == 'GUH'|	#ELDERLY/SENIOR HOUSING
                            bldg_code == 'M0M' |	#MULTI-PLEX
                            bldg_code == "M0P" |	#COOP
                            bldg_code == 'M50' |	#5-PLEX
                            bldg_code == "M51" |	#5-PLEX AND HIGHER
                            bldg_code == "M60" | #6-PLEX
                            bldg_code == "M80"	| #8-PLEX
                            bldg_code == "M90" |	#9-PLEX
                            bldg_code == "MA0" |	#APARTMENT
                            bldg_code == "MAA" |	#APARTMENT HI RISE
                            bldg_code == "MAB"	| #APARTMENT LOW RISE
                            bldg_code == "MAC" |	#APARTMENT CONDO
                            bldg_code == "MAL" |	#APARTMENT MID RISE
                            bldg_code == "MAO" | #APARTMENT & OFFICE
                            bldg_code == "MAP" |	#APARTMENT COOP
                            bldg_code == "MAR"	| #APARTMENT RETIREMENT
                            bldg_code == "MAS"	| #APARTMENT SENIOR
                            bldg_code == "MAT"	| #APARTMENT TOWNHOUSE
                            bldg_code =="MCA" |	#CONDO HI RISE
                            bldg_code == "MCB"	| #CONDO LOW RISE
                            bldg_code == "MCE" |	#CONDO APARTMENT
                            bldg_code == "MCM" |	#CONDO-MULTIPLEX
                            bldg_code == "MCO" |	#CONDO OFFICE
                            bldg_code == "MCT" |	#CONDO TOWNHOUSE
                            bldg_code == "MCU" | #CONDO PENTHOUSE
                            bldg_code == "MDC" |	#DUPLEX CONDO
                            bldg_code == "MDE" |	#DUPLEX APARTMENT
                            bldg_code == "MDF" |	#DUPLEX/TRIPLEX 
                            bldg_code == 'MD0' | #Duplex
                            bldg_code == 'MRE' |	#ROW TYPE APARTMENT
                            bldg_code == 'MS0' | #ROW TYPE
                            bldg_code == 'MST' |	#ROW TYPE TOWNHOUSE
                            bldg_code == 'MT0' | #TRIPLEX
                            bldg_code == "R00" |	#RESIDENTIAL
                            bldg_code == "R0C" | #RESIDENTIAL CONDO
                            bldg_code == "R0F" |	#MANUFACTURED HOME
                            bldg_code == "R0S" | #SENIOR CITIZEN HOUSING
                            bldg_code == "R10" |	#DETACHED
                            bldg_code == "R20" |	#ROW
                            bldg_code == "R30" |	#END ROW
                            bldg_code == "R40" |	#FLAT
                            bldg_code == "R80" |	#ZERO LOT LINE
                            bldg_code == "R90"	| #HALF-PLEX
                            bldg_code == "RC0"	| #CABIN/COTTAGE
                            bldg_code == "RCA"	| #CABIN/APARTMENT
                            bldg_code == "RG0" |	#GUEST HOUSE
                            bldg_code == "RM0" |	#MOBILE HOME
                            bldg_code == "RM1"	| #MOBILE HOME SINGLE WIDE
                            bldg_code == "RM2" |	#MOBILE HOME DOUBLE WIDE
                            bldg_code == "RMB" |	#MOBILE HOME COOP
                            bldg_code =="RMC"	| #CONDO MOBILE HOME
                            bldg_code == "RQ0" |	#ROW TYPE
                            bldg_code =="RS0" |	#SINGLE FAMILY
                            bldg_code == "RSF" |	#SINGLE FAMILY MANUFACTURED
                            bldg_code == "RT0" |	#TOWNHOUSE
                            bldg_code == "RU0" |	#PATIO HOME
                            bldg_code =="RW0" |	#RESIDENCE & WORKSHOP
                            bldg_code == "RY0" | #RESIDENTIAL MIXED USE  
                            bldg_code == "X0M" |	#HOME
                            bldg_code == "X0N" |	#PARSONAGE
                            bldg_code == "X0Z" |	#ASSISTED LIVING
                            bldg_code == "Y1A"	| #STABLE & APARTMENT
                            bldg_code == "Y1L"	| #STABLE & LIVING QUARTERS
                            bldg_code == "YBA"	| #BEAUTY SHOP & APARTMENT
                            bldg_code == "YCR"	| #COMMERCIAL & RESIDENTIAL
                            bldg_code == "YDA"	| #CONDO & SINGLE FAMILY RESIDENC
                            bldg_code == "YOL"	| #OFFICE & LIVING QUARTERS
                            bldg_code == "YOR"	| #OFFICE & RESIDENTIAL
                            bldg_code == "YQ1" |	#RESIDENTIAL & STORAGE
                            bldg_code == "YQB" | #RESIDENTIAL & BARN
                            bldg_code == "YQO" | #RESIDENTIAL & OFFICE
                            bldg_code == "YQR" |	#APARTMENTS & RESIDENTIAL
                            bldg_code == "YQS" |	#RESIDENTIAL & SHOP
                            bldg_code == "YRA" |	#RETAIL & APARTMENT
                            bldg_code == "YSA"	| #APARTMENT/STORE
                            bldg_code == "YSR"	| #STORE & RESIDENTIAL
                            bldg_code == "YTA"	| #TAVERN & APARTMENTS
                            bldg_code == "YWA"	| #WAREHOUSE & APARTMENT
                            bldg_code == "YWR" #WAREHOUSE & RESIDENTIAL
  ) 
  
  
  file_name <- paste0(counties[i,]$abbrv_st,
                      "_",
                      counties[i,]$geoid_cnty,
                      "_",
                      gsub(" ", "_", counties[i,]$name_co))
  
  csv_path <- paste0("~/git/corelogic/src/web/shiny_app/www/",
                    file_name,
                    ".csv")
  # xlsx_path <- paste0("data/county_data/",
  #                    file_name,
  #                    ".xlsx")
  # new file path 
  #zip_path <- paste0("~/git/corelogic/src/web/shiny_app/www/",
  #                  file_name,
  #                   ".zip")
  zip_file <- paste0(file_name,".zip")
  write.csv(rows, csv_path)
  # write.xlsx(rows, xlsx_path)
  zip(zipfile = zip_file, files = csv_path,
      include_directories = FALSE,
  root="~/git/corelogic/src/web/shiny_app/www/")
  unlink(csv_path)
}

DBI::dbDisconnect(con)




