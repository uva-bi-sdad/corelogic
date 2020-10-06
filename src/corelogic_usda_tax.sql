
-- current_tax id table
DROP TABLE IF EXISTS corelogic_usda.corelogic_usda_current_tax_2020_06_27_id;

SELECT DISTINCT fips_code geoid_cnty, p_id_iris_frmtd
INTO corelogic_usda.corelogic_usda_current_tax_2020_06_27_id
FROM corelogic_usda.corelogic_usda_current_tax_2020_06_27
WHERE fips_code != '' AND fips_code IS NOT NULL AND p_id_iris_frmtd != '' AND p_id_iris_frmtd IS NOT NULL;

-- add id primary key
ALTER TABLE corelogic_usda.corelogic_usda_current_tax_2020_06_27_id ADD PRIMARY KEY (geoid_cnty, p_id_iris_frmtd);


-- current_tax prop table
DROP TABLE IF EXISTS corelogic_usda.corelogic_usda_current_tax_2020_06_27_prop;

SELECT DISTINCT fips_code geoid_cnty, p_id_iris_frmtd, property_indicator, zoning, municipality_name, municipality_code,
  acres, land_square_footage, sale_date, property_centroid_longitude, property_centroid_latitude, geometry
INTO corelogic_usda.corelogic_usda_current_tax_2020_06_27_prop
FROM corelogic_usda.corelogic_usda_current_tax_2020_06_27
WHERE fips_code != '' AND fips_code IS NOT NULL
  AND p_id_iris_frmtd != '' AND p_id_iris_frmtd IS NOT NULL
  AND sale_date != '' AND sale_date IS NOT NULL
  AND sale_price != '' AND sale_price IS NOT NULL;

-- add prop foreign key
ALTER TABLE corelogic_usda.corelogic_usda_current_tax_2020_06_27_prop
ADD CONSTRAINT current_tax_prop_id_fk
FOREIGN KEY (geoid_cnty, p_id_iris_frmtd)
REFERENCES corelogic_usda.corelogic_usda_current_tax_2020_06_27_id(geoid_cnty, p_id_iris_frmtd);

-- add index on foreign key
DROP INDEX IF EXISTS current_tax_prop_fk_idx;
CREATE INDEX current_tax_prop_fk_idx ON corelogic_usda.corelogic_usda_current_tax_2020_06_27_prop (geoid_cnty, p_id_iris_frmtd);

-- add sale_date index
DROP INDEX IF EXISTS current_tax_prop_sale_date_idx;
CREATE INDEX current_tax_prop_sale_date_idx ON corelogic_usda.corelogic_usda_current_tax_2020_06_27_prop (sale_date);


-- current_tax bldg table
DROP TABLE IF EXISTS corelogic_usda.corelogic_usda_current_tax_2020_06_27_bldg;

SELECT DISTINCT fips_code geoid_cnty, p_id_iris_frmtd, bldg_code, building_square_feet, living_square_feet, year_built, effective_year_built,
  bedrooms, full_baths, "1qtr_baths", "3qtr_baths", half_baths, total_baths, sale_date
INTO corelogic_usda.corelogic_usda_current_tax_2020_06_27_bldg
FROM corelogic_usda.corelogic_usda_current_tax_2020_06_27
WHERE fips_code != '' AND fips_code IS NOT NULL
  AND p_id_iris_frmtd != '' AND p_id_iris_frmtd IS NOT NULL
  AND sale_date != '' AND sale_date IS NOT NULL
  AND sale_price != '' AND sale_price IS NOT NULL;

-- add bldg foreign key
ALTER TABLE corelogic_usda.corelogic_usda_current_tax_2020_06_27_bldg
ADD CONSTRAINT current_tax_bldg_id_fk
FOREIGN KEY (geoid_cnty, p_id_iris_frmtd)
REFERENCES corelogic_usda.corelogic_usda_current_tax_2020_06_27_id(geoid_cnty, p_id_iris_frmtd);

