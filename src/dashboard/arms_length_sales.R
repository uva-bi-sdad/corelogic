
source("R/functions.R")
library(data.table)

q1 <- "SELECT geoid_cnty, sale_year, count(*) all_sales
       FROM   corelogic_usda.current_tax_200627_latest_all_add_vars_add_progs_geom_blk
       WHERE  property_indicator = '10'
       AND    transaction_type != '9'
       AND    sale_year IN (2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018)
       GROUP BY geoid_cnty, sale_year
       ORDER BY geoid_cnty, sale_year"

con <- get_db_conn(db_host = "localhost", db_port = 5434)
res <- setDT(dbGetQuery(con, q1))
dbDisconnect(con)

all_sales <- dcast(res, geoid_cnty ~ sale_year, value.var = "all_sales")

q2 <- "SELECT geoid_cnty, sale_year, count(*) all_sales
       FROM   corelogic_usda.real_estate_arms_length_sales_2006_2018
       WHERE  property_indicator = '10'
       AND    transaction_type != '9'
       AND    sale_year IN (2006,2007,2008,2009,2010,2011,2012,2013,2014,2015,2016,2017,2018)
       GROUP BY geoid_cnty, sale_year
       ORDER BY geoid_cnty, sale_year"

con <- get_db_conn(db_host = "localhost", db_port = 5434)
res2 <- setDT(dbGetQuery(con, q2))
dbDisconnect(con)

all_var_sales <- dcast(res2, geoid_cnty ~ sale_year, value.var = "all_sales")

mrg <- merge(all_sales, all_var_sales, by = "geoid_cnty", all.x = TRUE)

mrg[is.na(mrg)] <- 0

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

fnl <- mrg[, .(geoid_cnty, `2006`, `2007`, `2008`, `2009`, `2010`, `2011`, `2012`, `2013`, `2014`, `2015`, `2016`, `2017`, `2018`)]
