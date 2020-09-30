# LOAD LIBRARIES
library(sf)
library(RPostgreSQL)
library(data.table)
library(vroom)

# LOAD FUNCTIONS
functions <- list.files("src/functions/", full.names = TRUE)
for (f in functions) source(f)

state_fips_codes <- tigris::fips_codes
state_abbrev <- "VA"
state_fp <- state_fips_codes[state_fips_codes$state == state_abbrev, "state_code"][1]

sql <- paste0("select fips, pcl_id_iris_formatted, geometry from corelogic_usda.corelogic_usda_deed_2020_06_27_prop where fips like '", state_fp, "%'")

con <- get_db_conn()
db_rows <- st_read(con, query = sql)
DBI::dbDisconnect(con)

map <- tigris::blocks(state_abbrev) %>%
  sf::st_transform(4326)

map <- st_read("data/geo/RUS_CC_Shapefiles_April2020/CC 2013_2019_83 04272020.shp") %>%
  sf::st_transform(4326)

st_map <- tigris::counties(state = "VA") %>%
  sf::st_transform(4326)

plot(map[map$FIPS %like% "^51*",c("STATUS")])
plot(st_map, add = TRUE)

int <- sf::st_intersects(db_rows, map)
int2 <- as.integer(as.character(int))

db_rows$blockce <- as.character(map$GEOID10[unlist(int2)])

saveRDS(db_rows, paste0("data/cl_blocks/", state_abbrev, "_cl_blocks.RDS"))

map[map$FIPS %like% "^51*",c("STATUS")]


