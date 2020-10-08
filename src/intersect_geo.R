# LOAD LIBRARIES
library(sf)
library(RPostgreSQL)
library(data.table)
#library(vroom)

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

# LOAD FUNCTIONS
functions <- list.files("src/functions/", full.names = TRUE)
for (f in functions) source(f)

counties_us <- tigris::counties() %>%
  sf::st_transform(4326)

state_fips_codes <- tigris::fips_codes
state_abbrev <- "VA"
state_fp <- state_fips_codes[state_fips_codes$state == state_abbrev, "state_code"][1]

map_program_area_cc <- st_read("data/original/geo/CC 2013_2019_83 04272020.shp") %>%
  sf::st_transform(4326)
map_program_area_bip <- st_read("data/original/geo/200409_BIP_ServAr_ID.shp") %>%
  sf::st_transform(4326)
map_program_area_rc <- st_read("data/original/geo/ReConnect R1 594 PFSA 05012020.shp") %>%
  sf::st_transform(4326)
map_program_area_tcf <- st_read("data/original/geo/USDARD_RUS_TELCO_FARMBILL_06042020/USDARD_RUS_TELCO_FARMBILL_06042020.shp") %>%
  sf::st_transform(4326)
map_program_area_tci <- st_read("data/original/geo/USDARD_RUS_TELCO_INFRA_06042020/USDARD_RUS_TELCO_INFRA_06042020.shp") %>%
  sf::st_transform(4326)

# CC
counties_cc <- paste0("'", paste(unique(strsplit(paste(map_program_area_cc$FIPS, collapse = ", "), ", ")[[1]]), collapse = "','"), "'")

sql <- paste0("select geoid_cnty, p_id_iris_frmtd, geometry from corelogic_usda.broadband_variables_tax_2020_06_27_unq where property_centroid_longitude IS NOT NULL AND geoid_cnty IN (", counties_cc, ")")

con <- get_db_conn()
db_rows_cc <- st_read(con, query = sql)
DBI::dbDisconnect(con)

int <- sf::st_intersects(db_rows_cc, map_program_area_cc)
int2 <- as.integer(as.character(int))

db_rows_cc$program <- "CC"
db_rows_cc$rusid <- as.character(map_program_area_cc$RUSID[unlist(int2)])
db_rows_cc <- db_rows_cc[!is.na(db_rows_cc$rusid),]

# RC

# counties_rc_names <- as.data.table(unique(strsplit(paste(map_program_area_rc$Counties_S, collapse = ", "), ", ")[[1]]))

# mrg <- merge(counties_rc_names, counties_us, by.x = "V1", by.y = "NAMELSAD")

int <- sf::st_intersects(map_program_area_rc, counties_us)

cnty_ints <- data.table(rc_rownum = numeric(), cntys_rownum = numeric(), geoid = character())
for (i in 1:length(int)) {
  u <- unlist(int[i])
  for (j in 1:length(int[[i]])) {
    geoid <- counties_us[u[j],]$GEOID
    newrow <- data.table(rc_rownum = i, cntys_rownum = u[j], geoid)
    cnty_ints <- rbindlist(list(cnty_ints, newrow))
    #print(paste(i, u[j]))
  }
}

cnty_ints_geoid <- cnty_ints[, .(geoid_cntys = paste(geoid, collapse = ", ")), rc_rownum]
map_program_area_rc$geoid_cnty <- ""

for (i in 1:nrow(cnty_ints_geoid)) {
  map_program_area_rc[cnty_ints_geoid[i,]$rc_rownum,]$geoid_cnty <- cnty_ints_geoid[i,]$geoid_cntys
}

geoid_cnty_unq <- unique(strsplit(paste(map_program_area_rc$geoid_cnty, collapse = ", "), ", ")[[1]])
geoid_cnty_unq <- geoid_cnty_unq[geoid_cnty_unq != ""]
counties_rc <- paste0("'", paste(geoid_cnty_unq, collapse = "','"), "'")


sql <- paste0("select geoid_cnty, p_id_iris_frmtd, geometry from corelogic_usda.broadband_variables_tax_2020_06_27_unq where property_centroid_longitude IS NOT NULL AND geoid_cnty IN (", counties_rc, ")")

#int2 <- as.integer(as.character(int))
#map_program_area_rc$geoid_cnty <- as.character(counties_us$GEOID[unlist(int2)])

con <- get_db_conn()
db_rows_rc <- st_read(con, query = sql)
DBI::dbDisconnect(con)

int <- sf::st_intersects(db_rows_rc, map_program_area_rc)
int2 <- as.integer(as.character(int))

db_rows_rc$program <- "RC"
db_rows_rc$rusid <- as.character(map_program_area_rc$RUS_ID[unlist(int2)])
db_rows_rc <- db_rows_rc[!is.na(db_rows_rc$rusid),]


# BIP

int <- sf::st_intersects(map_program_area_bip, counties_us)

