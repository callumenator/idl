;	-----------------------------------------
;	COMMON block definitions for EUV_IMTOOL
;	-----------------------------------------
;       Last modified: 18-Dec-2003

COMMON objects, scene, scene3, scene4, sceneP,$
  imview, imview3, imview4, imviewPa,imviewPr,$
  immodel, immodel3, immodel4,immodelc, immodel3c, immodelc_full, $
  immodelPa,immodelPr,$
  image, image3, image4, contour, contour3,$
  rad_plot, az_plot,$
  rad_plot_z, az_plot_z,$
  xaxis_az, yaxis_az, xaxis_rad, yaxis_rad,$
  azline2, radline2, azline3, radline3,$
  mlt_label, l_label, log_label_a, log_label_r,$
  null_label_a, null_label_r, $
  center_ellipse, center_ellipse3, center_ellipse_full, $
  click_points, click_symbol, click_points3, center_symbol, $
  center_point, center_point3, center_point_full, click_points_full

COMMON widget, window, window3, window4,windowpa,windowpr,$
  readoutw, midpointw, imlatw, imlonw,$
  fullreadoutw,$
  immlatw, immlonw, rangew,$
  syearw, sdoyw, shourw, sminw,$
  forward_button, backward_button,forward_seek,$
  record_file, sort_file, filew, statw,$
  zoom_button,full_button,contour_button,center_button,$
  keep_button, plot_button, clear_button,cont_readout,$
  imxw, imyw, imzw, imxsmw, imysmw, imzsmw, minLw, mltw, mlnw,wspt,$
  fitsnamew, bminxw, bminyw, bmaxxw, bmaxyw,$
  wBase3, wBaseP, wBase4, dumpfilew, lsw, psw, mult_list, mult_list_label,$
  w_ra, w_dec, autocheck, sw_button, expand_button, wDraw3, menu_ids

COMMON skymap, xdim, ydim, xdim2, ydim2, xdim3, ydim3,$
  mxdim, mydim,$
  darray, darrayl, bigmap, dmap, working_dmap, full,$
  darray3, darray3l,$
  dtstart, dtend, center_x2, center_y2, center_x3, center_y3, $
  center_full_x, center_full_y, back_y1, back_y2, $
  original, workarray, y_expand

COMMON spacecraft, image_x, image_y, image_z,$
  image_vx, image_vy, image_vz,$
  image_smx, image_smy, image_smz,$
  image_smvx, image_smvy, image_smvz,$
  sun_x, sun_y, sun_z,$
  moon_x, moon_y, moon_z,$
  image_gci_lat, image_gci_lon, image_w_lon,$
  image_maglon, solarlong,$
  spin_axis_x, spin_axis_y, spin_axis_z, range, range_re, rotangle

COMMON misc, EARTH_RADIUS, VERSION, $
  quicklook, red, green, blue, centered,$
  warned, warning, deband, bminx, bmaxx, bminy, bmaxy, $
  subtract_back, ftime, zoom_on, overlay_contour, overlay_contour3,$
  zoom_window_exists, full_window_exists, ct_update, defining_center,$
  keep_center, $
  fitsbrowse, linear, user_xoff, xoff, udf_load_canceled, $
  defaults_in_current, sort_clicks, continuous_readout, dlmflag,$
  batch_bkg_sub,$
  range0, ref_image, auto_center, cbias, bias_choices, bias_droplist,$
  backingstore, n_overlap, warned2, warning2, expanded_zoom, from_udf,$
  write_full_fits, full_frame, append_to_record, tau, warning3


COMMON fits, fits_file_array, nfitsfiles, current_fits

COMMON time, s0year, s0doy, s0hour, s0min, s0sec,jd,$
  start_year, start_doy, start_hour, start_minute,start_second,$
  next_year, next_doy, next_hour, next_minute, next_second,$
  prev_year, prev_doy, prev_hour, prev_minute, prev_second,$
  prev_set

COMMON orbit, orb, orb1, orb2

COMMON trans, t1,t2,t3,t4,t5, mtrans

COMMON batch, yf1, df1, hf1, mf1, yf2, df2, hf2, mf2, jdf1, jdf2

COMMON plots, xplotsize, yplotsize, do_plots, plot_window_exists,$
  naz, az, azbrite, nrad, rad, radbrite, del_x, del_y, del_ang, circ, $
  ra_log_scale, azbrite_zoom, radbrite_zoom, multiplier, multiplier_choices,$
  plot_stretch

COMMON click, xclick, yclick, xclick3, yclick3, xclick_full, yclick_full, nclicks, click_in_full


COMMON events, mouse_x, mouse_y, center_x, center_y, mouse_l, mouse_mlt,$
  from_zoom_win

COMMON contour, cnlevels, cminval, cmaxval

COMMON wind, sfdatafile, kpdatafile, dstdatafile, found_solar_data, plot_sw_data,$
  sw_plot_exists, sf_base, loaded_solar_data


