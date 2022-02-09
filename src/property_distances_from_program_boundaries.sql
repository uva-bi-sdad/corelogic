


-- Create table of property data converted to CRS 26918 (to work in meters), index geo for spatial joins
select geoid_cnty, p_id_iris_frmtd, st_transform(geometry, 26918) geometry
into corelogic_usda.current_tax_200627_latest_locs_geom_26918
from corelogic_usda.current_tax_200627_latest_all_add_vars_add_progs_geom_blk ctlaavapgb;

create index current_tax_200627_latest_locs_geom_26918_idx on corelogic_usda.current_tax_200627_latest_locs_geom_26918 using GIST (geometry);



-- Convert BIP Table to CRS 26918 (to work in meters), index geo
select *, st_transform(geometry, 26918) geom
into usda_bb.bip_program_areas_26918
from usda_bb.bip_program_areas bpa;

-- Add a line string representing the exterior ring of the POLYGON geometry
SELECT rusid, geom, ST_Collect(ST_ExteriorRing(ring_geom)) AS ring_geom
into usda_bb.bip_program_areas_ring_26918
FROM (SELECT "RUS_ID" rusid, geom, (ST_Dump(geom)).geom As ring_geom
			FROM usda_bb.bip_program_areas_26918) As foo
GROUP BY rusid, geom;

create index bip_with_ring_geom_idx on usda_bb.bip_program_areas_ring_26918 using GIST (ring_geom);
create index bip_with_ring_geom_26918_idx on usda_bb.bip_program_areas_ring_26918 using GIST (geom);


-- Create table of every property within 20 miles of a BIP boundary, index id, distance, and links to property table
select a.rusid, b.geoid_cnty, b.p_id_iris_frmtd, st_within(b.geometry, a.geom) in_rusid, min(st_distance(b.geometry, a.ring_geom)) dist_ring_meters
into usda_bb.bip_program_area_properties_20mi
from usda_bb.bip_program_areas_ring_26918 a
inner join corelogic_usda.current_tax_200627_latest_locs_geom_26918 b on st_dwithin(b.geometry, a.geom , 32186.88)
where a.rusid is not null
group by a.rusid, b.geoid_cnty, b.p_id_iris_frmtd, st_within(b.geometry, a.geom), st_distance(b.geometry, a.geom);

create index bip_20mi_geoid_cnty_idx on usda_bb.bip_program_area_properties_20mi (geoid_cnty);
create index bip_20mi_p_id_iris_frmtd_idx on usda_bb.bip_program_area_properties_20mi (p_id_iris_frmtd);


/*select bip."ProjectID", bip."RUS_ID", ctllg.geoid_cnty, ctllg.p_id_iris_frmtd, st_distance(ctllg.geometry, bip.geom) distance_meters
into usda_bb.bip_program_area_properties_20mi
from usda_bb.bip_program_areas_26918 bip
inner join corelogic_usda.current_tax_200627_latest_locs_geom_26918 ctllg on st_dwithin(ctllg.geometry, bip.geom , 32186.88);

alter table usda_bb.bip_program_area_properties_20mi rename column "RUS_ID" to bip_rusid;
alter table usda_bb.bip_program_area_properties_20mi rename column "distance_meters" to bip_dist_m;
create index bip_20mi_geoid_cnty_idx on usda_bb.bip_program_area_properties_20mi (geoid_cnty);
create index bip_20mi_p_id_iris_frmtd_idx on usda_bb.bip_program_area_properties_20mi (p_id_iris_frmtd);*/



-- Convert CC Table to CRS 26918 (to work in meters), index geo
select *, st_transform(geometry, 26918) geom
into usda_bb.cc_program_areas_26918
from usda_bb.cc_program_areas bpa;

-- Add a line string representing the exterior ring of the POLYGON geometry
SELECT rusid, geom, ST_Collect(ST_ExteriorRing(ring_geom)) AS ring_geom
into usda_bb.cc_program_areas_ring_26918
FROM (SELECT "RUSID" rusid, geom, (ST_Dump(geom)).geom As ring_geom
			FROM usda_bb.cc_program_areas_26918) As foo
GROUP BY rusid, geom;

create index cc_with_ring_geom_idx on usda_bb.cc_program_areas_ring_26918 using GIST (ring_geom);
create index cc_with_ring_geom_26918_idx on usda_bb.cc_program_areas_ring_26918 using GIST (geom);

-- create index cc_program_areas_26918_geom_idx on usda_bb.cc_program_areas_26918 using gist(geom);


