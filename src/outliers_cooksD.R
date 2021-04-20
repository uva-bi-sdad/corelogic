
res <- data.table::fread("data/or_sf_bed_bath.csv")
res <- res[(appr_baths > 0 & !is.na(appr_baths)) & (bedrooms > 0 & !is.na(bedrooms)),]

#fit the linear regression model to the dataset with outliers
model <- lm(appr_baths+bedrooms ~ living_sq_ft, data = res)

#find Cook's distance for each observation in the dataset
cooksD <- cooks.distance(model)

#identify influential points
influential_obs <- as.numeric(names(cooksD)[(cooksD > (5/(n-1)))])

res[influential_obs,]


source("R/functions.R")
con <- get_db_conn(db_host = "localhost", db_port = "5434")
blkknt_asmt <- dbGetQuery(con, "select * from blackknight.blkknt_asmt")
dbDisconnect(con)

con <- get_db_conn(db_host = "localhost", db_port = "5434")
blkknt_vre <- dbGetQuery(con, "select * from blackknight.blkknt_vre")
dbDisconnect(con)

blkknt_vre_w_bath_bed_sqft <- blkknt_vre[!is.na(blkknt_vre$int_baths_total) & !is.na(blkknt_vre$int_bedrooms_total) & !is.na(blkknt_vre$int_sqft_living), c("int_baths_total", "int_bedrooms_total", "int_sqft_living")]

model <- lm(int_baths_total+int_bedrooms_total ~ int_sqft_living, data = blkknt_vre_w_bath_bed_sqft)
#find Cook's distance for each observation in the dataset
cooksD <- cooks.distance(model)
#identify influential points
influential_obs <- as.numeric(names(cooksD)[(cooksD > (10/(2053)))])

blkknt_vre_w_bath_bed_sqft[influential_obs, c("int_baths_total", "int_bedrooms_total", "int_sqft_living")]


