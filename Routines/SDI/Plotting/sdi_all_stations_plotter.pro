
pro sdi_all_stations_plotter

	options = {	lat:65,	$ 		;\\ center geo lat of map
			   	lon:-147, $		;\\ center geo lon of map
			   	zoom:5.5, $		;\\ zoom factor of map
				scale:1E3, $	;\\ wind vectors multiplied by this for plotting
				continent_color:[50,0], ocean_color:[0,0], $	;\\ color of map continents
				outline_color:[90,0], grid_color:[0, 100], $	;\\ color of map coastlines
				bounds:[0,0,1,1], $			;\\ page bounds (normal coords) of the map
				arrow_head_size:5, $		;\\ size of the vector arrow heads
				winx:600, $					;\\ for png, x size of the image
				winy:600, $					;\\ for png, y size of the image
				text_color:255, $			;\\ text color for map annotations
				chars:0.7, $				;\\ for eps, character size of text
				output_path:output_path, $	;\\ root path where plot subdirs are made
				output_subdir:'', $			;\\ used internally
				output_name:'', $			;\\ used internally
				bistatic_color:[255, 0], $	;\\ color of bistatic vectors (color, color table)
				tristatic_color:[255, 0], $	;\\ color of tristatic vectors (color, color table)
				blend_color:[100, 0], $		;\\ color of blended monostatic vectors (color, color table)
				pfisr_color:[50, 39], $		;\\ color of pfisr convection vectors (color, color table)
				site_colors:[{site_code:'PKR', color:[150,39]}, $
							 {site_code:'TLK', color:[230,39]}, $
							 {site_code:'HRP', color:[100,39]}, $
							 {site_code:'KTO', color:[190,39]}  ]}


	;\\ Example - generate monostatic, bistatic and tristatic png's for 2012 335,
	;\\ save images in root dir c:\users\sdi\AllStationPlots\. Automatically calculate
	;\\ time range and resolution. No all-sky or pfisr convection data

	ydn = '2012335'
	opts = options
	plot_type = 'png'
	monostatic = 1
	bistatic = 1
	tristatic = 1
	output_path = 'c:\users\sdi\AllStationPlots\'

	sdi_all_stations_wind_fields, ydn=ydn, $
								  options=opts, $
								  monostatic=monostatic, $
								  bistatic=bistatic, $
								  tristatic=tristatic, $
								  plot_type=plot_type, $
								  output_path=output_path

end