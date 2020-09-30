library(glue)
library(RPostgreSQL)

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

