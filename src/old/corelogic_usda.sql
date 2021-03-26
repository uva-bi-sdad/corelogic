CREATE INDEX fips_pcl_idx ON corelogic_usda.testtable2 (fips, pcl_id_iris_formatted);

-- deed id table
SELECT DISTINCT fips, pcl_id_iris_formatted
INTO corelogic_usda.corelogic_usda_deed_2020_06_27_id
FROM corelogic_usda.corelogic_usda_deed_2020_06_27
WHERE fips != '' AND pcl_id_iris_formatted != '';

-- add id primary key
ALTER TABLE corelogic_usda.corelogic_usda_deed_2020_06_27_id ADD CONSTRAINT PRIMARY KEY (fips, pcl_id_iris_formatted)


-- deed prop table
DROP TABLE IF EXISTS corelogic_usda.corelogic_usda_deed_2020_06_27_prop;

SELECT DISTINCT fips, pcl_id_iris_formatted, property_indicator, land_use, acres, land_square_footage, recording_date_yyyymmdd, geometry
INTO corelogic_usda.corelogic_usda_deed_2020_06_27_prop
FROM corelogic_usda.corelogic_usda_deed_2020_06_27
WHERE fips != '' AND pcl_id_iris_formatted != '';

-- add prop foreign key
ALTER TABLE corelogic_usda.corelogic_usda_deed_2020_06_27_prop
ADD CONSTRAINT deed_prop_id_fk
FOREIGN KEY (fips, pcl_id_iris_formatted)
REFERENCES corelogic_usda.corelogic_usda_deed_2020_06_27_id(fips, pcl_id_iris_formatted);

-- add prop index
CREATE INDEX prop_fk_idx ON corelogic_usda.corelogic_usda_deed_2020_06_27_prop (fips, pcl_id_iris_formatted);

ALTER TABLE corelogic_usda.corelogic_usda_deed_2020_06_27_prop ADD COLUMN sale_year INTEGER;

UPDATE corelogic_usda.corelogic_usda_deed_2020_06_27_prop SET sale_year = cast(LEFT(sale_date_yyyymmdd, 4) AS INTEGER);

CREATE INDEX deed_prop_recyr_idx ON corelogic_usda.corelogic_usda_deed_2020_06_27_prop (recording_year);


-- deed bldg table
DROP TABLE IF EXISTS corelogic_usda.corelogic_usda_deed_2020_06_27_bldg;

SELECT DISTINCT fips, pcl_id_iris_formatted, building_square_feet, living_square_feet, gross_square_feet, year_built, effective_year_built,
  bedrooms, total_baths, recording_date_yyyymmdd
INTO corelogic_usda.corelogic_usda_deed_2020_06_27_bldg
FROM corelogic_usda.corelogic_usda_deed_2020_06_27
WHERE fips != '' AND pcl_id_iris_formatted != '';

-- add bldg foreign key
ALTER TABLE corelogic_usda.corelogic_usda_deed_2020_06_27_bldg
ADD CONSTRAINT deed_bldg_id_fk
FOREIGN KEY (fips, pcl_id_iris_formatted)
REFERENCES corelogic_usda.corelogic_usda_deed_2020_06_27_id(fips, pcl_id_iris_formatted);

-- add bldg index
CREATE INDEX bldg_fk_idx ON corelogic_usda.corelogic_usda_deed_2020_06_27_bldg (fips, pcl_id_iris_formatted);

ALTER TABLE corelogic_usda.corelogic_usda_deed_2020_06_27_bldg ADD COLUMN recording_year INTEGER;

UPDATE corelogic_usda.corelogic_usda_deed_2020_06_27_bldg SET recording_year = cast(LEFT(recording_date_yyyymmdd, 4) AS INTEGER);

CREATE INDEX deed_bldg_recyr_idx ON corelogic_usda.corelogic_usda_deed_2020_06_27_bldg (recording_year);


-- deed addr table
DROP TABLE IF EXISTS corelogic_usda.corelogic_usda_deed_2020_06_27_addr;

SELECT DISTINCT fips, pcl_id_iris_formatted, situs_house_number_prefix, situs_house_number, situs_house_number_suffix, situs_direction,
  situs_street_name, situs_mode, situs_quadrant, situs_apartment_unit, situs_city, situs_state, situs_zip_code, situs_carrier_code,
  mailing_house_number_prefix, mailing_house_number, mailing_house_number_suffix, mailing_direction, mailing_street_name, mailing_mode,
  mailing_quadrant, mailing_apartment_unit, mailing_property_city, mailing_property_state, mailing_property_address_zip_code,
  mailing_carrier_code, recording_date_yyyymmdd