-- Create table of every property within 20 miles of a CC boundary, index id, distance, and links to property table
select a.rusid, b.geoid_cnty, b.p_id_iris_frmtd, st_within(b.geometry, a.geom) in_rusid, min(st_distance(b.geometry, a.ring_geom)) dist_ring_meters
into usda_bb.cc_program_area_properties_20mi
from usda_bb.cc_program_areas_ring_26918 a
inner join corelogic_usda.current_tax_200627_latest_locs_geom_26918 b on st_dwithin(b.geometry, a.geom , 32186.88)
where a.rusid is not null
group by a.rusid, b.geoid_cnty, b.p_id_iris_frmtd, st_within(b.geometry, a.geom), st_distance(b.geometry, a.geom);

create index cc_20mi_geoid_cnty_idx on usda_bb.cc_program_area_properties_20mi (geoid_cnty);
create index cc_20mi_p_id_iris_frmtd_idx on usda_bb.cc_program_area_properties_20mi (p_id_iris_frmtd);

-- st_distance(b.geometry, a.geom) dist_meters,


-- select cpa."OBJECTID", cpa."RUSID", ctllg.geoid_cnty, ctllg.p_id_iris_frmtd, st_distance(ctllg.geometry, cpa.geom) distance_meters
-- into usda_bb.cc_program_area_properties_20mi
-- from usda_bb.cc_program_areas_26918 cpa
-- inner join corelogic_usda.current_tax_200627_latest_locs_geom_26918 ctllg on st_dwithin(ctllg.geometry, cpa.geom , 32186.88);



-- Convert RC Table to CRS 26918 (to work in meters), index geo
select *, st_transform(geometry, 26918) geom
into usda_bb.rc_program_areas_26918
from usda_bb.rc_program_areas;

-- Add a line string representing the exterior ring of the POLYGON geometry
SELECT rusid, geom, ST_Collect(ST_ExteriorRing(ring_geom)) AS ring_geom
into usda_bb.rc_program_areas_ring_26918
FROM (SELECT "RUS_ID" rusid, geom, (ST_Dump(geom)).geom As ring_geom
			FROM usda_bb.rc_program_areas_26918) As foo
GROUP BY rusid, geom;

create index rc_with_ring_geom_idx on usda_bb.rc_program_areas_ring_26918 using GIST (ring_geom);
create index rc_with_ring_geom_26918_idx on usda_bb.rc_program_areas_ring_26918 using GIST (geom);


-- Create table of every property within 20 miles of a RC boundary, index id, distance, and links to property table
select a.rusid, b.geoid_cnty, b.p_id_iris_frmtd, st_within(b.geometry, a.geom) in_rusid, min(st_distance(b.geometry, a.ring_geom)) dist_ring_meters
into usda_bb.rc_program_area_properties_20mi
from usda_bb.rc_program_areas_ring_26918 a
inner join corelogic_usda.current_tax_200627_latest_locs_geom_26918 b on st_dwithin(b.geometry, a.geom , 32186.88)
where a.rusid is not null
group by a.rusid, b.geoid_cnty, b.p_id_iris_frmtd, st_within(b.geometry, a.geom), st_distance(b.geometry, a.geom);

create index rc_20mi_geoid_cnty_idx on usda_bb.rc_program_area_properties_20mi (geoid_cnty);
create index rc_20mi_p_id_iris_frmtd_idx on usda_bb.rc_program_area_properties_20mi (p_id_iris_frmtd);


-- Convert TCF Table to CRS 26918 (to work in meters), index geo
select *, st_transform(geometry, 26918) geom
into usda_bb.tcf_program_areas_26918
from usda_bb.tcf_program_areas;

-- Add a line string representing the exterior ring of the POLYGON geometry
SELECT rusid, geom, ST_Collect(ST_ExteriorRing(ring_geom)) AS ring_geom
into usda_bb.tcf_program_areas_ring_26918
FROM (SELECT "RUS_ID" rusid, geom, (ST_Dump(geom)).geom As ring_geom
			FROM usda_bb.tcf_program_areas_26918) As foo
GROUP BY rusid, geom;

create index tcf_with_ring_geom_idx on usda_bb.tcf_program_areas_ring_26918 using GIST (ring_geom);
create index tcf_with_ring_geom_26918_idx on usda_bb.tcf_program_areas_ring_26918 using GIST (geom);


-- Create table of every property within 20 miles of a TCF boundary, index id, distance, and links to property table
select a.rusid, b.geoid_cnty, b.p_id_iris_frmtd, st_within(b.geometry, a.geom) in_rusid, min(st_distance(b.geometry, a.ring_geom)) dist_ring_meters
into usda_bb.tcf_program_area_properties_20mi
from usda_bb.tcf_program_areas_ring_26918 a
inner join corelogic_usda.current_tax_200627_latest_locs_geom_26918 b on st_dwithin(b.geometry, a.geom , 32186.88)
where a.rusid is not null
group by a.rusid, b.geoid_cnty, b.p_id_iris_frmtd, st_within(b.geometry, a.geom), st_distance(b.geometry, a.geom);

