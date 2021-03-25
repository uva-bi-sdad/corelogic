
res <- data.table::fread("data/or_sf_bed_bath.csv")
res <- res[(appr_baths > 0 & !is.na(appr_baths)) & (bedrooms > 0 & !is.na(bedrooms)),]

#fit the linear regression model to the dataset with outliers
model <- lm(appr_baths+bedrooms ~ living_sq_ft, data = res)

#find Cook's distance for each observation in the dataset
cooksD <- cooks.distance(model)

#identify influential points
influential_obs <- as.numeric(names(cooksD)[(cooksD > (5/(n-1)))])

res[influential_obs,]
