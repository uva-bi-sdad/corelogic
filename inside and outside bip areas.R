source("R/functions.R")
con <- get_db_conn(db_host = "localhost", db_port = "5434")
bronx_test_geom <- sf::st_read(con, c("public", "bronx_test_geom"), geometry_column = "geom")
dbDisconnect(con)

sf1 <- sf::st_as_sf(bronx_test_geom, sf_column_name = "geom")

con <- get_db_conn(db_host = "localhost", db_port = "5434")
bronx_neigh_geom <- sf::st_read(con, query = "select * from public.nyc_neighborhoods", geometry_column = "geom")
dbDisconnect(con)

plot(st_geometry(bronx_neigh_geom), axes = TRUE)
plot(st_geometry(bronx_test_geom), pch = 3, col = 'red', add = TRUE)

library(sf)
demo(nc, ask = FALSE, echo = FALSE)
plot(st_geometry(nc))
plot(st_geometry(nc), col = sf.colors(12, categorical = TRUE), border = 'grey',
     axes = TRUE)
plot(st_geometry(st_centroid(nc)), pch = 3, col = 'red', add = TRUE)


con <- get_db_conn(db_host = "localhost", db_port = "5434")
nyc_manahttan_homicides_pt <- sf::st_read(con, c("public", "nyc_manahttan_homicides"), geometry_column = "geom")
dbDisconnect(con)

con <- get_db_conn(db_host = "localhost", db_port = "5434")
nyc_homicides_pt <- sf::st_read(con, c("public", "nyc_homicides"), geometry_column = "geom")
dbDisconnect(con)

con <- get_db_conn(db_host = "localhost", db_port = "5434")
nyc_manhattanbronx_poly <- sf::st_read(con, c("public", "nyc_manhattanbronx"), geometry_column = "geom")
dbDisconnect(con)

con <- get_db_conn(db_host = "localhost", db_port = "5434")
nyc_neighborhoods_poly <- sf::st_read(con, c("public", "nyc_neighborhoods"), geometry_column = "geom")
dbDisconnect(con)

con <- get_db_conn(db_host = "localhost", db_port = "5434")
nyc_manahttan_homicides_near_bronx <- sf::st_read(con, c("public", "nyc_manahttan_homicides_near_bronx"))
dbDisconnect(con)

con <- get_db_conn(db_host = "localhost", db_port = "5434")
nyc_homicides_near_bronx <- sf::st_read(con, c("public", "nyc_homicides_near_bronx"))
dbDisconnect(con)

con <- get_db_conn(db_host = "localhost", db_port = "5434")
nyc_homicides_near_neighborhoods <- sf::st_read(con, c("public", "nyc_homocides_near_neighborhoods"))
dbDisconnect(con)



plot(st_geometry(nyc_neighborhoods_poly))
# plot(st_geometry(nyc_manahttan_homicides_pt), pch = 3, col = "red", add = TRUE)

plot(
  nyc_homicides_pt[nyc_homicides_pt$gid %in% nyc_homicides_near_bronx[nyc_homicides_near_bronx$distance_meters != 0 & nyc_homicides_near_bronx$poly == 4 & nyc_homicides_near_bronx$dwithin == TRUE, c("pt")],],
  pch = 5, col = "blue", add = TRUE)

plot(st_geometry(nyc_neighborhoods_poly[nyc_neighborhoods_poly$gid == 4,]), col = "yellow", add = TRUE)

plot(st_geometry(nyc_manahttan_homicides_pt[nyc_manahttan_homicides_pt$gid == 2,]), pch = 5, col = "blue", add = TRUE)
plot(st_geometry(nyc_manhattanbronx_poly[nyc_manhattanbronx_poly$gid == 11,]), col = "yellow", add = TRUE)

nyc_homicides_near_neighborhoods[nyc_homicides_near_neighborhoods$poly_id == 4, c("pt_id")]
nyc_homicides_pt[nyc_homicides_pt$gid %in% nyc_homicides_near_neighborhoods[nyc_homicides_near_neighborhoods$poly_id == 4, c("pt_id")],]

plot(st_geometry(nyc_neighborhoods_poly))
plot(st_geometry(nyc_neighborhoods_poly[nyc_neighborhoods_poly$gid == 4,]), col = "yellow", add = TRUE)
plot(st_geometry(nyc_homicides_pt[nyc_homicides_pt$gid %in% nyc_homicides_near_neighborhoods[nyc_homicides_near_neighborhoods$poly_id == 4, c("pt_id")],]), col = "red", add = TRUE)

nyc_homocides_near_neighborhoods



con <- get_db_conn(db_host = "localhost", db_port = "5434")
cc_program_areas <- sf::st_read(con, c("usda_bb", "cc_program_areas"))
dbDisconnect(con)

con <- get_db_conn(db_host = "localhost", db_port = "5434")
cc_program_areas_2 <- sf::st_read(con, c("usda_bb", "cc_program_areas_2"))
dbDisconnect(con)

con <- get_db_conn(db_host = "localhost", db_port = "5434")
wv_test_locs <- sf::st_read(con, c("corelogic_usda", "wv_test_locs"))
dbDisconnect(con)

con <- get_db_conn(db_host = "localhost", db_port = "5434")
wv_test_locs_4326 <- sf::st_read(con, c("corelogic_usda", "wv_test_locs_4326"))
dbDisconnect(con)

con <- get_db_conn(db_host = "localhost", db_port = "5434")
wv_test_2 <- sf::st_read(con, c("corelogic_usda", "wv_test_2"))
dbDisconnect(con)

states <- tigris::states(cb = TRUE)
WV <- states[states$STATEFP == "54",]

wv_test_2_by_loc <- dplyr::inner_join(wv_test_2, wv_test_locs_4326, by = c("geoid_cnty", "p_id_iris_frmtd"))
wv_test_2_by_loc_dist_not0 <- wv_test_2_by_loc[wv_test_2_by_loc$distance_meters != 0,]
wv_test_2_by_loc_dist0 <- wv_test_2_by_loc[wv_test_2_by_loc$distance_meters == 0,]

plot(st_transform(st_geometry(WV), 26918))
plot(st_geometry(cc_program_areas_2[cc_program_areas$STATE == "WV",]), col = "green", add = TRUE)
plot(st_geometry(wv_test_2_by_loc_dist0), pch = 3, cex = .1, col = "blue", add = TRUE)
plot(st_geometry(wv_test_2_by_loc_dist_not0), pch = 3, cex = .1, col = "red", add = TRUE)


states <- tigris::states(cb = TRUE)
WV <- states[states$STATEFP == "54",]
plot(st_transform(st_geometry(WV), 26918))