-- add bldg index on foreign key
DROP INDEX IF EXISTS current_tax_bldg_fk_idx;
CREATE INDEX current_tax_bldg_fk_idx ON corelogic_usda.corelogic_usda_current_tax_2020_06_27_bldg (geoid_cnty, p_id_iris_frmtd);

-- add sale_date index
DROP INDEX IF EXISTS current_tax_bldg_sale_date_idx;
CREATE INDEX current_tax_bldg_sale_date_idx ON corelogic_usda.corelogic_usda_current_tax_2020_06_27_bldg (sale_date);


-- current_tax addr table
DROP TABLE IF EXISTS corelogic_usda.corelogic_usda_current_tax_2020_06_27_addr;

SELECT DISTINCT fips_code geoid_cnty, p_id_iris_frmtd, situs_house_number_prefix, situs_house_number, situs_house_number_suffix, situs_direction,
  situs_street_name, situs_mode, situs_quadrant, situs_unit_number, situs_city, situs_state, situs_zip_code, situs_carrier_code,
  mail_house_number_prefix, mail_house_number, mail_house_number_2, mail_house_number_suffix, mail_direction, mail_street_name, mail_mode,
  mail_quadrant, mail_unit_number, mail_city, mail_state, mail_zip_code, mail_carrier_code, sale_date
INTO corelogic_usda.corelogic_usda_current_tax_2020_06_27_addr
FROM corelogic_usda.corelogic_usda_current_tax_2020_06_27
WHERE fips_code != '' AND fips_code IS NOT NULL
  AND p_id_iris_frmtd != '' AND p_id_iris_frmtd IS NOT NULL
  AND sale_date != '' AND sale_date IS NOT NULL
  AND sale_price != '' AND sale_price IS NOT NULL;

-- add addr foreign key
ALTER TABLE corelogic_usda.corelogic_usda_current_tax_2020_06_27_addr
ADD CONSTRAINT current_tax_addr_id_fk
FOREIGN KEY (geoid_cnty, p_id_iris_frmtd)
REFERENCES corelogic_usda.corelogic_usda_current_tax_2020_06_27_id(geoid_cnty, p_id_iris_frmtd);

-- add addr index on foreign key
DROP INDEX IF EXISTS current_tax_addr_fk_idx;
CREATE INDEX current_tax_addr_fk_idx ON corelogic_usda.corelogic_usda_current_tax_2020_06_27_addr (geoid_cnty, p_id_iris_frmtd);

-- add sale_date index
DROP INDEX IF EXISTS current_tax_addr_sale_date_idx;
CREATE INDEX current_tax_addr_sale_date_idx ON corelogic_usda.corelogic_usda_current_tax_2020_06_27_addr (sale_date);


-- current_tax sale table
DROP TABLE IF EXISTS corelogic_usda.corelogic_usda_current_tax_2020_06_27_sale;

SELECT DISTINCT fips_code geoid_cnty, p_id_iris_frmtd, sale_code, sale_price, sale_date, recording_date, transaction_type
INTO corelogic_usda.corelogic_usda_current_tax_2020_06_27_sale
FROM corelogic_usda.corelogic_usda_current_tax_2020_06_27
WHERE fips_code != '' AND fips_code IS NOT NULL
  AND p_id_iris_frmtd != '' AND p_id_iris_frmtd IS NOT NULL
  AND sale_date != '' AND sale_date IS NOT NULL
  AND sale_price != '' AND sale_price IS NOT NULL;

-- add sale foreign key
ALTER TABLE corelogic_usda.corelogic_usda_current_tax_2020_06_27_sale
ADD CONSTRAINT current_tax_sale_id_fk
FOREIGN KEY (geoid_cnty, p_id_iris_frmtd)
REFERENCES corelogic_usda.corelogic_usda_current_tax_2020_06_27_id(geoid_cnty, p_id_iris_frmtd);

-- add sale index on foreign key
DROP INDEX IF EXISTS current_tax_sale_fk_idx;
CREATE INDEX current_tax_sale_fk_idx ON corelogic_usda.corelogic_usda_current_tax_2020_06_27_sale (geoid_cnty, p_id_iris_frmtd);

