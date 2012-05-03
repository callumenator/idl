

pro get_zone_lat_lon, zone, metaData, windData, lat, lon, $
					  aziPlus=aziPlus, useAltitude=useAltitude

	if not keyword_set(aziPlus) then aziPlus = 0.

	case metaData.wavelength_nm of
		557.7: alt = 120.
		589.0: alt = 92.
		630.0: alt = 240.
		else: stop
	endcase

	if keyword_set(useAltitude) then alt = useAltitude

	pdist = get_great_circle_length(windData[0].zeniths[zone], alt)
	latlon = get_end_lat_lon(metaData.latitude, metaData.longitude, pdist, windData[0].azimuths[zone] + aziPlus)

	lat = latlon[*,0]
	lon = latlon[*,1]

end