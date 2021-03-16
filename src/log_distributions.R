library(RPostgreSQL)
library(ggplot2)

con <- dbConnect(drv = RPostgreSQL::PostgreSQL() , 
                 dbname="sdad", 
                 host = "localhost", 
                 port = "5434", 
                 user = "ads7fg", 
                 password = "Iwnftp$2")

sql <- "select appr_baths, bedrooms, living_sq_ft from corelogic_usda.broadband_variables_tax_2020_06_27_unq_prog TABLESAMPLE SYSTEM(2.0) WHERE living_sq_ft is not null"
res <- dbGetQuery(con, sql)

dbDisconnect(con)

res$bedrooms <- as.numeric(res$bedrooms)

# bathrooms
bath_finite <- res[is.finite(res$appr_baths),]
bath_log <- log(bath_finite$appr_baths)

df <- data.frame(cnt = bath_finite$appr_baths, lg = bath_log, lg10 = bath_log10)
df <- df[is.finite(df$lg) & df$lg > 0,]

ggplot(df, aes(lg10)) +
  geom_density()

dfsd <- sd(df$lg)
dfmean <- mean(df$lg)

rem <- df[df$lg >= dfmean + (5 * dfsd),]

# square footage living
sqf_finite <- res[is.finite(res$living_sq_ft),]
sqf_log <- log(sqf_finite$living_sq_ft)

df2 <- data.frame(sf = sqf_finite$living_sq_ft, lg = sqf_log)
df2 <- df2[is.finite(df2$lg) & df2$lg > 0,]

ggplot(df2, aes(lg)) +
  geom_density()

df2sd <- sd(df2$lg)
df2mean <- mean(df2$lg)

rem2 <- df2[df2$lg >= df2mean + (5 * df2sd),]

# bedrooms
bed_finite <- res[is.finite(res$bedrooms),]
bed_log <- log(bed_finite$bedrooms)
  
df3 <- data.frame(bed = bed_finite$bedrooms, lg = bed_log)
df3 <- df3[is.finite(df3$lg) & df3$lg > 0,]

ggplot(df3, aes(bed)) +
  geom_density()

ggplot(df3, aes(lg)) +
  geom_density()

df3sd <- sd(df3$lg)
df3mean <- mean(df3$lg)

rem3 <- df3[df3$lg >= df3mean + (5 * df3sd),]


