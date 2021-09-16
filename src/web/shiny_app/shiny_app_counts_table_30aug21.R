library(RPostgreSQL)
library(maditr)

# connection to PG server
con <- dbConnect(PostgreSQL(), 
                 dbname = "sdad",
                 host = "postgis1", 
                 port = 5432, 
                 password = "password") #<-- enter password here

# arms-length sales/SFR (not cleaned)
q1 <- "SELECT geoid_cnty, sale_year, count(*) all_sales
       FROM   corelogic_usda.current_tax_200627_latest_all_add_vars_add_progs_geom_blk
       WHERE  property_indicator = '10'
       AND    transaction_type != '9'
       AND    sale_year IN (2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018)
       GROUP BY geoid_cnty, sale_year
       ORDER BY geoid_cnty, sale_year"

tab_all_sales <- dbGetQuery(con, q1)
all_sales <- dcast(tab_all_sales, geoid_cnty ~ sale_year, value.var = "all_sales")
saveRDS(all_sales, file = "~/R/BK/all-arms-length-sf-cl.rds")

# selection criteria
test_crt <- c("sale_date IS NOT NULL", 
              "sale_price IS NOT NULL")
crt <- factor(c("sale_date IS NOT NULL", 
         "sale_price IS NOT NULL",
         "(building_square_feet IS NOT NULL OR living_square_feet IS NOT NULL)",
         "(acres IS NOT NULL OR land_square_footage IS NOT NULL)",
         "(year_built IS NOT NULL OR effective_year_built IS NOT NULL)",
         "baths_appraised IS NOT NULL",
         "bedrooms IS NOT NULL",
         "(LENGTH(situs_address) > 2 OR (property_centroid_latitude IS NOT NULL
            AND property_centroid_longitude IS NOT NULL))"))

# unique combinations of the criteria

crta_9 = combn(crt, 7) # satisfy any of the 9 criteria
crta_8 = combn(crt, 6) # 8 criteria
crta_7 = combn(crt, 5) # 7 criteria

############################ ALL CRITERIA ####################################

q_all <- "SELECT geoid_cnty, sale_year, count(*) all_sales
       FROM   corelogic_usda.current_tax_200627_latest_all_add_vars_add_progs_geom_blk
       WHERE  property_indicator = '10'
       AND    transaction_type != '9'
       AND    sale_year IN (2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018)
       AND sale_date IS NOT NULL 
       AND sale_price IS NOT NULL
       AND (building_square_feet IS NOT NULL OR living_square_feet IS NOT NULL)
       AND (acres IS NOT NULL OR land_square_footage IS NOT NULL)
       AND (year_built IS NOT NULL OR effective_year_built IS NOT NULL)
       AND baths_appraised IS NOT NULL
       AND bedrooms IS NOT NULL
       AND (LENGTH(situs_address) > 2 OR (property_centroid_latitude IS NOT NULL
        AND property_centroid_longitude IS NOT NULL))
       GROUP BY geoid_cnty, sale_year
       ORDER BY geoid_cnty, sale_year"

tab <- dbGetQuery(con, q_all)
hor_tab <- dcast(tab, geoid_cnty ~ sale_year, value.var = "all_sales")
saveRDS(hor_tab, file = "~/R/BK/all-criteria-arms-length-sf-cl.rds")


