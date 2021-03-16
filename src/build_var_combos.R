library(glue)
library(RPostgreSQL)
library(data.table)

get_db_conn <-
  function(db_name = "sdad",
           db_host = "localhost",
           db_port = "5434",
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
con <- get_db_conn()

# DEED COLUMNS
PI <- glue_sql("property_indicator")
C1 <- glue_sql("pri_cat_code")
SA <- glue_sql("sale_amount")
SD <- glue_sql("sale_date_yyyymmdd")
TT <- glue_sql("transaction_type")
SC <- glue_sql("sale_code")
C2 <- glue_sql("deed_sec_cat_codes_2x10")
YB <- glue_sql("year_built")
YE <- glue_sql("effective_year_built")
BS <- glue_sql("building_square_feet")
VS <- glue_sql("living_square_feet")
GS <- glue_sql("gross_square_feet")
LA <- glue_sql("acres")
LS <- glue_sql("land_square_footage")
BD <- glue_sql("bedrooms")
TB <- glue_sql("total_baths")
RY <- glue_sql("recording_year")
BK <- glue_sql("blockce")
QB <- glue_sql("qtr_baths")
HB <- glue_sql("half_baths")
FB <- glue_sql("full_baths")
BF <- glue_sql("building_square_feet")
LF <- glue_sql("living_square_feet")
GF <- glue_sql("gross_square_feet")

TBL1 <- glue_sql("corelogic_usda.corelogic_usda_deed_2020_06_27_blockce")
TBL2 <- glue_sql("corelogic_usda.corelogic_usda_deed_2020_06_27_sale")
TBL3 <- glue_sql("corelogic_usda.corelogic_usda_deed_2020_06_27_prop")
TBL4 <- glue_sql("corelogic_usda.corelogic_usda_deed_2020_06_27_bldg")
TBL5 <- glue_sql("corelogic_usda.corelogic_usda_current_tax_2020_06_27_max_baths")

# JOIN IDs
JN_ID1 <- glue_sql("fips")
JN_ID2 <- glue_sql("pcl_id_iris_formatted")
JN_ID3 <- glue_sql("recording_year")
JN_ID4 <- glue_sql("fips_code")
JN_ID5 <- glue_sql("p_id_iris_frmtd")

# JOIN STATEMENTS
JN_TBL1_TBL2 <- glue_sql(TBL1, " JOIN ", TBL2, " ON ",
                         TBL1, ".", JN_ID1, " = ", TBL2, ".", JN_ID1, " AND ",
                         TBL1, ".", JN_ID2, " = ", TBL2, ".", JN_ID2)
JN_TBL1_TBL3 <- glue_sql(" JOIN ", TBL3, " ON ",
                         TBL1, ".", JN_ID1, " = ", TBL3, ".", JN_ID1, " AND ",
                         TBL1, ".", JN_ID2, " = ", TBL3, ".", JN_ID2, " AND ",
                         TBL2, ".", JN_ID3, " = ", TBL3, ".", JN_ID3)
JN_TBL1_TBL4 <- glue_sql(" JOIN ", TBL4, " ON ",
                         TBL1, ".", JN_ID1, " = ", TBL4, ".", JN_ID1, " AND ",
                         TBL1, ".", JN_ID2, " = ", TBL4, ".", JN_ID2, " AND ",
                         TBL3, ".", JN_ID3, " = ", TBL4, ".", JN_ID3)
JN_TBL1_TBL5 <- glue_sql(" JOIN ", TBL5, " ON ",
                         TBL1, ".", JN_ID1, " = ", TBL5, ".", JN_ID4, " AND ",
                         TBL1, ".", JN_ID2, " = ", TBL5, ".", JN_ID5)

JN_TBL1_TBL2_TBL3_TBL4 <- glue_sql("(((", JN_TBL1_TBL2, ")", JN_TBL1_TBL3, ")", JN_TBL1_TBL4, ")", JN_TBL1_TBL5)

# TEMP
ST <- "5101%"
FP <- "51013"

# BUILD QUERY
Q1 <- glue_sql(
  "SELECT
  {TBL1}.{JN_ID1},
  {TBL2}.{RY},
  'SA,SD,TT|SC,C2,LA|LS,YB|YE,BF|LF|GF,BD,TB|QB|HB|FB' vars,
  COUNT(*) have_all
  -- {TBL1}.{JN_ID2},
  -- {TBL1}.{BK},
  -- {TBL2}.{SA},
  -- {TBL2}.{SC},
  -- {TBL2}.{SD},
  -- {TBL2}.{TT},
  -- {TBL2}.{C1},
  -- {TBL2}.{C2},
  -- {TBL3}.{AC},
  -- {TBL3}.{LS},
  -- {TBL3}.{PI},
  -- {TBL4}.{YB},
  -- {TBL4}.{YE},
  -- {TBL4}.{BD},
  -- {TBL4}.{TB}
  FROM {JN_TBL1_TBL2_TBL3_TBL4}
  WHERE
  {TBL1}.{JN_ID1} LIKE {ST}
  -- Single Family Residence / Townhouse
  AND {TBL3}.{PI} = '10'
  -- Arms Length Transaction
  AND {TBL2}.{C1} = 'A'
  -- Recording Year
  AND {TBL2}.{RY} IN (2005,2006,2007,2008,2009,2010,2011,2012,2013,2104,2015,2016,2017)
  -- Sale Amount
  AND {TBL2}.{SA} <> '\"\"'
  -- Sale date
  AND {TBL2}.{SD} <> '\"\"'
  -- Transaction Categories
  AND ({TBL2}.{TT} <> '' OR {TBL2}.{SC} <> '\"\"')
  AND {TBL2}.{C2} <> '\"\"'
  -- Land Size
  AND ({TBL3}.{LA} <> '\"\"' OR {TBL3}.{LS} <> '\"\"')
  -- Year Built
  AND ({TBL4}.{YB} <> '\"\"' OR {TBL4}.{YE} <> '\"\"')
  -- House Size
  AND ({TBL4}.{BF} <> '\"\"' OR {TBL4}.{LF} <> '\"\"' OR {TBL4}.{GF} <> '\"\"')
  -- Bedrooms
  AND {TBL4}.{BD} <> '\"\"'
  -- Bathrooms
  AND ({TBL4}.{TB} <> '\"\"' OR {TBL5}.{QB} IS NOT NULL OR {TBL5}.{HB} IS NOT NULL OR {TBL5}.{FB} IS NOT NULL)
  GROUP BY
  {TBL1}.{JN_ID1},
  {TBL2}.{RY}
  ORDER BY
  {TBL1}.{JN_ID1},
  {TBL2}.{RY}",
  .con = con
)

# RUN QUERY
R1 <- dbGetQuery(con, Q1)

# GET COUNTY NAMES
counties <- dbGetQuery(con, "SELECT \"GEOID\" as geoid, \"NAME\" as name FROM corelogic_usda.counties WHERE \"GEOID\" LIKE '51%' OR \"GEOID\" LIKE '19%'")


"
geoid_cnty,
p_id_iris_frmtd,
sale_date,
sale_price,
sale_code,
transaction_type,
bldg_code,
building_square_feet,
living_square_feet,
year_built,
effective_year_built,
bedrooms,
full_baths,
\"1qtr_baths\",
\"3qtr_baths\",
\"half_baths\",
total_baths,
address,
property_indicator,
zoning,
acres,
land_square_footage,
property_centroid_longitude,
property_centroid_latitude,
geometry,
pri_cat_code,
BIP,
CC,
RC,
TCF,
TCI
"

# With or without pri_cat_code
q1 <-
"
SELECT
  geoid_cnty,
  sale_yr,
  pri_cat_code_req,
  have_all
FROM
(
SELECT
  geoid_cnty,
  LEFT(sale_date, 4) sale_yr,
  'TRUE' pri_cat_code_req,
  count(*) have_all
FROM
  corelogic_usda.broadband_variables_tax_2020_06_27_unq_prog
WHERE
--  (geoid_cnty LIKE '51%' OR geoid_cnty LIKE '19%')
-- AND
  property_indicator = '10'
AND
  transaction_type != '9'
AND
  sale_date IS NOT NULL
AND
  sale_price IS NOT NULL
AND
  (building_square_feet IS NOT NULL OR living_square_feet IS NOT NULL)
AND
 (acres IS NOT NULL OR land_square_footage IS NOT NULL)
AND
 (year_built IS NOT NULL OR effective_year_built IS NOT NULL)
AND
 (full_baths IS NOT NULL OR \"1qtr_baths\" IS NOT NULL OR \"3qtr_baths\" IS NOT NULL OR half_baths IS NOT NULL OR total_baths IS NOT NULL)
AND
  pri_cat_code IS NOT NULL
AND
  LEFT(sale_date, 4) IN ('2006', '2007','2008','2009','2010','2011','2012','2013','2014','2015','2016','2017','2018')
GROUP BY
  geoid_cnty,
  LEFT(sale_date, 4)

UNION ALL

SELECT
  geoid_cnty,
  LEFT(sale_date, 4) sale_yr,
  'FALSE' pri_cat_code_req,
  count(*) have_all
FROM
  corelogic_usda.broadband_variables_tax_2020_06_27_unq_prog
WHERE
--  (geoid_cnty LIKE '51%' OR geoid_cnty LIKE '19%')
-- AND
   property_indicator = '10'
AND
  transaction_type != '9'
AND
  sale_date IS NOT NULL
AND
  sale_price IS NOT NULL
AND
  (building_square_feet IS NOT NULL OR living_square_feet IS NOT NULL)
AND
 (acres IS NOT NULL OR land_square_footage IS NOT NULL)
AND
 (year_built IS NOT NULL OR effective_year_built IS NOT NULL)
AND
 (full_baths IS NOT NULL OR \"1qtr_baths\" IS NOT NULL OR \"3qtr_baths\" IS NOT NULL OR half_baths IS NOT NULL OR total_baths IS NOT NULL)
AND
  LEFT(sale_date, 4) IN ('2006', '2007','2008','2009','2010','2011','2012','2013','2014','2015','2016','2017','2018')
GROUP BY
  geoid_cnty,
  LEFT(sale_date, 4)
) t
GROUP BY
  geoid_cnty,
  sale_yr,
  pri_cat_code_req,
  have_all
ORDER BY
  geoid_cnty,
  sale_yr,
  pri_cat_code_req,
  have_all
"

con <- get_db_conn()
res <- setDT(dbGetQuery(con, q1))
dbDisconnect(con)

have_all <- dcast(res, geoid_cnty + pri_cat_code_req ~ sale_yr, value.var = "have_all")

saveRDS(have_all, "data/working/corelogic_have_all_vars.RDS")

counties <- setDT(tigris::counties())[, .(geoid_st = STATEFP, geoid_cnty = GEOID, name_cnty = NAMELSAD)]
have_all_names <- merge(have_all, counties, by = "geoid_cnty")
setcolorder(have_all_names, c("geoid_st", "geoid_cnty", "name_cnty", "pri_cat_code_req", "2006", "2007", "2008", "2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018"))

saveRDS(have_all_names, "data/working/corelogic_have_all_vars.RDS")


have_all_names <- readRDS("data/working/corelogic_have_all_vars.RDS")

q2 <- "SELECT  geoid_cnty,  LEFT(sale_date, 4) sale_yr,  count(*) all_sales FROM  corelogic_usda.broadband_variables_tax_2020_06_27_unq_prog WHERE    property_indicator = '10'
  AND   transaction_type != '9' AND LEFT(sale_date, 4) IN ('2006', '2007','2008','2009','2010','2011','2012','2013','2014','2015','2016','2017','2018') GROUP BY   geoid_cnty,   LEFT(sale_date, 4) ORDER BY   geoid_cnty,   LEFT(sale_date, 4)"

con <- get_db_conn()
res2 <- setDT(dbGetQuery(con, q2))
dbDisconnect(con)

all_sales <- dcast(res2, geoid_cnty ~ sale_yr, value.var = "all_sales")

all_all <- merge(have_all_names, all_sales, by = c("geoid_cnty"))


for (c in c('2006', '2007','2008','2009','2010','2011','2012','2013','2014','2015','2016','2017','2018')) {
  t <- paste0(c, ".x")
  b <- paste0(c, ".y")
  all_all[, eval(c) := paste0(get(t), " (", round(100 * (get(t) / get(b)), 2), "%)")]
}

corelogic_have_all_vars_fnl <- all_all[, .(geoid_cnty, name_cnty, pri_cat_code_req, `2006`, `2007`, `2008`, `2009`, `2010`, `2011`, `2012`, `2013`, `2014`, `2015`, `2016`, `2017`, `2018`)]
saveRDS(corelogic_have_all_vars_fnl, "data/working/corelogic_have_all_vars_fnl.RDS")

# library(reactable)
# reactable(
#   have_all_names,
#   filterable = FALSE,
#   searchable = FALSE,
#   rownames = FALSE,
#   #showPageSizeOptions = TRUE,
#   #pageSizeOptions = c(10, 50, 100),
#   #defaultPageSize = 10,
#   pagination = FALSE,
#   height = 800,
#   #defaultSorted = list(Species = "asc", Petal.Length = "desc"),
#   defaultColDef = colDef(
#     # cell = function(value) format(value, nsmall = 0),
#     style = "font-size: 12px;",
#     align = "left",
#     minWidth = 70,
#     headerStyle = list(background = "#f7f7f8", fontSize = "12px"),
#     sortNALast = TRUE
#   ),
#   bordered = TRUE,
#   striped = TRUE,
#   highlight = TRUE
#   # ,
#   # groupBy = "Field.Name"
# )

library(dataplumbr)
loc.lat_lon2geo_areas(lat = '30.206450', lon = '-85.818760')