cnty_ints <- data.table(rc_rownum = numeric(), cntys_rownum = numeric(), geoid = character())
for (i in 1:length(int)) {
  u <- unlist(int[i])
  for (j in 1:length(int[[i]])) {
    geoid <- counties_us[u[j],]$GEOID
    newrow <- data.table(rc_rownum = i, cntys_rownum = u[j], geoid)
    cnty_ints <- rbindlist(list(cnty_ints, newrow))
    #print(paste(i, u[j]))
  }
}

cnty_ints_geoid <- cnty_ints[, .(geoid_cntys = paste(geoid, collapse = ", ")), rc_rownum]
map_program_area_bip$geoid_cnty <- ""

for (i in 1:nrow(cnty_ints_geoid)) {
  map_program_area_bip[cnty_ints_geoid[i,]$rc_rownum,]$geoid_cnty <- cnty_ints_geoid[i,]$geoid_cntys
}

geoid_cnty_unq <- unique(strsplit(paste(map_program_area_bip$geoid_cnty, collapse = ", "), ", ")[[1]])
geoid_cnty_unq <- geoid_cnty_unq[geoid_cnty_unq != ""]
counties_bip <- paste0("'", paste(geoid_cnty_unq, collapse = "','"), "'")


sql <- paste0("select geoid_cnty, p_id_iris_frmtd, geometry from corelogic_usda.broadband_variables_tax_2020_06_27_unq where property_centroid_longitude IS NOT NULL AND geoid_cnty IN (", counties_bip, ")")

#int2 <- as.integer(as.character(int))
#map_program_area_bip$geoid_cnty <- as.character(counties_us$GEOID[unlist(int2)])

con <- get_db_conn()
db_rows_bip <- st_read(con, query = sql)
DBI::dbDisconnect(con)

int <- sf::st_intersects(db_rows_bip, map_program_area_bip)
int2 <- as.integer(as.character(int))

db_rows_bip$program <- "BIP"
db_rows_bip$rusid <- as.character(map_program_area_bip$RUS_ID[unlist(int2)])
db_rows_bip <- db_rows_bip[!is.na(db_rows_bip$rusid),]


# TCF

int <- sf::st_intersects(map_program_area_tcf, counties_us)

cnty_ints <- data.table(rc_rownum = numeric(), cntys_rownum = numeric(), geoid = character())
for (i in 1:length(int)) {
  u <- unlist(int[i])
  for (j in 1:length(int[[i]])) {
    geoid <- counties_us[u[j],]$GEOID
    newrow <- data.table(rc_rownum = i, cntys_rownum = u[j], geoid)
    cnty_ints <- rbindlist(list(cnty_ints, newrow))
    #print(paste(i, u[j]))
  }
}

cnty_ints_geoid <- cnty_ints[, .(geoid_cntys = paste(geoid, collapse = ", ")), rc_rownum]
map_program_area_tcf$geoid_cnty <- ""

for (i in 1:nrow(cnty_ints_geoid)) {
  map_program_area_tcf[cnty_ints_geoid[i,]$rc_rownum,]$geoid_cnty <- cnty_ints_geoid[i,]$geoid_cntys
}

geoid_cnty_unq <- unique(strsplit(paste(map_program_area_tcf$geoid_cnty, collapse = ", "), ", ")[[1]])
geoid_cnty_unq <- geoid_cnty_unq[geoid_cnty_unq != ""]
counties_tcf <- paste0("'", paste(geoid_cnty_unq, collapse = "','"), "'")


sql <- paste0("select geoid_cnty, p_id_iris_frmtd, geometry from corelogic_usda.broadband_variables_tax_2020_06_27_unq where property_centroid_longitude IS NOT NULL AND geoid_cnty IN (", counties_tcf, ")")

#int2 <- as.integer(as.character(int))
#map_program_area_tcf$geoid_cnty <- as.character(counties_us$GEOID[unlist(int2)])

con <- get_db_conn()
db_rows_tcf <- st_read(con, query = sql)
DBI::dbDisconnect(con)

int <- sf::st_intersects(db_rows_tcf, map_program_area_tcf)
int2 <- as.integer(as.character(int))

db_rows_tcf$program <- "TCF"
db_rows_tcf$rusid <- as.character(map_program_area_tcf$RUS_ID[unlist(int2)])
db_rows_tcf <- db_rows_tcf[!is.na(db_rows_tcf$rusid),]


# TCI

int <- sf::st_intersects(map_program_area_tci, counties_us)

cnty_ints <- data.table(rc_rownum = numeric(), cntys_rownum = numeric(), geoid = character())
for (i in 1:length(int)) {
  u <- unlist(int[i])
  for (j in 1:length(int[[i]])) {
    geoid <- counties_us[u[j],]$GEOID
    newrow <- data.table(rc_rownum = i, cntys_rownum = u[j], geoid)
    cnty_ints <- rbindlist(list(cnty_ints, newrow))
    #print(paste(i, u[j]))
  }
}

cnty_ints_geoid <- cnty_ints[, .(geoid_cntys = paste(geoid, collapse = ", ")), rc_rownum]
map_program_area_tci$geoid_cnty <- ""