mrg <- merge(all_sales, hor_tab, by = "geoid_cnty", all.x = TRUE)
mrg[is.na(mrg)] <- 0
mrg <- data.table(mrg)
mrg[, '2006' := paste0(`2006.x`, " (", round(100*(`2006.y`/`2006.x`), 2), "%)")]
mrg[, '2007' := paste0(`2007.x`, " (", round(100*(`2007.y`/`2007.x`), 2), "%)")]
mrg[, '2008' := paste0(`2008.x`, " (", round(100*(`2008.y`/`2008.x`), 2), "%)")]
mrg[, '2009' := paste0(`2009.x`, " (", round(100*(`2009.y`/`2009.x`), 2), "%)")]
mrg[, '2010' := paste0(`2010.x`, " (", round(100*(`2010.y`/`2010.x`), 2), "%)")]
mrg[, '2011' := paste0(`2011.x`, " (", round(100*(`2011.y`/`2011.x`), 2), "%)")]
mrg[, '2012' := paste0(`2012.x`, " (", round(100*(`2012.y`/`2012.x`), 2), "%)")]
mrg[, '2013' := paste0(`2013.x`, " (", round(100*(`2013.y`/`2013.x`), 2), "%)")]
mrg[, '2014' := paste0(`2014.x`, " (", round(100*(`2014.y`/`2014.x`), 2), "%)")]
mrg[, '2015' := paste0(`2015.x`, " (", round(100*(`2015.y`/`2015.x`), 2), "%)")]
mrg[, '2016' := paste0(`2016.x`, " (", round(100*(`2016.y`/`2016.x`), 2), "%)")]
mrg[, '2017' := paste0(`2017.x`, " (", round(100*(`2017.y`/`2017.x`), 2), "%)")]
mrg[, '2018' := paste0(`2018.x`, " (", round(100*(`2018.y`/`2018.x`), 2), "%)")]

fnl_all <- mrg[, .(geoid_cnty, `2006`, `2007`, `2008`, `2009`, `2010`, `2011`, `2012`, `2013`, `2014`, `2015`, `2016`, `2017`, `2018`)]
fnl_all <- data.table(fnl_all)

