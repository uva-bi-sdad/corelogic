-- !preview conn=DBI::dbConnect(RSQLite::SQLite())

SELECT nameco, LEFT(blockce, 5) fipsco, recording_year, 'SA,SD,TT,C1orC2,LAorLS,BDorBA' vars, count(*) have_all
 FROM (
 SELECT co."GEOID" geoid, co."NAME" nameco,
        a.fips, a.pcl_id_iris_formatted, a.blockce,
        b.sale_amount, b.sale_code, b.sale_date_yyyymmdd sale_date, b.recording_year, b.transaction_type, b.pri_cat_code, b.deed_sec_cat_codes_2x10,
        c.acres, c.land_square_footage, c.property_indicator,
        d.year_built, d.effective_year_built, d.bedrooms, d.total_baths
 FROM corelogic_usda.counties co LEFT JOIN (
       ((corelogic_usda.corelogic_usda_deed_2020_06_27_blockce a
         JOIN corelogic_usda.corelogic_usda_deed_2020_06_27_sale b ON a.fips = b.fips AND a.pcl_id_iris_formatted = b.pcl_id_iris_formatted)
           JOIN corelogic_usda.corelogic_usda_deed_2020_06_27_prop c ON a.fips = c.fips AND a.pcl_id_iris_formatted = c.pcl_id_iris_formatted)
             JOIN corelogic_usda.corelogic_usda_deed_2020_06_27_bldg d ON a.fips = d.fips AND a.pcl_id_iris_formatted = d.pcl_id_iris_formatted)
               ON co."GEOID" = a.fips
 WHERE co."GEOID" LIKE '51%' AND a.fips LIKE '51%'
  AND (
       (b.recording_year = 2017 AND c.recording_year = 2017 AND d.recording_year = 2017)
       OR
       (b.recording_year = 2016 AND c.recording_year = 2016 AND d.recording_year = 2016)
       OR
       (b.recording_year = 2015 AND c.recording_year = 2015 AND d.recording_year = 2015)
       OR
       (b.recording_year = 2014 AND c.recording_year = 2014 AND d.recording_year = 2014)
       OR
       (b.recording_year = 2013 AND c.recording_year = 2014 AND d.recording_year = 2013)
      )
  -- AND c.recording_year = 2016
  -- AND d.recording_year = 2016
 ) t
 WHERE sale_amount != '""' AND sale_date != '""' AND transaction_type != '""' AND (pri_cat_code != '""' OR sale_code != '""') AND deed_sec_cat_codes_2x10 != '""'
   AND (acres != '' OR land_square_footage != '') AND property_indicator != '""' AND (bedrooms != '""' OR total_baths != '""')
 GROUP BY nameco, LEFT(blockce, 5), recording_year
 ORDER BY nameco, LEFT(blockce, 5), recording_year
