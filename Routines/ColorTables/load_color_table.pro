
pro load_color_table, name
	path = where_is('color_tables')
	restore, path + name
	tvlct, r, g, b
end