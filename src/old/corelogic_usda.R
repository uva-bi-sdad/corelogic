library(data.table)
library(magrittr)
library(RPostgreSQL)
source("db/src/db_connection.R")

deed_cols <- fread("/project/biocomplexity/sdad/projects-active/usda/bb/original/corelogic/corelogic_usda/deed/corelogic-USDA_Deed_cols.txt") %>% 
  colnames() %>% 
  make.names() %>% 
  gsub("\\.", "_", .) %>% 
  tolower() %>% paste0("\"", ., "\"", " varchar")

for (y in c("2005","2006","2007","2008","2009","2010","2011","2012","2013","2014","2015")) {
  deed_cols_create <- paste0("CREATE TABLE usda_deed_", y," (", paste(deed_cols, collapse = ","),")")
  con <- get_db_conn()
  dbSendQuery(con, deed_cols_create)
  DBI::dbDisconnect(con)
}

"\copy usda_deed_2015 from /project/biocomplexity/sdad/projects-active/usda/bb/original/corelogic/corelogic_usda/deed/corelogic-USDA_Deed_2015.csv WITH (FORMAT 'csv', DELIMITER E'\|', QUOTE E'\"', HEADER);"

# select columns
'cut -d "|" -f 1-145 UVA_300000123123966_TaxHist01_Delivery_20190827.txt > ../../../UVA_300000123123966_TaxHist01_Delivery_20190827_145cols.txt'
# remove non-ascii
"tr -cd '\11\12\15\40-\176' < UVA_300000123123966_TaxHist01_Delivery_20190827_145cols.txt > UVA_300000123123966_TaxHist01_Delivery_20190827_145cols_ascii.txt"
# validate number of delimiters
"tr -cd '|\n' < UVA_300000123123966_TaxHist01_Delivery_20190827_145cols_ascii.txt | awk 'length!=144 {print NR}' > wrong_number_pipes.txt"
# upload NO QUOTE
"\copy corelogic_sdad.tax_hist_01 from /project/biocomplexity/sdad/projects_data/UVA_300000123123966_TaxHist01_Delivery_20190827_145cols_ascii.txt WITH (FORMAT 'csv', DELIMITER E'\|', QUOTE E'\b', HEADER);"


tax_cols <- fread("/project/biocomplexity/sdad/projects-active/usda/bb/original/corelogic/corelogic_usda/tax/TaxHistory.Tax_History_cols.txt") %>% 
  colnames() %>% 
  make.names() %>% 
  gsub("\\.", "_", .) %>% 
  tolower() %>% paste0("\"", ., "\"", " varchar")

for (y in c("08","09","10")) {
  deed_cols_create <- paste0("CREATE TABLE usda_tax_history_", y," (", paste(tax_cols, collapse = ","),")")
  con <- get_db_conn()
  dbSendQuery(con, deed_cols_create)
  DBI::dbDisconnect(con)
}


state8_deed_cols <- fread("/project/biocomplexity/sdad/projects-active/usda/bb/original/corelogic/8state/8State_Deed_Cols.txt", colClasses = "character") %>% 
  colnames() %>% 
  gsub("\\`", "", .) %>%
  make.names() %>% 
  gsub("\\.", "_", .) %>% 
  tolower() %>% paste0("\"", ., "\"", " varchar")

state8_deed_cols_create <- paste0("CREATE TABLE state8_deed (", paste(state8_deed_cols, collapse = ","),")")
con <- get_db_conn()
dbSendQuery(con, state8_deed_cols_create)
DBI::dbDisconnect(con)


state8_tax_cols <- fread("/project/biocomplexity/sdad/projects-active/usda/bb/original/corelogic/8state/8State_Tax_Cols.txt", colClasses = "character") %>% 
  colnames() %>% 
  gsub("\\`", "", .) %>%
  make.names() %>% 
  gsub("\\.", "_", .) %>% 
  tolower() %>% paste0("\"", ., "\"", " varchar")

state8_tax_cols_create <- paste0("CREATE TABLE state8_tax (", paste(state8_tax_cols, collapse = ","),")")
con <- get_db_conn()
dbSendQuery(con, state8_tax_cols_create)
DBI::dbDisconnect(con)


"\copy state8_deed from /project/biocomplexity/sdad/projects-active/usda/bb/original/corelogic/8state/8State_Deed.txt WITH (FORMAT 'csv', DELIMITER E'\|', QUOTE '`', HEADER);"
"\copy state8_tax from /project/biocomplexity/sdad/projects-active/usda/bb/original/corelogic/8state/8State_Tax_10.txt WITH (FORMAT 'csv', DELIMITER E'\|', QUOTE '`', HEADER);"


sql <- paste0("CREATE INDEX corelogic_sdad_tax_hist_1", f,"_fips_trgm_idx ON corelogic_usda.usda_deed_2006 USING GIST (fips gist_trgm_ops);")




library("maps")
library("stringr")

state_fips <- state.fips$fips %>% unique() %>% 
  str_pad(2, pad = "0")

for (f in state_fips[6:49]) {
  sql <- paste0("select * into corelogic_sdad.tax_hist_2_", f," from corelogic_sdad.tax_hist_2 where fips_code like '", f, "%';")
  con <- get_db_conn()
  dbExecute(con, sql)
  dbDisconnect(con)
}



tax_hist_01_cols <- fread("/project/biocomplexity/sdad/projects_data/volume_nyc1_03/Biocomplexity-CoreLogic/05092019_Corelogic_Data_Delivery/UVA_300000123123966_TaxHist01_Delivery_20190827.txt", nrows = 1) %>% colnames() %>% 
  gsub("\\`", "", .) %>%
  make.names() %>% 
  gsub("\\.", "_", .) %>% 
  tolower() %>% 
  paste0("\"", ., "\"", " varchar")


tax_hist_01_cols <- tax_hist_01_cols[1:(length(tax_hist_01_cols)-3)]
tax_hist_01_cols_create <- paste0("CREATE TABLE tax_hist_01 (", paste(TaxHist01_cols, collapse = ","),")")

for (i in c("01","02","03","04","05","06","07","08","09","10")) {
  sql <- paste0("CREATE TABLE corelogic_sdad.tax_hist_", i, " (", paste(tax_hist_01_cols, collapse = ","),")")
  con <- get_db_conn()
  dbExecute(con, sql)
  dbDisconnect(con)
}

print(Sys.time())
reaadtest <- fread("/project/biocomplexity/sdad/projects_data/volume_nyc1_03/Biocomplexity-CoreLogic/05092019_Corelogic_Data_Delivery/UVA_300000123123966_TaxHist01_Delivery_20190827.txt")
print(Sys.time())



