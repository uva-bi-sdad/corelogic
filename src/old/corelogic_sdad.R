library(data.table)
library(magrittr)
library(RPostgreSQL)
source("db/src/db_connection.R")

tax_hist_1_cols <- fread("/project/biocomplexity/sdad/projects-active/usda/bb/original/corelogic/corelogic_sdad/tax_hist_1_cols") %>% 
  colnames() %>% 
  make.names() %>% 
  gsub("\\.", "_", .) %>% 
  tolower() %>% paste0("\"", ., "\"", " varchar")

tax_hist_1_create <- paste0("CREATE TABLE tax_hist_1 (", paste(tax_hist_1_cols, collapse = ","),")")

tax_hist_2_cols <- fread("/project/biocomplexity/sdad/projects-active/usda/bb/original/corelogic/corelogic_sdad/tax_hist_2_cols") %>% 
  colnames() %>% 
  make.names() %>% 
  gsub("\\.", "_", .) %>% 
  tolower() %>% paste0("\"", ., "\"", " varchar")

tax_hist_2_create <- paste0("CREATE TABLE tax_hist_2 (", paste(tax_hist_2_cols, collapse = ","),")")

con <- get_db_conn()
dbSendQuery(con, "drop table tax_hist_1")
dbSendQuery(con, tax_hist_1_create)
dbSendQuery(con, "drop table tax_hist_2")
dbSendQuery(con, tax_hist_2_create)
DBI::dbDisconnect(con)


tax_hist_1_10mil <- fread("/project/biocomplexity/sdad/projects-active/usda/bb/original/corelogic/corelogic_sdad/tax_hist_1_10mil.txt", sep="|")