for (i in 1:nrow(cnty_ints_geoid)) {
  map_program_area_tci[cnty_ints_geoid[i,]$rc_rownum,]$geoid_cnty <- cnty_ints_geoid[i,]$geoid_cntys
}

geoid_cnty_unq <- unique(strsplit(paste(map_program_area_tci$geoid_cnty, collapse = ", "), ", ")[[1]])
geoid_cnty_unq <- geoid_cnty_unq[geoid_cnty_unq != ""]
counties_tci <- paste0("'", paste(geoid_cnty_unq, collapse = "','"), "'")


sql <- paste0("select geoid_cnty, p_id_iris_frmtd, geometry from corelogic_usda.broadband_variables_tax_2020_06_27_unq where property_centroid_longitude IS NOT NULL AND geoid_cnty IN (", counties_tci, ")")

#int2 <- as.integer(as.character(int))
#map_program_area_tci$geoid_cnty <- as.character(counties_us$GEOID[unlist(int2)])

con <- get_db_conn()
db_rows_tci <- st_read(con, query = sql)
DBI::dbDisconnect(con)

int <- sf::st_intersects(db_rows_tci, map_program_area_tci)
int2 <- as.integer(as.character(int))

db_rows_tci$program <- "TCI"
db_rows_tci$rusid <- as.character(map_program_area_tci$RUSID[unlist(int2)])
db_rows_tci <- db_rows_tci[!is.na(db_rows_tci$rusid),]


# COMBINE
combn <- rbindlist(list(db_rows_cc, db_rows_rc, db_rows_bip, db_rows_tcf, db_rows_tci))

combn_cast <- dcast(combn, geoid_cnty + p_id_iris_frmtd ~ program, value.var = "rusid")


saveRDS(combn_cast, paste0("data/working/sales_in_program_areas.RDS"))

con <- get_db_conn()
dbWriteTable(con, c("corelogic_usda", "sales_in_program_areas"), combn_cast, overwrite = TRUE, row.names = FALSE)
DBI::dbDisconnect(con)



# Census Blocks
get_blocks <- function(geoid_st = "51") {
  sql <- paste0("select geoid_cnty, p_id_iris_frmtd, geometry
               from corelogic_usda.broadband_variables_tax_2020_06_27_unq_prog
               where property_centroid_longitude IS NOT NULL AND geoid_cnty LIKE '", geoid_st,"%'")
  con <- get_db_conn()
  print(paste("getting", geoid_st, "rows"))
  db_rows_blk <- st_read(con, query = sql)
  DBI::dbDisconnect(con)
  blk_map_path <- paste0("/home/ads7fg/sdad/projects_data/usda/bb/original/censusblocks/blocks_TIGER2018_sf_RDS/tl_2018_", geoid_st, "_tabblock10.RDS")
  print(paste("getting", geoid_st, "blocks"))
  blk_map <- readRDS(blk_map_path) %>%
    sf::st_transform(4326)
  print(paste("getting", geoid_st, "interesection"))
  int <- sf::st_intersects(db_rows_blk, blk_map)
  int2 <- as.integer(as.character(int))
  db_rows_blk$geoid_blk <- as.character(blk_map$GEOID10[unlist(int2)])
  print(paste("saving", geoid_st, "results"))
  file_path <- paste0("data/working/sales_with_blk_", geoid_st, ".RDS")
  saveRDS(db_rows_blk, file_path)
  rm(blk_map)
}


geoids_st <- tigris::states()
geoids_st$geometry <- NULL
geoids_st <- geoids_st[!geoids_st$GEOID %in% c("78", "69", "60", "72", "12", "51", "54"), c("GEOID")]

library(doParallel)

cl <- makeForkCluster(6, outfile = "src/parlog")
doParallel::registerDoParallel(cl)

geoids_st_test <- geoids_st[21:49]
res <- foreach(i = 1:length(geoids_st_test)) %dopar% {
  get_blocks(geoids_st_test[i])
}

parallel::stopCluster(cl)


file_paths <- list.files("data/working/", pattern = "sales_with_blk*", full.names = TRUE)
con <- get_db_conn()
dat <- readRDS(file_paths[1])
sf::dbWriteTable(con, c("corelogic_usda", "sales_with_blk"), dat)
rm(dat)
DBI::dbDisconnect(con)

library(doParallel)
library(sf)
library(RPostgreSQL)
library(data.table)

cl <- makeForkCluster(6, outfile = "src/parlog")
doParallel::registerDoParallel(cl)

file_paths_2 <- file_paths[2:45]
res <- foreach(i = 1:length(file_paths_2)) %dopar% {
  con <- get_db_conn()
  print(paste("reading", file_paths_2[i]))
  dat <- readRDS(file_paths_2[i])
  print(paste("writing", file_paths_2[i]))
  sf::dbWriteTable(con, c("corelogic_usda", "sales_with_blk"), dat, append = TRUE)
  rm(dat)
  DBI::dbDisconnect(con)
}

parallel::stopCluster(cl)