################################# 9 Criteria ################################
for (j in 1:dim(crta_9)[2]){
q <-paste0("SELECT geoid_cnty, sale_year, count(*) all_sales
FROM   corelogic_usda.current_tax_200627_latest_all_add_vars_add_progs_geom_blk
WHERE  property_indicator = '10'
AND    transaction_type != '9' 
AND sale_year IN (2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018)
            AND ", crta_9[1,j], 
           " AND ", crta_9[2,j],
           " AND ", crta_9[3,j],
           " AND ", crta_9[4,j],
           " AND ", crta_9[5,j],
           " AND ", crta_9[6,j],
           " AND ", crta_9[7,j],
" GROUP BY geoid_cnty, sale_year
ORDER BY geoid_cnty, sale_year")
print(q)

tab <- dbGetQuery(con, q)
hor_tab <- dcast(tab, geoid_cnty ~ sale_year, value.var = "all_sales")

mrg_nam <- paste("mrg_tab_", j, sep = "")

assign(mrg_nam, merge(all_sales, hor_tab, by = "geoid_cnty", all.x = TRUE))
}

mrg <- do.call("rbind", list(mrg_tab_1, mrg_tab_2, mrg_tab_3, 
                             mrg_tab_4, mrg_tab_5, mrg_tab_6,
                             mrg_tab_7, mrg_tab_8))
mrg[is.na(mrg)] <- 0
mrg <- mrg %>% group_by(geoid_cnty) %>% summarize_if(is.numeric, max)
mrg <- data.table(mrg)
mrg[, '2006' := paste0(`2006.y`, " (", round(100*(`2006.y`/`2006.x`), 2), "%)")]
mrg[, '2007' := paste0(`2007.y`, " (", round(100*(`2007.y`/`2007.x`), 2), "%)")]
mrg[, '2008' := paste0(`2008.y`, " (", round(100*(`2008.y`/`2008.x`), 2), "%)")]
mrg[, '2009' := paste0(`2009.y`, " (", round(100*(`2009.y`/`2009.x`), 2), "%)")]
mrg[, '2010' := paste0(`2010.y`, " (", round(100*(`2010.y`/`2010.x`), 2), "%)")]
mrg[, '2011' := paste0(`2011.y`, " (", round(100*(`2011.y`/`2011.x`), 2), "%)")]
mrg[, '2012' := paste0(`2012.y`, " (", round(100*(`2012.y`/`2012.x`), 2), "%)")]
mrg[, '2013' := paste0(`2013.y`, " (", round(100*(`2013.y`/`2013.x`), 2), "%)")]
mrg[, '2014' := paste0(`2014.y`, " (", round(100*(`2014.y`/`2014.x`), 2), "%)")]
mrg[, '2015' := paste0(`2015.y`, " (", round(100*(`2015.y`/`2015.x`), 2), "%)")]
mrg[, '2016' := paste0(`2016.y`, " (", round(100*(`2016.y`/`2016.x`), 2), "%)")]
mrg[, '2017' := paste0(`2017.y`, " (", round(100*(`2017.y`/`2017.x`), 2), "%)")]
mrg[, '2018' := paste0(`2018.y`, " (", round(100*(`2018.y`/`2018.x`), 2), "%)")]

fnl_9 <- mrg[, .(geoid_cnty, `2006`, `2007`, `2008`, `2009`, `2010`, `2011`, `2012`, `2013`, `2014`, `2015`, `2016`, `2017`, `2018`)]
fnl_9 <- data.table(fnl_9)
########################### 8 CRITERIA ################################
mrg_names <- list()
for (j in 1:dim(crta_8)[2]){
  q <-paste0("SELECT geoid_cnty, sale_year, count(*) all_sales
             FROM   corelogic_usda.current_tax_200627_latest_all_add_vars_add_progs_geom_blk
             WHERE  property_indicator = '10'
             AND    transaction_type != '9' 
             AND sale_year IN (2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018)
             AND ", crta_8[1,j], 
             " AND ", crta_8[2,j],
             " AND ", crta_8[3,j],
             " AND ", crta_8[4,j],
             " AND ", crta_8[5,j],
             " AND ", crta_8[6,j],
             " GROUP BY geoid_cnty, sale_year
             ORDER BY geoid_cnty, sale_year")
  print(q)
  
  tab <- dbGetQuery(con, q)
  hor_tab <- dcast(tab, geoid_cnty ~ sale_year, value.var = "all_sales")
  
  mrg_nam <- paste("mrg_tab_", j, sep = "")
  #mrg_names <- append(mrg_names, mrg_nam)
  assign(mrg_nam, merge(all_sales, hor_tab, by = "geoid_cnty", all.x = TRUE))
  mrg_names<- append(mrg_names, mrg_nam)
}

mrg_names <- list(mrg_tab_1, mrg_tab_2, mrg_tab_3, mrg_tab_4, mrg_tab_5,
                  mrg_tab_6, mrg_tab_7, mrg_tab_8, mrg_tab_9, mrg_tab_10,
                  mrg_tab_11, mrg_tab_12, mrg_tab_13, mrg_tab_14, mrg_tab_15,
                  mrg_tab_16, mrg_tab_17, mrg_tab_18, mrg_tab_19, mrg_tab_20,
                  mrg_tab_21, mrg_tab_22, mrg_tab_23, mrg_tab_24, mrg_tab_25,
                  mrg_tab_26, mrg_tab_27, mrg_tab_28)
mrg <- do.call("rbind", mrg_names)
mrg[is.na(mrg)] <- 0
mrg <- mrg %>% group_by(geoid_cnty) %>% summarize_if(is.numeric, max)
mrg <- data.table(mrg)
mrg[, '2006' := paste0(`2006.y`, " (", round(100*(`2006.y`/`2006.x`), 2), "%)")]
mrg[, '2007' := paste0(`2007.y`, " (", round(100*(`2007.y`/`2007.x`), 2), "%)")]
mrg[, '2008' := paste0(`2008.y`, " (", round(100*(`2008.y`/`2008.x`), 2), "%)")]
mrg[, '2009' := paste0(`2009.y`, " (", round(100*(`2009.y`/`2009.x`), 2), "%)")]
mrg[, '2010' := paste0(`2010.y`, " (", round(100*(`2010.y`/`2010.x`), 2), "%)")]
mrg[, '2011' := paste0(`2011.y`, " (", round(100*(`2011.y`/`2011.x`), 2), "%)")]
mrg[, '2012' := paste0(`2012.y`, " (", round(100*(`2012.y`/`2012.x`), 2), "%)")]
mrg[, '2013' := paste0(`2013.y`, " (", round(100*(`2013.y`/`2013.x`), 2), "%)")]
mrg[, '2014' := paste0(`2014.y`, " (", round(100*(`2014.y`/`2014.x`), 2), "%)")]
mrg[, '2015' := paste0(`2015.y`, " (", round(100*(`2015.y`/`2015.x`), 2), "%)")]
mrg[, '2016' := paste0(`2016.y`, " (", round(100*(`2016.y`/`2016.x`), 2), "%)")]
mrg[, '2017' := paste0(`2017.y`, " (", round(100*(`2017.y`/`2017.x`), 2), "%)")]
mrg[, '2018' := paste0(`2018.y`, " (", round(100*(`2018.y`/`2018.x`), 2), "%)")]

fnl_8 <- mrg[, .(geoid_cnty, `2006`, `2007`, `2008`, `2009`, `2010`, `2011`, `2012`, `2013`, `2014`, `2015`, `2016`, `2017`, `2018`)]
fnl_8 <- data.table(fnl_8)
########################### 7 CRITERIA ###############################
mrg_names <- list()
for (j in 1:dim(crta_7)[2]){
  q <-paste0("SELECT geoid_cnty, sale_year, count(*) all_sales
             FROM   corelogic_usda.current_tax_200627_latest_all_add_vars_add_progs_geom_blk
             WHERE  property_indicator = '10'
             AND    transaction_type != '9' 
             AND sale_year IN (2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018)
             AND ", crta_7[1,j], 
             " AND ", crta_7[2,j],
             " AND ", crta_7[3,j],
             " AND ", crta_7[4,j],
             " AND ", crta_7[5,j],
             " GROUP BY geoid_cnty, sale_year
             ORDER BY geoid_cnty, sale_year")
  print(q)
  
  tab <- dbGetQuery(con, q)
  hor_tab <- dcast(tab, geoid_cnty ~ sale_year, value.var = "all_sales")
  
  mrg_nam <- paste("mrg_tab_", j, sep = "")
  #mrg_names <- append(mrg_names, mrg_nam)
  assign(mrg_nam, merge(all_sales, hor_tab, by = "geoid_cnty", all.x = TRUE))
  mrg_names<- append(mrg_names, mrg_nam)
}

mrg_names <- list(mrg_tab_1, mrg_tab_2, mrg_tab_3, mrg_tab_4, mrg_tab_5,
                  mrg_tab_6, mrg_tab_7, mrg_tab_8, mrg_tab_9, mrg_tab_10,
                  mrg_tab_11, mrg_tab_12, mrg_tab_13, mrg_tab_14, mrg_tab_15,
                  mrg_tab_16, mrg_tab_17, mrg_tab_18, mrg_tab_19, mrg_tab_20,
                  mrg_tab_21, mrg_tab_22, mrg_tab_23, mrg_tab_24, mrg_tab_25,
                  mrg_tab_26, mrg_tab_27, mrg_tab_28,
                  mrg_tab_29, mrg_tab_30, mrg_tab_31, mrg_tab_32, mrg_tab_33,
                  mrg_tab_34, mrg_tab_35, mrg_tab_36, mrg_tab_37, mrg_tab_38,
                  mrg_tab_39, mrg_tab_40, mrg_tab_41, mrg_tab_42, mrg_tab_43,
                  mrg_tab_44, mrg_tab_45, mrg_tab_46, mrg_tab_47, mrg_tab_48,
                  mrg_tab_49, mrg_tab_50, mrg_tab_51, mrg_tab_52, mrg_tab_53,
                  mrg_tab_54, mrg_tab_55, mrg_tab_56)
mrg <- do.call("rbind", mrg_names)
saveRDS(mrg, file = "~/R/BK/7-criteria-arms-length-sf-cl.rds")
mrg[is.na(mrg)] <- 0
mrg <- mrg %>% group_by(geoid_cnty) %>% summarize_if(is.numeric, max)
mrg <- data.table(mrg)
mrg[, '2006' := paste0(`2006.y`, " (", round(100*(`2006.y`/`2006.x`), 2), "%)")]
mrg[, '2007' := paste0(`2007.y`, " (", round(100*(`2007.y`/`2007.x`), 2), "%)")]
mrg[, '2008' := paste0(`2008.y`, " (", round(100*(`2008.y`/`2008.x`), 2), "%)")]
mrg[, '2009' := paste0(`2009.y`, " (", round(100*(`2009.y`/`2009.x`), 2), "%)")]
mrg[, '2010' := paste0(`2010.y`, " (", round(100*(`2010.y`/`2010.x`), 2), "%)")]
mrg[, '2011' := paste0(`2011.y`, " (", round(100*(`2011.y`/`2011.x`), 2), "%)")]
mrg[, '2012' := paste0(`2012.y`, " (", round(100*(`2012.y`/`2012.x`), 2), "%)")]
mrg[, '2013' := paste0(`2013.y`, " (", round(100*(`2013.y`/`2013.x`), 2), "%)")]
mrg[, '2014' := paste0(`2014.y`, " (", round(100*(`2014.y`/`2014.x`), 2), "%)")]
mrg[, '2015' := paste0(`2015.y`, " (", round(100*(`2015.y`/`2015.x`), 2), "%)")]
mrg[, '2016' := paste0(`2016.y`, " (", round(100*(`2016.y`/`2016.x`), 2), "%)")]
mrg[, '2017' := paste0(`2017.y`, " (", round(100*(`2017.y`/`2017.x`), 2), "%)")]
mrg[, '2018' := paste0(`2018.y`, " (", round(100*(`2018.y`/`2018.x`), 2), "%)")]

fnl_7 <- mrg[, .(geoid_cnty, `2006`, `2007`, `2008`, `2009`, `2010`, `2011`, `2012`, `2013`, `2014`, `2015`, `2016`, `2017`, `2018`)]
fnl_7 <- data.table(fnl_7)

########################### FINAL TABLE ###############################

`2006` <- paste(fnl_all$`2006`, "\n", fnl_9$`2006`, "\n", 
                 fnl_8$`2006`, "\n", fnl_7$`2006`, "\n")
`2007` <- paste(fnl_all$`2007`, "\n", fnl_9$`2007`, "\n",
                 fnl_8$`2007`, "\n", fnl_7$`2007`, "\n")
`2008` <- paste(fnl_all$`2008`, "\n", fnl_9$`2008`, "\n",
                 fnl_8$`2008`, "\n", fnl_7$`2008`, "\n")
`2009` <- paste(fnl_all$`2009`, "\n", fnl_9$`2009`, "\n",
                 fnl_8$`2009`, "\n", fnl_7$`2009`, "\n")
`2010` <- paste(fnl_all$`2010`, "\n", fnl_9$`2010`, "\n",
                 fnl_8$`2010`, "\n", fnl_7$`2010`, "\n")
`2011` <- paste(fnl_all$`2011`, "\n", fnl_9$`2011`, "\n",
                 fnl_8$`2011`, "\n", fnl_7$`2011`, "\n")
`2012` <- paste(fnl_all$`2012`, "\n", fnl_9$`2012`, "\n",
                 fnl_8$`2012`, "\n", fnl_7$`2012`, "\n")
`2013` <- paste(fnl_all$`2013`, "\n", fnl_9$`2013`, "\n",
                 fnl_8$`2013`, "\n", fnl_7$`2013`, "\n")
`2014` <- paste(fnl_all$`2014`, "\n", fnl_9$`2014`, "\n",
                 fnl_8$`2014`, "\n", fnl_7$`2014`, "\n")
`2015` <- paste(fnl_all$`2015`, "\n", fnl_9$`2015`, "\n",
                 fnl_8$`2015`, "\n", fnl_7$`2015`, "\n")
`2016` <- paste(fnl_all$`2016`, "\n", fnl_9$`2016`, "\n",
                 fnl_8$`2016`, "\n", fnl_7$`2016`, "\n")
`2017` <- paste(fnl_all$`2017`, "\n", fnl_9$`2017`, "\n",
                 fnl_8$`2017`, "\n", fnl_7$`2017`, "\n")
`2018` <- paste(fnl_all$`2018`, "\n", fnl_9$`2018`, "\n",
                 fnl_8$`2018`, "\n", fnl_7$`2018`, "\n")


`2006` <- paste(fnl_all$`2006`, fnl_9$`2006`,
                fnl_8$`2006`, fnl_7$`2006`, sep =", ")
`2007` <- paste(fnl_all$`2007`, fnl_9$`2007`,
                fnl_8$`2007`, fnl_7$`2007`, sep =", ")
`2008` <- paste(fnl_all$`2008`, fnl_9$`2008`,
                fnl_8$`2008`, fnl_7$`2008`, sep =", ")
`2009` <- paste(fnl_all$`2009`,  fnl_9$`2009`, 
                fnl_8$`2009`, fnl_7$`2009`, sep =", ")
`2010` <- paste(fnl_all$`2010`, fnl_9$`2010`,
                fnl_8$`2010`, fnl_7$`2010`, sep=", ")
`2011` <- paste(fnl_all$`2011`, fnl_9$`2011`,
                fnl_8$`2011`, fnl_7$`2011`, sep =", ")
`2012` <- paste(fnl_all$`2012`, fnl_9$`2012`, 
                fnl_8$`2012`, fnl_7$`2012`, sep =", ")
`2013` <- paste(fnl_all$`2013`, fnl_9$`2013`,
                fnl_8$`2013`, fnl_7$`2013`, sep =", ")
`2014` <- paste(fnl_all$`2014`, fnl_9$`2014`, 
                fnl_8$`2014`, fnl_7$`2014`, sep =", ")
`2015` <- paste(fnl_all$`2015`, fnl_9$`2015`,
                fnl_8$`2015`, fnl_7$`2015`, sep =", ")
`2016` <- paste(fnl_all$`2016`, fnl_9$`2016`, 
                fnl_8$`2016`, fnl_7$`2016`, sep =", ")
`2017` <- paste(fnl_all$`2017`, fnl_9$`2017`,
                fnl_8$`2017`, fnl_7$`2017`, sep =", ")
`2018` <- paste(fnl_all$`2018`, fnl_9$`2018`,
                fnl_8$`2018`, fnl_7$`2018`, sep =", ")


fnl<- data.frame(fnl_all$geoid_cnty, `2006`, `2007`, `2008`, `2009`, `2010`, `2011`,
                 `2012`, `2013`, `2014`, `2015`, `2016`, `2017`, `2018`)
names(fnl)[1] <- "geoid_cnty"
names(fnl)[2] <- "2006"
names(fnl)[3] <- "2007"
names(fnl)[4] <- "2008"
names(fnl)[5] <- "2009"
names(fnl)[6] <- "2010"
names(fnl)[7] <- "2011"
names(fnl)[8] <- "2012"
names(fnl)[9] <- "2013"
names(fnl)[10] <- "2014"
names(fnl)[11] <- "2015"
names(fnl)[12] <- "2016"
names(fnl)[13] <- "2017"
names(fnl)[14] <- "2018"
# save as RDS file
saveRDS(fnl, "~/git/corelogic/src/web/shiny_app/cl_arms_length_sales_pct_all-7_30aug21.Rds")