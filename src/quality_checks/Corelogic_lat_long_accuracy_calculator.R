library(tibble)
library(DT)
library(dplyr)
library(tidygeocoder)
library(censusxy)
library(stringr)


get_db_conn <-
  function(db_name = "sdad",
           db_host = "postgis1",
           db_port = "5432",
           db_user = Sys.getenv("db_usr"), # requires you to setup environmental vars (above)
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

#STEP 1, GET 1100 RANDOM POINTS OF DATA
random_addresses2 <- DBI::dbGetQuery(con, statement = paste(
  "SELECT * FROM corelogic_usda.broadband_variables_tax_2020_06_27_unq_prog WHERE property_centroid_longitude IS NOT NULL AND property_centroid_latitude IS NOT NULL ORDER BY RANDOM() LIMIT 1100;"))


random_addresses <- DBI::dbGetQuery(con, statement = paste(
  "SELECT * FROM corelogic_usda.broadband_variables_tax_2020_06_27_unq_prog WHERE property_centroid_longitude IS NOT NULL AND property_centroid_latitude IS NOT NULL ORDER BY RANDOM() LIMIT 1100;"))


#STEP 2, MERGE WITH TABLE THAT HAS SITUS INFORMATION

for (row in 1:nrow(random_addresses)) {
  
  retrieved_row <- DBI::dbGetQuery(con, statement = paste0( 
    "select * from  corelogic_usda.corelogic_usda_current_tax_2020_06_27_addr where p_id_iris_frmtd ='",random_addresses[row,"p_id_iris_frmtd"],"'AND geoid_cnty='",random_addresses[row,"geoid_cnty"],"';"))
  
  random_addresses[row,"situs_house_number"]<-retrieved_row['situs_house_number']
  random_addresses[row,"situs_street_name"]<-retrieved_row['situs_street_name']
  random_addresses[row,"situs_unit_number"]<-retrieved_row['situs_unit_number']
  random_addresses[row,"situs_direction"]<-retrieved_row['situs_direction']
  random_addresses[row,"situs_mode"]<-retrieved_row['situs_mode']
  random_addresses[row,"situs_quadrant"]<-retrieved_row['situs_quadrant']
  random_addresses[row,"situs_city"]<-retrieved_row['situs_city']
  random_addresses[row,"situs_state"]<-retrieved_row['situs_state']
  random_addresses[row,"situs_zip_code"]<-retrieved_row['situs_zip_code']
  
}

#STEP 3, GENERATE SITUS ADDRESS FIELDS

for (row in 1:nrow(random_addresses)){
  dummystring<-''
  if(!(is.na(random_addresses[row,"situs_house_number"]) || random_addresses[row,"situs_house_number"]=='')){
    print(random_addresses[row,"situs_house_number"])
    dummystring<-paste(dummystring,random_addresses[row,"situs_house_number"],sep=" ",collapse = NULL)
  }
  if(!(is.na(random_addresses[row,"situs_street_name"]) || random_addresses[row,"situs_street_name"]=='')){
    dummystring<-paste(dummystring,random_addresses[row,"situs_street_name"],sep=" ",collapse = NULL)
  }
  if(!(is.na(random_addresses[row,"situs_mode"]) || random_addresses[row,"situs_mode"]=='')){
    dummystring<-paste(dummystring,random_addresses[row,"situs_mode"],sep=" ",collapse = NULL)
  }
  if(!(is.na(random_addresses[row,"situs_quadrant"]) || random_addresses[row,"situs_quadrant"]=='')){
    dummystring<-paste(dummystring,random_addresses[row,"situs_quadrant"],sep=" ",collapse = NULL)
  }
  if(!(is.na(random_addresses[row,"situs_direction"]) || random_addresses[row,"situs_direction"]=='')){
    dummystring<-paste(dummystring,random_addresses[row,"situs_direction"],sep=" ",collapse = NULL)
  }
#AT THIS POINT WE SHOULD HAVE THE STREET ADDRESS CORRECTLY FORMATTED
  
  random_addresses[row,"situs_street_address"]<-dummystring
  
  if(!(is.na(random_addresses[row,"situs_city"]) || random_addresses[row,"situs_city"]=='')){
    dummystring<-paste(dummystring,random_addresses[row,"situs_city"],sep=" ",collapse = NULL)
  }
  if(!(is.na(random_addresses[row,"situs_state"]) || random_addresses[row,"situs_state"]=='')){
    dummystring<-paste(dummystring,random_addresses[row,"situs_state"],sep=" ",collapse = NULL)
  }
  if(!(is.na(random_addresses[row,"situs_zip_code"]) || random_addresses[row,"situs_zip_code"]=='')){
    dummystring<-paste(dummystring,random_addresses[row,"situs_zip_code"],sep=" ",collapse = NULL)
  }
  #AT THIS POINT WE SHOULD HAVE THE FULL ADDRESS CORRECTLY FORMATTED
  random_addresses[row,"situs_address"]<-dummystring
  print(dummystring)
}


#GET LAT AND LONG FROM SITUS ADDRESS
result<-geo(address = random_addresses$situs_address, method = 'census', 
             lat = situs_latitude, long = situs_longitude)


#USE CENSUSXY TO GET THE GEO BLOCK ID FOR SITUS LAT/LONG
for (row in 1:nrow(result)) {
  
  val<- cxy_geography(lon=result[row,"situs_longitude"],lat=result[row,"situs_latitude"],benchmark='Public_AR_ACS2019',vintage='ACS2018_ACS2019')
  if(!is.null(val)){
    result[row,"census_block_calculated"]<-val['X2010.Census.Blocks.GEOID']
  }
}

#MERGE THE RESULTS IN WITH THE ORIGINAL RANDOM ADDRESSES (FAILS)
colnames(result)
names(result)[names(result) == "address"] <- "situs_address"
colnames(result)
result_merge <- merge(random_addresses, result, by=c("situs_address"))

result_merge<-random_addresses %>%filter(nchar(situs_address) > 5) %>%
  mutate(situs_address = stringr::str_trim(as.character(situs_address), "both")) %>%
  left_join(result %>% transmute(situs_address, census_block_calculated) %>% filter(nchar(situs_address) > 5), by = "situs_address")

  #left_join(result%>% transmute(situs_address,census_block_calculated), by = "situs_address")



#FILTER OUT NA VALUES

filtered_result<-result[!is.na(result$census_block_calculated),]
nrow(filtered_result)

#TRIM WHITESPACE
filtered_result<-filtered_result %>%
  mutate_if(is.character, str_trim)

random_addresses<-random_addresses %>%
  mutate_if(is.character, str_trim)

filtered_result_merge <- merge(random_addresses, filtered_result, by=c("situs_address"))

#MERGE THE RESULTS IN WITH THE ORIGINAL RANDOM ADDRESSES
nrow(result_merge)

result_merge<-result_merge[!is.na(result_merge$geoid_blk),]
result_merge<-result_merge[!is.na(result_merge$census_block_calculated),]

#ASSIGN SCORES FOR MATCHES
for (row in 1:nrow(result_merge)) {
  
  if(identical(result_merge[row,"census_block_calculated"],result_merge[row,"geoid_blk"])){
    result_merge[row,"score"]<-1
  }
  else{
    result_merge[row,"score"]<-0
  }  
  
}

#CALCULATE MATCH PERCENTAGE
matches<-nrow(result_merge[result_merge$score == 1,])
total<-nrow(result_merge)

percentage<-100*(matches/total)

percentage
