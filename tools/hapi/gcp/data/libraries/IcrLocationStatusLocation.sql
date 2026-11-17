SELECT h.* FROM hierarchy AS h WHERE h.is_admin AND h.id IN (SELECT location_id FROM location_status)