INTO corelogic_usda.corelogic_usda_deed_2020_06_27_addr
FROM corelogic_usda.corelogic_usda_deed_2020_06_27
WHERE fips != '' AND pcl_id_iris_formatted != '';

-- add addr foreign key
ALTER TABLE corelogic_usda.corelogic_usda_deed_2020_06_27_addr
ADD CONSTRAINT deed_addr_id_fk
FOREIGN KEY (fips, pcl_id_iris_formatted)
REFERENCES corelogic_usda.corelogic_usda_deed_2020_06_27_id(fips, pcl_id_iris_formatted);

-- add addr index
CREATE INDEX addr_fk_idx ON corelogic_usda.corelogic_usda_deed_2020_06_27_addr (fips, pcl_id_iris_formatted);

ALTER TABLE corelogic_usda.corelogic_usda_deed_2020_06_27_addr ADD COLUMN recording_year INTEGER;

UPDATE corelogic_usda.corelogic_usda_deed_2020_06_27_addr SET recording_year = cast(LEFT(recording_date_yyyymmdd, 4) AS INTEGER);

CREATE INDEX deed_addr_recyr_idx ON corelogic_usda.corelogic_usda_deed_2020_06_27_addr (recording_year);


-- deed sale table
DROP TABLE IF EXISTS corelogic_usda.corelogic_usda_deed_2020_06_27_sale;

SELECT DISTINCT fips, pcl_id_iris_formatted, sale_code, sale_amount, sale_date_yyyymmdd, recording_date_yyyymmdd, transaction_type, pri_cat_code,
  deed_sec_cat_codes_2x10, inter_family
INTO corelogic_usda.corelogic_usda_deed_2020_06_27_sale
FROM corelogic_usda.corelogic_usda_deed_2020_06_27
WHERE fips != '' AND pcl_id_iris_formatted != '';

-- add sale foreign key
ALTER TABLE corelogic_usda.corelogic_usda_deed_2020_06_27_sale
ADD CONSTRAINT deed_sale_id_fk
FOREIGN KEY (fips, pcl_id_iris_formatted)
REFERENCES corelogic_usda.corelogic_usda_deed_2020_06_27_id(fips, pcl_id_iris_formatted);

-- add sale index
CREATE INDEX sale_fk_idx ON corelogic_usda.corelogic_usda_deed_2020_06_27_sale (fips, pcl_id_iris_formatted);

ALTER TABLE corelogic_usda.corelogic_usda_deed_2020_06_27_sale ADD COLUMN recording_year INTEGER;

UPDATE corelogic_usda.corelogic_usda_deed_2020_06_27_sale SET recording_year = cast(LEFT(recording_date_yyyymmdd, 4) AS INTEGER);

CREATE INDEX deed_sale_recyr_idx ON corelogic_usda.corelogic_usda_deed_2020_06_27_sale (recording_year);


-- deed tax table
DROP TABLE IF EXISTS corelogic_usda.corelogic_usda_deed_2020_06_27_tax;

SELECT DISTINCT fips, pcl_id_iris_formatted, tax_amount, tax_year, total_value_calculated, land_value_calculated,
  improvement_value_calculated, recording_date_yyyymmdd
INTO corelogic_usda.corelogic_usda_deed_2020_06_27_tax
FROM corelogic_usda.corelogic_usda_deed_2020_06_27
WHERE fips != '' AND pcl_id_iris_formatted != '';

-- add tax foreign key
ALTER TABLE corelogic_usda.corelogic_usda_deed_2020_06_27_tax
ADD CONSTRAINT deed_tax_id_fk
FOREIGN KEY (fips, pcl_id_iris_formatted)
REFERENCES corelogic_usda.corelogic_usda_deed_2020_06_27_id(fips, pcl_id_iris_formatted);

-- add tax index
CREATE INDEX tax_fk_idx ON corelogic_usda.corelogic_usda_deed_2020_06_27_tax (fips, pcl_id_iris_formatted);

ALTER TABLE corelogic_usda.corelogic_usda_deed_2020_06_27_tax ADD COLUMN recording_year INTEGER;

UPDATE corelogic_usda.corelogic_usda_deed_2020_06_27_tax SET recording_year = cast(LEFT(recording_date_yyyymmdd, 4) AS INTEGER);

CREATE INDEX deed_tax_recyr_idx ON corelogic_usda.corelogic_usda_deed_2020_06_27_tax (recording_year);