-- add sale_date index
DROP INDEX IF EXISTS current_tax_sale_sale_date_idx;
CREATE INDEX current_tax_sale_sale_date_idx ON corelogic_usda.corelogic_usda_current_tax_2020_06_27_sale (sale_date);


-- current_tax tax table
DROP TABLE IF EXISTS corelogic_usda.corelogic_usda_current_tax_2020_06_27_tax;

SELECT DISTINCT fips_code geoid_cnty, p_id_iris_frmtd, tax_amount, tax_year, assessed_year, total_value_calculated, land_value_calculated,
  improvement_value_calculated, sale_date
INTO corelogic_usda.corelogic_usda_current_tax_2020_06_27_tax
FROM corelogic_usda.corelogic_usda_current_tax_2020_06_27
WHERE fips_code != '' AND fips_code IS NOT NULL
  AND p_id_iris_frmtd != '' AND p_id_iris_frmtd IS NOT NULL
  AND sale_date != '' AND sale_date IS NOT NULL
  AND sale_price != '' AND sale_price IS NOT NULL;

-- add tax foreign key
ALTER TABLE corelogic_usda.corelogic_usda_current_tax_2020_06_27_tax
ADD CONSTRAINT current_tax_tax_id_fk
FOREIGN KEY (geoid_cnty, p_id_iris_frmtd)
REFERENCES corelogic_usda.corelogic_usda_current_tax_2020_06_27_id(geoid_cnty, p_id_iris_frmtd);

-- add tax index on foreign key
DROP INDEX IF EXISTS current_tax_tax_fk_idx;
CREATE INDEX current_tax_tax_fk_idx ON corelogic_usda.corelogic_usda_current_tax_2020_06_27_tax (geoid_cnty, p_id_iris_frmtd);

-- add sale_date index
DROP INDEX IF EXISTS current_tax_tax_sale_date_idx;
CREATE INDEX current_tax_tax_sale_date_idx ON corelogic_usda.corelogic_usda_current_tax_2020_06_27_tax (sale_date);


-- create broadband_variables_tax table
SELECT id.geoid_cnty,
       id.p_id_iris_frmtd,
       sale.sale_date,
       sale.sale_price,
       nullif(sale.sale_code, '') sale_code,
       sale.transaction_type,
       nullif(bldg.bldg_code, '') bldg_code,
       bldg.building_square_feet,
       bldg.living_square_feet,
       bldg.year_built,
       bldg.effective_year_built,
       bldg.bedrooms,
       bldg.full_baths,
       bldg."1qtr_baths",
       bldg."3qtr_baths",
       bldg.half_baths,
       bldg.total_baths,
       trim(
         replace(
           replace(
             coalesce(addr.mail_house_number_prefix, '') || ' ' ||
             coalesce(addr.mail_house_number, '') || ' ' ||
             coalesce(addr.mail_direction, '') || ' ' ||
             coalesce(addr.mail_street_name, '') || ' ' ||
             coalesce(addr.mail_mode, '') || ' ' ||
             coalesce(addr.mail_quadrant, '') || ' ' ||
             coalesce(addr.mail_city, '') || ' ' ||
             coalesce(addr.mail_state, '') || ' ' ||
             coalesce(addr.mail_zip_code, ''),
           '  ', ' '),
         '  ', ' ')
       ) as address,
       prop.property_indicator,
       prop.zoning,
       prop.acres,
       prop.land_square_footage,
       prop.property_centroid_longitude,
       prop.property_centroid_latitude,
       prop.geometry
