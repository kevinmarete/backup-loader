/*Install List*/
DROP VIEW IF EXISTS vw_install_list;
CREATE VIEW vw_install_list AS
	SELECT 
		f.mflcode, 
		f.name facility, 
		c.name county, 
		sb.name subcounty, 
		p.name partner,
		f.category classification,
		IF(i.is_internet = 1, 'Yes', 'No') has_internet,
		i.version adt_version,
		IF(b.id IS NOT NULL, 'Yes', 'No') has_backup,
		i.active_patients,
		i.contact_name contact_name,
		REPLACE(i.contact_phone, '254','0') contact_phone,
		CONCAT_WS(' ', u.firstname, u.lastname) assigned_to
	FROM tbl_install i
	INNER JOIN tbl_facility f ON f.id = i.facility_id
	INNER JOIN tbl_subcounty sb ON sb.id = f.subcounty_id
	INNER JOIN tbl_county c ON c.id = sb.county_id
	INNER JOIN tbl_partner p ON p.id = f.partner_id
	INNER JOIN tbl_user u ON u.id = i.user_id
	LEFT JOIN tbl_backup b ON b.facility_id = i.facility_id
	GROUP BY i.facility_id;

/*Central Site List*/
DROP VIEW IF EXISTS vw_central_site_list;
CREATE VIEW vw_central_site_list AS
	SELECT 
	    f.name facility,
	    c.name county,
	    sb.name sub_county,
	    p.name partner,
	    IF(i.id IS NOT NULL, 'Yes', 'No') has_install,
	    i.version adt_version,
	    IF(i.is_internet = 1, 'Yes', 'No') has_internet,
	    IF(b.id IS NOT NULL, 'Yes', 'No') has_backup,
	    i.active_patients,
	    CONCAT_WS(' ', u.firstname, u.lastname) coordinator
	FROM tbl_facility f 
	INNER JOIN tbl_subcounty sb ON sb.id = f.subcounty_id
	INNER JOIN tbl_county c ON c.id = sb.county_id
	INNER JOIN tbl_partner p ON p.id = f.partner_id
	LEFT JOIN tbl_install i ON f.id = i.facility_id
	LEFT JOIN tbl_backup b ON b.facility_id = i.facility_id
	LEFT JOIN tbl_user u ON u.id = i.user_id
	WHERE f.category LIKE '%central%'
	GROUP BY f.id;

/*CDRR Item List*/
DROP VIEW IF EXISTS vw_cdrr_list;
CREATE VIEW vw_cdrr_list AS
	SELECT 
	    f.name facility,
	    f.category category,
	    CASE 
	    	WHEN f.category = 'central' AND c.code = 'D-CDRR' THEN 'D-CDRR'
	    	WHEN f.category = 'standalone' AND c.code = 'F-CDRR' THEN 'F-CDRR_packs'
	    	ELSE 'F-CDRR_units'
	    END AS code,
	    co.name county,
	    sb.name subcounty,
	    p.name partner,
	    YEAR(c.period_begin) data_year,
	    DATE_FORMAT(c.period_begin, '%b') data_month,
	    c.period_begin data_date,
	    d.name drug,
	    ci.dispensed_packs consumed,
	    ci.qty_allocated allocated
	FROM tbl_cdrr c
	INNER JOIN tbl_maps m ON m.facility_id = c.facility_id AND m.period_begin = c.period_begin AND m.period_end = c.period_end AND SUBSTRING(m.code, 1, 1) = SUBSTRING(c.code, 1, 1)
	INNER JOIN tbl_cdrr_item ci ON ci.cdrr_id = c.id
	INNER JOIN tbl_facility f ON f.id = c.facility_id
	INNER JOIN tbl_subcounty sb ON sb.id = f.subcounty_id
	INNER JOIN tbl_county co ON co.id = sb.county_id
	INNER JOIN tbl_partner p ON p.id = f.partner_id
	INNER JOIN vw_drug_list d On d.id = ci.drug_id
	GROUP BY ci.id;

/*MAPS Item List*/
DROP VIEW IF EXISTS vw_maps_list;
CREATE VIEW vw_maps_list AS
	SELECT 
	    f.name facility,
	    f.category category,
	    m.code code,
	    co.name county,
	    sb.name subcounty,
	    p.name partner,
	    YEAR(m.period_begin) data_year,
	    DATE_FORMAT(m.period_begin, '%b') data_month,
	    m.period_begin data_date,
	    r.name regimen,
	    r.service regimen_service,
	    r.category regimen_category,
	    mi.total
	FROM tbl_maps m
	INNER JOIN tbl_cdrr c ON c.facility_id = m.facility_id AND c.period_begin = m.period_begin AND c.period_end = m.period_end AND SUBSTRING(c.code, 1, 1) = SUBSTRING(m.code, 1, 1)
	INNER JOIN tbl_maps_item mi ON mi.maps_id = m.id
	INNER JOIN tbl_facility f ON f.id = m.facility_id
	INNER JOIN tbl_subcounty sb ON sb.id = f.subcounty_id
	INNER JOIN tbl_county co ON co.id = sb.county_id
	INNER JOIN tbl_partner p ON p.id = f.partner_id
	INNER JOIN vw_regimen_list r On r.id = mi.regimen_id
	GROUP BY mi.id;