create index tcf_20mi_geoid_cnty_idx on usda_bb.tcf_program_area_properties_20mi (geoid_cnty);
create index tcf_20mi_p_id_iris_frmtd_idx on usda_bb.tcf_program_area_properties_20mi (p_id_iris_frmtd);


-- Convert TCI Table to CRS 26918 (to work in meters), index geo
select *, st_transform(geometry, 26918) geom
into usda_bb.tci_program_areas_26918
from usda_bb.tci_program_areas;

SELECT rusid, geom, ST_Collect(ST_ExteriorRing(ring_geom)) AS ring_geom
into usda_bb.tci_program_areas_ring_26918
FROM (SELECT "RUSID" rusid, geom, (ST_Dump(geom)).geom As ring_geom
			FROM usda_bb.tci_program_areas_26918) As foo
GROUP BY rusid, geom;

create index tci_with_ring_geom_idx on usda_bb.tci_program_areas_ring_26918 using GIST (ring_geom);
create index tci_with_ring_geom_26918_idx on usda_bb.tci_program_areas_ring_26918 using GIST (geom);


-- Create table of every property within 20 miles of a TCI boundary, index id, distance, and links to property table
select a.rusid, b.geoid_cnty, b.p_id_iris_frmtd, st_within(b.geometry, a.geom) in_rusid, min(st_distance(b.geometry, a.ring_geom)) dist_ring_meters
into usda_bb.tci_program_area_properties_20mi
from usda_bb.tci_program_areas_ring_26918 a
inner join corelogic_usda.current_tax_200627_latest_locs_geom_26918 b on st_dwithin(b.geometry, a.geom , 32186.88)
where a.rusid is not null
group by a.rusid, b.geoid_cnty, b.p_id_iris_frmtd, st_within(b.geometry, a.geom), st_distance(b.geometry, a.geom);

create index tci_20mi_geoid_cnty_idx on usda_bb.tci_program_area_properties_20mi (geoid_cnty);
create index tci_20mi_p_id_iris_frmtd_idx on usda_bb.tci_program_area_properties_20mi (p_id_iris_frmtd);


-- Create single table of all properties within 20 miles of USDA broadband program boundaries, add indexes for link and search
select *
into usda_bb.rus_program_property_distances_to_20mi_b
from
(
select * from
(select 'BIP' rus_prog, rusid rus_id, geoid_cnty, p_id_iris_frmtd, in_rusid, round(dist_ring_meters::numeric/1609.344, 2) distance_mi
from usda_bb.bip_program_area_properties_20mi) a
union
select * from
(select 'CC' rus_prog, rusid rus_id, geoid_cnty, p_id_iris_frmtd, in_rusid, round(dist_ring_meters::numeric/1609.344, 2) distance_mi
from usda_bb.cc_program_area_properties_20mi) b
union
select * from
(select 'RC' rus_prog, rusid rus_id, geoid_cnty, p_id_iris_frmtd, in_rusid, round(dist_ring_meters::numeric/1609.344, 2) distance_mi
from usda_bb.rc_program_area_properties_20mi) c
union
select * from
(select 'TCF' rus_prog, rusid rus_id, geoid_cnty, p_id_iris_frmtd, in_rusid, round(dist_ring_meters::numeric/1609.344, 2) distance_mi
from usda_bb.tcf_program_area_properties_20mi) d
union
select * from
(select 'TCI' rus_prog, rusid rus_id, geoid_cnty, p_id_iris_frmtd, in_rusid, round(dist_ring_meters::numeric/1609.344, 2) distance_mi
from usda_bb.tci_program_area_properties_20mi) e
) t;

create index rppd_20_prop_idx on usda_bb.rus_program_property_distances_to_20mi (geoid_cnty, p_id_iris_frmtd);
create index rppd_20_rusid_idx on usda_bb.rus_program_property_distances_to_20mi (rus_id);
create index rppd_20_rusprog_idx on usda_bb.rus_program_property_distances_to_20mi (rus_prog);








select tcf."RUS_ID", ctllg.geoid_cnty, ctllg.p_id_iris_frmtd, st_distance(ctllg.geometry, tcf.geom) distance_meters, st_distance(ctllg.geometry, ST_ExteriorRing((ST_Dump(geom)).geom)) dist_ring
into usda_bb.tcf_ring_test
from usda_bb.tcf_program_areas_26918 tcf
inner join corelogic_usda.current_tax_200627_latest_locs_geom_26918 ctllg on st_dwithin(ctllg.geometry, tcf.geom , 32186.88);


select ST_Collect(ST_ExteriorRing(tcf.geom)) dist_ring
from usda_bb.tcf_program_areas_26918 tcf
limit 5;

select tcf.geom dist_ring
from usda_bb.tcf_program_areas_26918 tcf
limit 5;