INTO   corelogic_usda.broadband_variables_tax
FROM   (((corelogic_usda.corelogic_usda_current_tax_2020_06_27_id id
       JOIN   corelogic_usda.corelogic_usda_current_tax_2020_06_27_sale sale
         ON   id.geoid_cnty = sale.geoid_cnty AND id.p_id_iris_frmtd = sale.p_id_iris_frmtd)
              JOIN   corelogic_usda.corelogic_usda_current_tax_2020_06_27_bldg bldg
                ON   id.geoid_cnty = bldg.geoid_cnty AND id.p_id_iris_frmtd = bldg.p_id_iris_frmtd AND sale.sale_date = bldg.sale_date)
                     JOIN   corelogic_usda.corelogic_usda_current_tax_2020_06_27_addr addr
                       ON   id.geoid_cnty = addr.geoid_cnty AND id.p_id_iris_frmtd = addr.p_id_iris_frmtd AND sale.sale_date = addr.sale_date)
                            JOIN   corelogic_usda.corelogic_usda_current_tax_2020_06_27_prop prop
                              ON   id.geoid_cnty = prop.geoid_cnty AND id.p_id_iris_frmtd = prop.p_id_iris_frmtd AND sale.sale_date = prop.sale_date
--WHERE id.geoid_cnty = '51013'
--LIMIT 10

-- eliominate duplicates
SELECT DISTINCT  * INTO corelogic_usda.broadband_variables_tax_2020_06_27 FROM corelogic_usda.broadband_variables_tax;

SELECT
geoid_cnty, p_id_iris_frmtd, sale_date, MAX(sale_price) sale_price, MAX(sale_code) sale_code, MAX(transaction_type) transaction_type,
  MAX(bldg_code) bldg_code, MAX(building_square_feet) building_square_feet, MAX(living_square_feet) living_square_feet, MAX(year_built) year_built,
  MAX(effective_year_built) effective_year_built, MAX(bedrooms) bedrooms, MAX(full_baths) full_baths, MAX("1qtr_baths") "1qtr_baths",
  MAX("3qtr_baths") "3qtr_baths", MAX(half_baths) half_baths, MAX(total_baths) total_baths, MAX(address) address, MAX(property_indicator) property_indicator,
  MAX(zoning) zoning, MAX(acres) acres, MAX(land_square_footage) land_square_footage, MAX(property_centroid_longitude) property_centroid_longitude,
  MAX(property_centroid_latitude) property_centroid_latitude, MAX(geometry) geometry
INTO corelogic_usda.broadband_variables_tax_2020_06_27_unq
FROM corelogic_usda.broadband_variables_tax_2020_06_27
--WHERE geoid_cnty='51013'
GROUP BY geoid_cnty, p_id_iris_frmtd, sale_date

-- add broadband_variables_tax primary key
ALTER TABLE corelogic_usda.broadband_variables_tax_2020_06_27_unq ADD PRIMARY KEY (geoid_cnty, p_id_iris_frmtd, sale_date);
-- add index on transaction type
CREATE INDEX broadband_variables_tax_tt ON corelogic_usda.broadband_variables_tax_2020_06_27_unq (transaction_type);
-- add index on property indicator
CREATE INDEX broadband_variables_tax_pi ON corelogic_usda.broadband_variables_tax_2020_06_27_unq (property_indicator);


SELECT
	geoid_cnty,
  p_id_iris_frmtd,
  sale_date,
	COUNT (*)
FROM
	corelogic_usda.broadband_variables_tax_2020_06_27
WHERE geoid_cnty = '51013'
GROUP BY
	geoid_cnty,
  p_id_iris_frmtd,
  sale_date
HAVING
	COUNT (*) > 1;


ALTER TABLE corelogic_usda.broadband_variables_tax_2020_06_27_unq
ADD COLUMN pri_cat_code text;


UPDATE corelogic_usda.broadband_variables_tax_2020_06_27_unq a
SET pri_cat_code = b.pri_cat_code
FROM corelogic_usda.corelogic_usda_deed_2020_06_27_sale b
WHERE a.geoid_cnty = b.fips
  AND a.p_id_iris_frmtd = b.pcl_id_iris_formatted
  AND a.sale_date = b.sale_date_yyyymmdd




COPY (select * from corelogic_usda.broadband_variables_tax_2020_06_27_unq where geoid_cnty like '51%') to /project/biocomplexity/sdad/projects_data/usda/bb/working/bb_vars_va.csv CSV HEADER




