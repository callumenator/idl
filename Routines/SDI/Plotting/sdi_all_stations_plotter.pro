
;\\ The all stations plotters will create a directory tree (under the top level dir specified
;\\ by output_path) with sub dirs for day, wavelength, and plot type (monostatic, bistatic, etc).
;\\ So if you specify c:\users\blah as output_path, look for plots in c:\users\blah\daynum\lambda\bistatic.

pro sdi_all_stations_plotter

	;\\ This structure can be optionally supplied as keyword 'options', to control
	;\\ various things inside sdi_all_stations_wind_fields

	options = {	lat:0,	$ 		;\\ center geo lat of map (0 = use mean lat)
			   	lon:0, $		;\\ center geo lon of map (0 = use mean lon)
			   	zoom:5.5, $		;\\ zoom factor of map
				scale:1E3, $	;\\ wind vectors multiplied by this for plotting
				continent_color:[50,0], ocean_color:[0,0], $	;\\ color of map continents and ocean [color, ctable]
				outline_color:[90,0], grid_color:[0, 100], $	;\\ color of map coastlines and geomag grid
				bounds:[0,0,1,1], $			;\\ page bounds (normal coords) of the map
				arrow_head_size:5, $		;\\ size of the vector arrow heads
				arrow_thick:1, $			;\\ arrow thickness
				winx:600, $					;\\ for png, x size of the image
				winy:600, $					;\\ for png, y size of the image
				text_color:255, $			;\\ text color for map annotations
				chars:0.7, $				;\\ for eps, character size of text
				output_path:'', $			;\\ used internally
				output_subdir:'', $			;\\ used internally
				output_name:'', $			;\\ used internally
				bistatic_color:[255, 0], $	;\\ color of bistatic vectors (color, color table)
				tristatic_color:[255, 0], $	;\\ color of tristatic vectors (color, color table)
				mono_blend_color:[100, 0], $;\\ color of blended monostatic vectors (color, color table)
				bi_blend_color:[130, 8], $  ;\\ color of blended bistatic vectors (color, color table)
				pfisr_color:[50, 39], $		;\\ color of pfisr convection vectors (color, color table)
				site_colors:[{site_code:'PKR', color:[150,39]}, $
							 {site_code:'TLK', color:[230,39]}, $
							 {site_code:'HRP', color:[100,39]}, $
							 {site_code:'KTO', color:[190,39]}  ]}


	;\\ Example - make dial plots (as eps) and pngs of monostatic and bistatic winds for each
	;\\ of the given days, and return then monostatic gradients in variable 'grads'

	ydns = ['2012326', '2012329', '2012346', '2012350', '2012353', '2012356',$
			'2013009', '2013014', '2013017', '2013018', '2013019', '2013020']

	for i = 0, n_elements(ydns) - 1 do begin
		sdi_all_stations_wind_dial, ydn=ydns[i], output='c:\users\sdi\allstationsplots\', plot_type = 'eps'
		sdi_all_stations_wind_fields, ydn=ydns[i], output='c:\users\sdi\allstationsplots\', gradients=grads, /mono, /bi, options=options
	endfor


	;\\ Example - get the blended monostatic winds at a time resolution of 15 minutes
	;\\ between 10 and 12 UT, return the data in variable 'mb'
	sdi_all_stations_wind_fields, ydn='2012326', time_res = 15, time_range=[10,12], monoblend=mb

	;\\ Example - get the bistatic vertical winds
	sdi_all_stations_wind_fields, ydn='2012326', vertical = vz

end