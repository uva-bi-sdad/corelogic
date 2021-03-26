-- !preview conn=DBI::dbConnect(RSQLite::SQLite())


-- 'SA,SD,TT,C1,C2,LA,LS,BD,BA'
SELECT LEFT(blockce, 5) fipsco, recording_year, 'SA,SD,TT,C1,C2,LA,LS,BD,BA' vars, count(*) have_all
FROM (
SELECT a.fips, a.pcl_id_iris_formatted, a.blockce,
       b.sale_amount, b.sale_code, b.sale_date_yyyymmdd sale_date, b.recording_year, b.transaction_type, b.pri_cat_code, b.deed_sec_cat_codes_2x10,
       c.acres, c.land_square_footage, c.property_indicator,
       d.year_built, d.effective_year_built, d.bedrooms, d.total_baths
FROM ((corelogic_usda.corelogic_usda_deed_2020_06_27_blockce a
        JOIN corelogic_usda.corelogic_usda_deed_2020_06_27_sale b ON a.fips = b.fips AND a.pcl_id_iris_formatted = b.pcl_id_iris_formatted)
          JOIN corelogic_usda.corelogic_usda_deed_2020_06_27_prop c ON a.fips = c.fips AND a.pcl_id_iris_formatted = c.pcl_id_iris_formatted)
            JOIN corelogic_usda.corelogic_usda_deed_2020_06_27_bldg d ON a.fips = d.fips AND a.pcl_id_iris_formatted = d.pcl_id_iris_formatted
WHERE a.fips LIKE '51%'
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
  AND acres != '' AND land_square_footage != '' AND property_indicator != '""' AND bedrooms != '""' AND total_baths != '""'
GROUP BY LEFT(blockce, 5), recording_year
ORDER BY LEFT(blockce, 5), recording_year


-- 'SA,SD,TT,C1orC2,LAorLS,BDorBA'

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


-- Create new baths table from tax_sale
select fips_code, p_id_iris_frmtd, max(half_baths) half_baths, max(qtr_baths) qtr_baths, max(full_baths) full_baths, max(total_baths) total_baths
into corelogic_usda.corelogic_usda_current_tax_2020_06_27_max_baths
from corelogic_usda.corelogic_usda_current_tax_2020_06_27_bldg
group by fips_code, p_id_iris_frmtd

 alter table corelogic_usda.corelogic_usda_current_tax_2020_06_27_max_baths add column sum_baths integer
 update corelogic_usda.corelogic_usda_current_tax_2020_06_27_max_baths set sum_baths = COALESCE(half_baths::INTEGER, 0) +
 COALESCE(qtr_baths::INTEGER, 0) + COALESCE(full_baths::INTEGER, 0)

-- CREATE baths table index
CREATE INDEX tax_bath_idx ON corelogic_usda.corelogic_usda_current_tax_2020_06_27_max_baths (fips_code, p_id_iris_frmtd);

-- JOIN deed_sale to baths from tax
SELECT fips,
       pcl_id_iris_formatted,
       building_square_feet,
       living_square_feet,
       gross_square_feet,
       year_built,
       effective_year_built,
       bedrooms,
       a.total_baths,
       recording_date_yyyymmdd,
       recording_year,
       half_baths,
       qtr_baths,
       full_baths
INTO corelogic_usda.corelogic_usda_deed_2020_06_27_bldg_taxbath
FROM corelogic_usda.corelogic_usda_deed_2020_06_27_bldg a
LEFT JOIN corelogic_usda.corelogic_usda_current_tax_2020_06_27_max_baths b
  ON a.fips = b.fips_code
  AND a.pcl_id_iris_formatted = b.p_id_iris_frmtd