select ST_ExteriorRing(the_geom) dist_ring
from (
SELECT "RUS_ID" , ST_ExteriorRing((ST_Dump(geom)).geom) As the_geom
FROM usda_bb.tcf_program_areas_26918 tcf
limit 1) t;

SELECT *, ST_ExteriorRing((ST_Dump(geom)).geom) As ring_geom
into usda_bb.tcf_with_ring_geom
FROM usda_bb.tcf_program_areas_26918 tcf;

create index tcf_with_ring_geom_idx on usda_bb.tcf_with_ring_geom using GIST (ring_geom);
create index tcf_with_ring_geom_26918_idx on usda_bb.tcf_with_ring_geom using GIST (geom);

select tcf."RUS_ID", ctllg.geoid_cnty, ctllg.p_id_iris_frmtd, st_within(ctllg.geometry, tcf.geom) within_prog, st_distance(ctllg.geometry, tcf.geom) distance_meters, min(st_distance(ctllg.geometry, tcf.ring_geom)) dist_ring
into usda_bb.tcf_ring_test_4
from usda_bb.tcf_with_ring_geom tcf
inner join corelogic_usda.current_tax_200627_latest_locs_geom_26918 ctllg on st_dwithin(ctllg.geometry, tcf.geom , 32186.88)
where tcf."RUS_ID" is not null
group by tcf."RUS_ID", ctllg.geoid_cnty, ctllg.p_id_iris_frmtd, st_within(ctllg.geometry, tcf.geom), st_distance(ctllg.geometry, tcf.geom);




SELECT "RUSID", geom, ST_Collect(ST_ExteriorRing(ring_geom)) AS ring_geom
into usda_bb.cc_program_areas_ring_26918
FROM (SELECT "RUSID", geom, (ST_Dump(geom)).geom As ring_geom
			FROM usda_bb.cc_program_areas_26918) As foo
GROUP BY "RUSID", geom;

create index cc_with_ring_geom_idx on usda_bb.cc_program_areas_ring_26918 using GIST (ring_geom);
create index cc_with_ring_geom_26918_idx on usda_bb.cc_program_areas_ring_26918 using GIST (geom);

select tcf."RUSID", ctllg.geoid_cnty, ctllg.p_id_iris_frmtd, st_within(ctllg.geometry, tcf.geom) within_prog, st_distance(ctllg.geometry, tcf.geom) distance_meters, min(st_distance(ctllg.geometry, tcf.ring_geom)) dist_ring
into usda_bb.cc_ring_test
from usda_bb.cc_program_areas_ring_26918 tcf
inner join corelogic_usda.current_tax_200627_latest_locs_geom_26918 ctllg on st_dwithin(ctllg.geometry, tcf.geom , 32186.88)
where tcf."RUSID" is not null
group by tcf."RUSID", ctllg.geoid_cnty, ctllg.p_id_iris_frmtd, st_within(ctllg.geometry, tcf.geom), st_distance(ctllg.geometry, tcf.geom);






SELECT
  geoid_cnty,
  geoid_blk,
  p_id_iris_frmtd,
  property_indicator,
  acres,
  land_square_footage,
  bldg_code,
  building_square_feet,
  living_square_feet,
  year_built,
  effective_year_built,
  bedrooms,
  baths_appraised,
  situs_address property_address,
  sale_price,
  sale_date,
  sale_year,
  transaction_type,
  property_centroid_latitude,
  property_centroid_longitude
INTO
  corelogic_usda.real_estate_sales_final_characteristics
FROM
  corelogic_usda.current_tax_200627_latest_all_add_vars_add_progs_geom_blk
WHERE
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
 baths_appraised IS NOT NULL
AND
  sale_year BETWEEN 2006 AND 2018;

ALTER TABLE corelogic_usda.real_estate_sales_final_characteristics ADD PRIMARY KEY (geoid_cnty, p_id_iris_frmtd);
create index fnl_char_sale_year_idx on corelogic_usda.real_estate_sales_final_characteristics (sale_year);
create index fnl_char_sale_year_baths on corelogic_usda.real_estate_sales_final_characteristics (baths_appraised);
create index fnl_char_sale_year_beds on corelogic_usda.real_estate_sales_final_characteristics (bedrooms);
create index fnl_char_sale_year_trantype on corelogic_usda.real_estate_sales_final_characteristics (transaction_type);
create index fnl_char_sale_year_blk on corelogic_usda.real_estate_sales_final_characteristics (geoid_blk);


-- number of arms-length sales
SELECT
  distinct geoid_cnty, p_id_iris_frmtd
FROM
  corelogic_usda.current_tax_200627_latest_all_add_vars_add_progs_geom_blk
WHERE
  property_indicator = '10'
AND
  transaction_type != '9'


