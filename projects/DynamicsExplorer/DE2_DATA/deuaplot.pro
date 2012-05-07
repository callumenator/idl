;*  Dynamics Explorer UA data Plot program                            *;
;*                                                                    *;
;*  Mark Conde, Fairbanks, April, 1996.                               *;
;=======================================================================
; Initialise the program's global state, which is stored in common blocks:

pro deua_data_init

@deua_inc.pro


; Obtain a description of the current working directory:
cd, '', current=entry_dir
entry_dir = 'c:\cal\idlsource\de2_data\de2_data\'
cd, entry_dir

; Initialise the common block variables:


uarec = {s_ua, _date: 82001, $
               time_ut: 0.d, $
               _orbit: 0, $
               altitude: 500., $
               latitude: 80., $
               longitude: 0., $
               loc_sol_time: 0., $
               loc_mag_time: 0., $
               L_shell: 0., $
               inv_latitude: 0., $
               sol_zen_angle: 0., $
               N2_density: 0., $
               O_density: 0., $
               HE_density: 0., $
               AR_density: 0., $
               N_density: 0., $
               neutral_temp: 0., $
               eastward_wind: 0, $
               upward_wind: 0, $
               plasma_dens: 0., $
               electron_temp: 0., $
               _fpi_wavelength: 0., $
               fpi_tang_alt: 0., $
               northward_wind: 0., $
               fpi_temperature: 0., $
               fpi_intensity: 0., $
               ion_temp: 0., $
               ion_density: 0., $
               eastward_ion_drift: 0., $
               northward_ion_drift: 0., $
               upward_ion_drift:0.}

units = {s_uts, date: ' [yyddd]', $
                time_ut: ' [hr]', $
                orbit:  '', $
                altitude: ' [km]', $
                latitude: ' [deg]', $
                longitude: ' [deg]', $
                local_solar_time: ' [hr]', $
                local_magnetic_time: ' [hr]', $
                L_shell: '', $
                invariant_latitude: ' [deg]', $
                solar_zenith_angle: ' [deg]', $
                N2_density: ' [cm-3]', $
                O_density: ' [cm-3]', $
                HE_density: ' [cm-3]', $
                AR_density: ' [cm-3]', $
                N_density: ' [cm-3]', $
                neutral_temperature: ' [K]', $
                eastward_wind: ' [m/s]', $
                upward_wind: ' [m/s]', $
                plasma_density: ' [cm-3]', $
                electron_temperature: ' [K]', $
                fpi_wavelength: ' [Angstrom]', $
                fpi_tangent_altitude: ' [km]', $
                northward_wind: ' [m/s]', $
                fpi_temperature: ' [K]', $
                fpi_intensity: ' [Rayleighs]', $
                ion_temperature: ' [K]', $
                ion_density: ' [cm-3]', $
                eastward_ion_drift: ' [m/s]', $
                northward_ion_drift: ' [m/s]', $
                upward_ion_drift: ' [m/s]'}

ua   =  replicate(uarec, 1)
widz   = {s_wid, top: 900l, $
                 mainmen: 901l, $
                 menu: 902l, $
                 dialogue: 903l, $
                 output: 904l, $
                 parlist: 905l, $
                 fname: 906l, $
                 choice: "", $
                 conf: 907l, $
                 legend: 908l, $
                 legitm: 909l, $
                 legwin: 997, $
                 dialz: lindgen(64), $
                 output_window: 999}
prn    = {s_prn, type: 'Color-PS'}
host   = {s_hst, windev: 'WIN', $
                 resln: intarr(2), $
                 outsize: intarr(2), $
                 legend_size: intarr(2), $
                 shades: 0, $
                 colsat: 0.95, $
                 entry_dir: entry_dir, $
                 ranseed: 0l, $
                 background: 0, $
                 text_line: 0, $
                 text_normtop: 0.95, $
                 text_normsep: 0.028, $
                 seq: intarr(256), $
                 idx:0 }
plot  = {s_plt,  parnamz:    strarr(64), $
                 limz:       fltarr(2, 32), $
                 temp_limz:  fltarr(2), $
                 map_pix:    intarr(2), $
                 coast_cull: 0, $
                 vecthick:   2, $
                 lidx:       0, $
                 xypt_style: -1, $
                 ypar_count: 0., $
                 plot_type: 'Scatter Plot', $
                 map_proj:  'North Polar Stereographic', $
                 vecfrac:    0.06, $
                 coltab:     34, $
                 gifnum:     0, $
                 filename:  'deuadata.asc', $
                 path:       entry_dir, $
                 hc: 0., $
                 hc_fix: 1.4}
parlist= strarr(64)

; establish the windowing environment:
if strmid(strupcase(!version.OS), 0, 3) ne 'WIN' then host.windev = 'X'
end


;=======================================================================
; Here we setup the top level menu for the 'deuaplot' program:

pro deua_setup_widgets

@deua_inc.pro
junk = {CW_PDMENU_S, flags: 0, name: 'Dummy'}


widz.top       = WIDGET_BASE   (title='Dynamics Explorer UA Data Plotter' , $
                               /frame, /column, space=10)
desc = [{CW_PDMENU_S, 1, 'File'}, $
        {CW_PDMENU_S, 0,   'Open'}, $
        {CW_PDMENU_S, 0,   'Clear Loaded Data'}, $
        {CW_PDMENU_S, 2,   'Exit'}, $
        {CW_PDMENU_S, 1, 'Configure'}, $
        {CW_PDMENU_S, 0,   'Interpolate Sparse Data'}, $
        {CW_PDMENU_S, 0,   'Project Densities to 300 km'}, $
        {CW_PDMENU_S, 1,   'XY Plotting'}, $
        {CW_PDMENU_S, 0,       'Joined Points'}, $
        {CW_PDMENU_S, 2,       'Isolated Points'}, $
        {CW_PDMENU_S, 0,   'Color Tables'}, $
        {CW_PDMENU_S, 0,   'Black Background'}, $
        {CW_PDMENU_S, 2,   'White Background'}, $
        {CW_PDMENU_S, 1, 'Display'}, $
        {CW_PDMENU_S, 0,   'View Results'}, $
        {CW_PDMENU_S, 2,   'Make GIF File'}, $
        {CW_PDMENU_S, 2, 'Help'}]

widz.mainmen = cw_pdmenu (widz.top, desc, $
                      /return_full_name, $
                       delimiter='|')
deua_build_fullname, fullname
widz.fname = widget_label (widz.top, $
                           value='Filename is: '+fullname)
WIDGET_CONTROL, widz.top, /realize

end

;=======================================================================
; This is the event handler for the deua plotting program.  All widget
; events come here.  We first call WIDGET_CONTROL for more info on the
; widget requesting service and then proceed to the explicit code
; for each request:

pro deua_event, event

@deua_inc.pro

widget_control, widz.top, /show
reserve_colors, shades

if (event.value eq 'File|Exit') then begin
    deua_clear_window, widz.top
endif
if (event.value eq 'File|Open') then begin
    deua_get_filename, ok, /read, /must_exist
    if (ok) then deua_load_data
endif
if (event.value eq 'File|Clear Loaded Data') then begin
    ua = ua(0)
endif
if (event.value eq 'Configure|Interpolate Sparse Data') then begin
    deua_data_interp
endif
if (event.value eq 'Configure|Project Densities to 300 km') then begin
    deua_density_proj
endif
if (event.value eq 'Configure|Color Tables') then begin
    xloadct, group=widz.top
endif
if (event.value eq 'Configure|XY Plotting|Joined Points') then begin
    plot.xypt_style = -1
endif
if (event.value eq 'Configure|XY Plotting|Isolated Points') then begin
    plot.xypt_style = 1
endif
if (event.value eq 'Configure|Black Background') then begin
    host.background = 0
    reserve_colors, shades
endif
if (event.value eq 'Configure|White Background') then begin
    host.background = 255
    reserve_colors, shades
endif
if (event.value eq 'Display|View Results') then begin
    deua_display_data
endif
if (event.value eq 'Display|Make GIF File') then begin
    deua_write_gif
endif
if (event.value eq 'Help') then begin
    xdisplayfile, 'Help', group=widz.top, $
    text=['Plotting Procedure:', $
          ' ', $
          '  1. Choose File|Open to load a data file', $
          '  2. Choose Display|View Results to visualize the data', $
          '  3. Use the display options dialogue box to refine your plot', $
          ' ', $
          '']
endif
if widget_info(widz.top, /valid_id) then $
   widget_control, widz.top, /show
end


pro deua_get_filename, success, must_exist=me, read=rd, write=wt
@deua_inc.pro
    path = ' '
    success = 0
    choice = pickfile(file=plot.filename, $
                      path=plot.path, get_path=path, $
                      filter='*.asc', $
                      must_exist=me, $
                      read=rd, $
                      write=wt)
    if strlen(choice) gt 0 then begin
       success=1
       plot.filename = choice
       if strpos(choice, path) eq 0 then $
          plot.filename = strmid(choice, strlen(path), $
                               strlen(choice)-strlen(path))
       colon = strpos(plot.filename, ';')
       if colon ge 0 then $
          plot.filename = strmid(plot.filename, 0, colon)
       endch          = strmid(path, strlen(path)-1, 1)
       if (endch eq '\' or endch eq '/') then $
           path = strmid(path, 0, strlen(path)-1)
       plot.path     = path
    endif
    deua_build_fullname, fullname
    widget_control,  widz.fname, $
                     set_value='File: '+fullname
end

pro deua_build_fullname, fullname
@deua_inc.pro
    path = plot.path
    if strpos(path, '\') ge 0 then path = path + '\'
    fullname = path + plot.filename
end

pro deua_info_screen, message
@deua_inc.pro
    if widget_info(widz.output, /valid_id) then begin
       wset, widz.output_window
       erase
    endif else begin
       deua_open_outwin, /make_draw, aspect=1.1
    endelse
    wset, widz.output_window
    flis = findfile('*.bmp')
    nfils= n_elements(flis)
    if host.idx eq 0 then begin
       dummy = randomu(seed)
       host.seq(0:nfils-1) = sort(randomu(seed, nfils))
    endif
    host.idx = host.idx + 1
    if host.idx eq nfils then host.idx = 0
    niceview = read_bmp(flis(host.seq(host.idx)), r, g, b)
    tvlct, r, g, b
    reserve_colors, shades, /black
    vw = host.outsize
    im = [n_elements(niceview(*,0)), n_elements(niceview(0,*))]
    xpos = (vw(0) - im(0))/2 > 0
    ypos = (vw(1) - im(1))/1.2 > 0
    tv, niceview, xpos, ypos, /device
    xyouts, vw(0)/2, ypos/2, message, /device, $
            align=0.5, charsize=2.5, charthick=2, color=shades-1
end


pro deua_load_data
@deua_inc.pro
    on_ioerror, no_file_load
    namesave = plot.filename
    pathsave = plot.path
    fail     = 1
    uain     = ua(0)
    parin    = 1.D
    inline   = 'test'
    get_lun,  pltun
    deua_clear_window, widz.output
    deua_build_fullname, fullname
    openr,    pltun, fullname, /get_lun
    rex      = 0
    while not eof(pltun) do begin
              if rex/100. - fix(rex/100) lt 0.001 then $
                 deua_info_screen, 'Reading Data: ' + strcompress(string(rex))
              readf, pltun, inline
              inline = strcompress(inline)
              inline = strtrim(inline, 2)
              pars = str_sep(inline, ' ')
              for par=0,n_elements(pars)-1 do begin
                  parstr = pars(par)
                  reads, parstr, parin
                  if par eq 1 then parin = float(parin/3600000l)
                  uain.(par) = parin
              endfor
              ua = [ua, uain]
              rex = rex + 1
    endwhile
    plot.hc = 0.
    ua = ua(1:*)
    close,    pltun
    free_lun, pltun
    deua_clear_window, widz.output
    deua_loadct
    fail = 0
    no_file_load: if (fail) then print, '>>> ERROR: Unable to load simulation'
end

pro deua_print_setup
@deua_inc.pro
    tags = tag_names(ua(0))
    print, '================================================================='
    print, ' '
    print, '                    Plot Settings'
    print, ' '

    for field=0,n_elements(tags)-1 do begin
        print, 'Plot Setting: ', tags(field)
;       help, /structure, plot.(field)
        print, plot.(field)
    endfor
    print, ' '
end


pro deua_confirm, title, default, confirmation
@deua_inc.pro
    deua_clear_window, widz.dialogue
    deua_open_window, widx, title & widz.dialogue=widx
    widz.output_window = !D.window
    buttons = ['>>No<<', '>>Yes<<']
    deua_scalar_menu, buttons
    confirmation = where(widz.choice eq buttons)
    confirmation = confirmation(0)
end

pro deua_clear_window, wot
@deua_inc.pro
    if widget_info(wot, /valid_id) then $
       widget_control, wot, /destroy
end

pro deua_scalar_menu, menulist, column=col
@deua_inc.pro
junk = {CW_PDMENU_S, flags: 0, name: 'Dummy'}
desc = replicate(junk, n_elements(menulist))
for j=0,n_elements(menulist)-1 do begin
    desc(j).name= menulist(j)
endfor
if keyword_set(col) then begin
   bcount = n_elements(menulist) - 1
   binc   = 1 + fix(bcount/12)
   for j  = 0,bcount-1,binc do begin
       j2 = j+binc < bcount-1
       widz.menu = cw_pdmenu (widz.dialogue, desc(j:j2), $
                             /return_full_name, $
                              delimiter='|')
   endfor
   widz.menu = cw_pdmenu (widz.dialogue, desc(bcount), $
                         /return_full_name, $
                          delimiter='|')
endif else $
       widz.menu = cw_pdmenu (widz.dialogue, desc, $
                             /return_full_name, $
                              delimiter='|')
WIDGET_CONTROL, widz.dialogue, /realize
xmanager, 'scalar_menu', widz.dialogue, group_leader=widz.top, /modal
end

pro scalar_menu_event, event
@deua_inc.pro
    widget_control, widz.top, /show
    widz.choice = event.value
    deua_clear_window, widz.dialogue
    widget_control, widz.top, /show
end

pro deua_build_parlist
@deua_inc.pro
    nok = -1
    parids = tag_names(ua(0))
    paruns = strarr(n_elements(parids))
    parsel = intarr(n_elements(parids))
    for par=0,n_elements(parids)-1 do begin
        ok = where(ua.(par) ne 0., nok)
        if nok gt 0 then parsel(par) = 1
        paruns(par) = units.(par)
    endfor
    keep = where(strpos(parids, '_') ne 0 and parsel eq 1)
    parids = parids(keep) +  paruns(keep) + ':  '
    sortseq = sort(parids)
    parids  = parids(sortseq)
    parnums = keep(sortseq)
end


pro deua_choose_parameter, parchoice, banner, dismiss=dsm
@deua_inc.pro
    lastb = 'Cancel'
    if keyword_set(dsm) then lastb = dsm
    deua_clear_window, widz.dialogue
    deua_build_parlist
    deua_open_window, widx, banner & widz.dialogue = widx
    parids    = [parids, lastb]
    parnums   = [parnums, -1]
    deua_scalar_menu, parids, /column
    parchoice = where(widz.choice eq parids)
    parchoice = parnums(parchoice(0))
end

pro deua_open_window, wot, title, xoffset=xf, yoffset=yf
@deua_inc.pro
if not keyword_set(xf) then xf = host.resln(0)/5
if not keyword_set(yf) then yf = host.resln(1)/5

    wot = widget_base(title=title, $
                      xoffset=xf, $
                      yoffset=yf, $
                      space=5, /column)
end

pro deua_gfx_ctl, outopts, gfxok, recsel
@deua_inc.pro
      deua_clear_window, widz.dialogue
      deua_open_window,  widx, 'Choose Display Option', $
                         xoffset=host.resln(0)*0.75, yoffset=host.resln(1)*.05
                         widz.dialogue = widx
      deua_scalar_menu, [outopts, 'Done'], /column
      gfxok = 1
      if widz.choice eq    'Orbit Range'                then $
         deua_set_limz, 0, 'Orbit'
      if widz.choice eq    'Next Orbit'                 then $
         deua_specific_orbit, recsel, /next
      if widz.choice eq    'Previous Orbit'             then $
         deua_specific_orbit, recsel, /previous
      if widz.choice eq    'Specific Orbit'             then $
         deua_specific_orbit, recsel
      if widz.choice eq    'Independent Variable Range' then $
         deua_set_limz, 1, 'Independent Variable'
      if widz.choice eq    'Dependent Variable Range'   then $
         deua_set_limz, 2, 'Dependent Variable'
      if widz.choice eq    'Interactive'   then $
         deua_interactive_output
      if widz.choice eq    'Done'                       then gfxok = -1
      reserve_colors, shades
end

pro deua_specific_orbit, recsel, next=nx, previous=pv
@deua_inc.pro
     orbhere = ua._orbit
     prevorb = -999
     orblis  = -1
     for k=0,n_elements(orbhere)-1 do begin
         if orbhere(k) ne prevorb then begin
            orblis  = [orblis, orbhere(k)]
            prevorb = orbhere(k)
         endif
     endfor
     orblis = orblis(1:n_elements(orblis)-1)
     nz     = 0
     orbok  = where(orblis ne 0, nz)
     orblis = strcompress(string(orblis), /remove_all)
     if nz gt 0 then orblis = orblis(orbok) else return

     gotorb = 0
     if keyword_set(nx) then begin
        thisorb = where(float(orblis) eq plot.limz(0,0), gotorb)
        if gotorb gt 0 then begin
           thisorb = thisorb(0) + 1
           if thisorb gt n_elements(orblis)-1 then thisorb = 0
           plot.limz(0,0) = float(orblis(thisorb))
           plot.limz(1,0) = float(orblis(thisorb))
        endif
     endif
     if keyword_set(pv) then begin
        thisorb = where(float(orblis) eq plot.limz(1,0), gotorb)
        if gotorb gt 0 then begin
           thisorb = thisorb(0) - 1
           if thisorb lt 0 then thisorb = n_elements(orblis)-1
           plot.limz(0,0) = float(orblis(thisorb))
           plot.limz(1,0) = float(orblis(thisorb))
        endif
     endif
     if gotorb gt 0 then return
     deua_clear_window, widz.dialogue
     deua_open_window,  widx, 'Select an Orbit', $
                        xoffset=host.resln(0)*0.75, yoffset=host.resln(1)*.05
                        widz.dialogue = widx
     deua_scalar_menu, [orblis, 'Cancel'], /column
     if widz.choice ne 'Cancel' then begin
        plot.limz(0,0) = float(widz.choice)
        plot.limz(1,0) = float(widz.choice)
     endif
end

pro deua_set_limz, lidx, wot
@deua_inc.pro
      if (lidx eq 2 and plot.ypar_count gt 1) then begin
          deua_clear_window, widz.dialogue
          deua_open_window,  widx, 'Set Limits for Which Parameter', $
                             xoffset=host.resln(0)*0.75, $
                             yoffset=host.resln(1)*.05
                             widz.dialogue = widx
          deua_scalar_menu, [plot.parnamz(2:plot.ypar_count+1), $
                            'Cancel'], /column
          lidx = where(widz.choice eq plot.parnamz)
          lidx = lidx(0)
      endif
      if lidx lt 0 then return
      plot.lidx = lidx
      plot.temp_limz = plot.limz(*, lidx)
      deua_clear_window, widz.dialogue
      deua_open_window,  widx, 'Choose ' + wot + ' Range', $
                         xoffset=host.resln(0)*0.75, yoffset=host.resln(1)*.05
                         widz.dialogue = widx
      widz.dialz(0) = cw_field (widz.dialogue, $
                                title='Minimum ' + plot.parnamz(lidx) + ' ', $
                                value=plot.limz(0,lidx), $
                               /frame, $
                                all_events=1, $
                               /string)
      widz.dialz(1) = cw_field (widz.dialogue, $
                                title='Maximum ' + plot.parnamz(lidx) + ' ', $
                                value=plot.limz(1,lidx), $
                               /frame, $
                                all_events=1, $
                               /string)
      button = [{CW_PDMENU_S, flags: 0, name: 'Done'}, $
                {CW_PDMENU_S, flags: 0, name: 'Cancel'}]
      widz.dialz(2)= cw_pdmenu (widz.dialogue, button, $
                               /return_full_name, $
                                delimiter='|')
      WIDGET_CONTROL, widz.dialogue, /realize
      xmanager, 'gfx_ctl', widz.dialogue, group_leader=widz.top, /modal
end


pro gfx_ctl_event, event
@deua_inc.pro
    widget_control, widz.top, /show
    processed = 0
    if event.value eq 'Done' then begin
       plot.limz(*, plot.lidx) = plot.temp_limz
       deua_clear_window, widz.dialogue
       processed = 1
    endif
    if event.value eq 'Cancel' then begin
       deua_clear_window, widz.dialogue
       processed = 1
    endif
    nmat  = 0
    match = where(event.id eq widz.dialz, nmat)
    match = match(0)
    if nmat gt 0  and not(processed) then begin
       plot.temp_limz(match) = event.value
    endif
    widget_control, widz.top, /show
end


pro deua_display_data
@deua_inc.pro
      deua_clear_window, widz.output
      deua_clear_window, widz.dialogue
      deua_open_window,  widx, 'Choose Output Option'
                        widz.dialogue = widx
      deua_scalar_menu, ['Scatter Plot', $
                         'Scalar Map', $
                         'Vector Map', $
                         'Color Modulated Vectors', $
                         'Deflection Plot', $
                         'Satellite Orbit', $
                         'Interactive',  'Cancel'], /column
      if widz.choice ne 'Cancel' then begin
         plot.plot_type  = widz.choice
         !p.region       = 0
         !p.position     = 0
         plot.limz       = 0
         plot.limz(*,0)  = [min(ua._orbit), max(ua._orbit)]
         plot.parnamz(0) = 'Orbit Number'
         plot.ypar_count = 0
         if widz.choice eq 'Scatter Plot'            then deua_scat_plot
         if widz.choice eq 'Scalar Map'              then deua_scalar_map
         if widz.choice eq 'Vector Map'              then deua_vector_map
         if widz.choice eq 'Color Modulated Vectors' then deua_colvec_map
         if widz.choice eq 'Deflection Plot'         then deua_deflection_plot
         if widz.choice eq 'Satellite Orbit'         then deua_orbit_plot
         if widz.choice eq 'Interactive'             then deua_interactive_output
      endif
end

pro deua_open_outwin, make_draw=dw, aspect=ap
@deua_inc.pro
     aspect = 1.2
     if keyword_set(ap) then aspect = ap
     xr  = host.resln(0)*aspect
     yr  = host.resln(0)
     shrink = 0.98*min(float(host.resln)/[xr, yr])
     xr = xr*shrink
     yr = yr*shrink
     host.outsize = [xr, yr]
     deua_clear_window, widz.output
     widz.output=widget_base(title='DE Unified Abstract Data', $
                             group_leader=widz.top, $
                             xoffset=(host.resln(0) - xr)*.05, $
                             yoffset=(host.resln(1) - yr)*.88)
     if keyword_set(dw) then begin
        widz.menu=widget_draw(widz.output, $
                              xsize=xr, $
                              ysize=yr)
     endif
     widget_control, widz.output, /realize
     if keyword_set(dw) then begin
        widget_control, widz.menu, get_value=windex
        widz.output_window = windex
     endif
end

pro deua_plot_pars, plotpars, axis, y_multiple
@deua_inc.pro
    plotpars = -1
    pnum = 1
    namz = tag_names(ua(0))
    base = 0
    if axis eq 'Y' then base = 1
    repeat begin
       banner = 'Specify ' + axis + ' parameter'
       if axis eq 'Y' and y_multiple then $
          banner = banner + ' No. ' + string(pnum)
       deua_choose_parameter, parchoice, banner, dismiss='   Apply   '
       plotpars = [plotpars, parchoice]
       if parchoice ge 0 then $
          plot.parnamz(base+pnum) = namz(parchoice) + units.(parchoice)
       pnum = pnum + 1
    endrep until (parchoice eq -1 or not y_multiple )
    if parchoice ne -1 then plotpars = plotpars(1:n_elements(plotpars)-1)
    if parchoice eq -1 then plotpars = plotpars(1:n_elements(plotpars)-2)
    if axis eq 'X' then begin
       nz = -1
       keep = where(ua.(plotpars(0)) ne 0., nz)
       if nz gt 0 then $
          plot.limz(*,1) = [min(ua(keep).(plotpars(0))), $
                            max(ua(keep).(plotpars(0)))]
    end
    if axis eq 'Y' then begin
       plot.ypar_count    = n_elements(plotpars)
       for j=0,plot.ypar_count-1 do begin
           nz = -1
           keep = where(ua.(plotpars(j)) ne 0., nz)
           if nz gt 0 then $
              plot.limz(*,j+2) = [min(ua(keep).(plotpars(j))), $
                                  max(ua(keep).(plotpars(j)))]
       endfor
    endif
end

pro deua_legend, recsel
@deua_inc.pro
     deua_clear_window, widz.legend
     if n_elements(recsel) eq 0 then return
     nk = -1
     ok = where(recsel ge 0, nk)
     if nk le 0 then return

     xr  = host.resln(0)*0.7
     yr  = host.resln(0)
     shrink = 0.7*min(float(host.resln)/[xr, yr])
     xr = xr*shrink
     yr = yr*shrink
     host.legend_size = [xr, yr]

     widz.legend=widget_base(title='Plot Legend', $
                             group_leader=widz.output, $
                             xoffset=(host.resln(0) - xr)*.99, $
                             yoffset=(host.resln(1) - yr)*.92)
     widz.legitm=widget_draw(widz.legend, $
                             xsize=xr-2, $
                             ysize=yr-2)
     widget_control, widz.legend, /realize
     widget_control, widz.legitm, get_value=windex
     widz.legwin = windex
     wset, windex
     erase, color=0
     host.text_line = 0

     deua_time_legend,     recsel
     deua_orbit_legend,    recsel
     deua_altitude_legend, recsel
     if plot.plot_type eq 'Scalar Map' or $
        plot.plot_type eq 'Color Modulated Vectors' then $
                           deua_color_legend, recsel
     if plot.plot_type eq 'Vector Map' or $
        plot.plot_type eq 'Color Modulated Vectors' or $
        plot.plot_type eq 'Deflection Plot' then deua_vector_legend, recsel
     wset,  widz.output_window
     wshow, widz.output_window
end

pro deua_next_yline, ypos
@deua_inc.pro
    host.text_line = host.text_line + 1
    ypos = host.text_normtop - host.text_normsep*host.text_line
end

pro deua_time_legend, recsel
@deua_inc.pro
     wset, widz.legwin
     deua_next_yline, ypos
     txt = strcompress('Min YYDDD: ' + string(min(ua(recsel)._date)))
     xyouts, 0.1,  ypos, txt, color=host.shades-1, align=0, /normal
     txt = strcompress('Max YYDDD: ' + string(max(ua(recsel)._date)))
     xyouts, 0.9,  ypos, txt, color=host.shades-1, align=1, /normal
     losel  = where(ua(recsel)._date eq min(ua(recsel)._date))
     hisel  = where(ua(recsel)._date eq max(ua(recsel)._date))
     lotime = string(min(ua(recsel(losel)).time_ut), format='(f5.2)')
     deua_next_yline, ypos
     txt = strcompress('Start UT: '  + lotime)
     xyouts, 0.1,  ypos, txt, color=host.shades-1, align=0, /normal
     hitime = string(max(ua(recsel(hisel)).time_ut), format='(f5.2)')
     txt = strcompress('End UT: '  + hitime)
     xyouts, 0.9,  ypos, txt, color=host.shades-1, align=1, /normal
end

pro deua_orbit_legend, recsel
@deua_inc.pro
     wset, widz.legwin
     orblo   = min(ua._orbit)
     orbhi   = max(ua._orbit)
     orbmd   = (orblo+orbhi)/2
     orbrg   = orbhi - orblo
     orbhere = ua(recsel)._orbit
     prevorb = -999
     hdng    = 'Orbit Number: '

     deua_next_yline, ypos
     deua_next_yline, ypos
     xyouts, 0.1, ypos, hdng, color=host.shades-1, $
             align=0, /normal, width=xwid
     xorg = 0.1 + xwid*1.05
     xshf = 0.
     for k=0,n_elements(orbhere)-1 do begin
         if orbhere(k) ne prevorb then begin
            orbcul = host.shades/2 + $
                    (orbhere(k) - orbmd)*(host.colsat*host.shades)/orbrg
            if xorg + xshf gt 0.90 then begin
               xshf = 0
               deua_next_yline, ypos
            endif
            xyouts, xorg+xshf, ypos, strcompress(string(orbhere(k))), $
                    color=orbcul, align=0, /normal, width=xwid
            xshf = xshf + xwid*1.2
            prevorb = orbhere(k)
         endif
     endfor
end

pro deua_altitude_legend, recsel
@deua_inc.pro
     wset, widz.legwin
     deua_next_yline, ypos
     !p.region = [0.05, 0.35, 0.95, ypos]
     xdat  = ua(recsel)._date*24 + ua(recsel).time_ut
     xdat  = xdat - ua(recsel(0))._date*24
     ydat  = ua(recsel).altitude
     if n_elements(xdat) eq 1 then begin
        xdat = [xdat, xdat+0.001]
        ydat = [ydat, ydat]
     endif
     orblo = min(ua._orbit)
     orbhi = max(ua._orbit)
     orbmd = (orblo+orbhi)/2
     orbrg = orbhi - orblo
     plot, xdat, ydat, /nodata, /noerase, $
                 xtitle='Time U.T. [hours]', $
                 ytitle='Altitude [km]', $
                 yrange=[0,1000], $
                 xstyle=2, /ystyle, $
                 color=host.shades-1
     for k=0,n_elements(recsel)-1 do begin
         orbcul = host.shades/2 + $
                 (ua(recsel(k))._orbit - orbmd)*(host.colsat*host.shades)/orbrg
         oplot, [xdat(k)], [ydat(k)], psym=1, symsize=.1, color=orbcul
     endfor
     !p.region = 0
end

pro deua_color_legend, recsel
@deua_inc.pro
     wset, widz.legwin
     !p.position = [0.25, 0.1, 0.3, 0.30]
     lopix = convert_coord(!p.position(0), !p.position(1), /normal, /to_device)
     hipix = convert_coord(!p.position(2), !p.position(3), /normal, /to_device)

     nlev = hipix(1) - lopix(1)
     npix = hipix(0) - lopix(0)
     map  = bindgen(nlev) * float(host.colsat*host.shades)/nlev
     tv, (bytarr(npix) + 1)#map, !p.position(0), !p.position(1), /normal
     plot,  /nodata, [0,host.shades-1], $
         xstyle=1, ystyle=4, $
         xtitle=' ', ytitle=' ', $
         xticks=2, xticklen = 0.001, xtickname=replicate(' ', 3), $
             color=host.shades-1, /noerase
     lolbl = strcompress(plot.parnamz(2) + '=' + string(plot.limz(0,2), $
                         format='(g12.4)'))
     hilbl = strcompress(plot.parnamz(2) + '=' + string(plot.limz(1,2), $
                         format='(g12.4)'))
     AXIS, xaxis=0, xstyle=1, xtitle=' ', xticks=2, $
           xticklen = 0.001, xtickname=[' ', lolbl, ' '], charsize=0.8
     AXIS, xaxis=1,xstyle=1, xtitle=' ',  xticks=2, $
           xticklen = 0.001, xtickname=[' ', hilbl, ' '], charsize=0.8
     AXIS, yaxis=0, ystyle=1, ytitle=' ', yticks=2, $
           yticklen = 0.001, ytickname=[' ', ' ', ' ']
     AXIS, yaxis=1, ystyle=1, ytitle=' ', yticks=2, $
           yticklen = 0.001, ytickname=[' ', ' ', ' ']
     !p.position = 0
end

pro deua_vector_legend, recsel
@deua_inc.pro
     if plot.plot_type eq 'Color Modulated Vectors' then idx = 3 else idx = 2
     wset, widz.legwin
     !p.position = [0.5, 0.1, 0.9, 0.30]
     veclen = plot.vecfrac*total(float(plot.map_pix))/2
     org    = [(!p.position(0) +   !p.position(2))/2, $
               (!p.position(1) + 2*!p.position(3))/3]
     org    = convert_coord(org, /normal, /to_device)
     plots, org(0) - veclen/2,  org(1), /device
     plots, org(0) + veclen/2,  org(1), /device, color=host.shades-1, /continue
     plots, org(0) + veclen/2,  org(1), /device
     plots, org(0) + veclen/2 - veclen/10,  org(1) + veclen/10, $
                                        /device, color=host.shades-1, /continue
     plots, org(0) + veclen/2,  org(1), /device
     plots, org(0) + veclen/2 - veclen/10,  org(1) - veclen/10, $
                                        /device, color=host.shades-1, /continue
     org  = [(!p.position(0) +   !p.position(2))/2, $
             (!p.position(3) + 2*!p.position(1))/3]
     anot = strcompress(plot.parnamz(idx) + '=' + string(plot.limz(1,idx), $
                         format='(g12.4)'))
     xyouts, org(0), org(1), anot, /normal, align=0.5, color=host.shades-1, $
             charsize=0.8
     !p.position = 0
end

pro deua_latsign, latsign
@deua_inc.pro
    nl = -1
    latsign = congrid(ua.latitude, 6*n_elements(ua.latitude), /cubic)
    latsign = latsign - shift(latsign , 1)
    latsign = rebin(latsign, n_elements(ua.latitude))
    sgn = where(latsign ge 0, nl)
    if nl gt 0 then latsign(sgn) = 1
    sgn = where(latsign lt 0, nl)
    if nl gt 0 then latsign(sgn) = -1
end

pro deua_data_interp
@deua_inc.pro
    deua_plot_pars, xpars, 'X', 0
    idx = xpars(0)
    ng = -1
    nb = -1
    goods = where(ua.(idx) ne 0., ng)
    bads  = where(ua.(idx) eq 0., nb)
    if ng le 0 then return
    if nb eq 0 then return

;   Select only the bad points that are inside the period of good data:
    badin = where(bads gt goods(0), nb)
    if nb eq 0 then return
    bads  = bads(badin)
    badin = where(bads lt goods(n_elements(goods)-1), nb)
    if nb eq 0 then return
    bads  = bads(badin)

    deua_clear_window, widz.output
    deua_info_screen, 'Interpolating ' + widz.choice
    deua_latsign, latsign
    ua.northward_wind = ua.northward_wind*latsign
    ua.northward_ion_drift = ua.northward_ion_drift*latsign

    for k=0,nb-1 do begin
        before = where(bads(k) gt goods)
        after  = where(bads(k) lt goods)
        before = before(n_elements(before)-1)
        after  = after(0)
        bday   = ua(goods(before))._date
        aday   = ua(goods(after))._date
        btime  = ua(goods(before)).time_ut
        atime  = ua(goods(after)).time_ut
        bval   = ua(goods(before)).(idx)
        aval   = ua(goods(after)).(idx)
        badday = ua(bads(k))._date
        badtim = ua(bads(k)).time_ut
        deltim = 24.*(badday-bday) + badtim - btime
        delt2  = 24.*(badday-aday) + badtim - atime
        timint = 24.*(aday-bday) + atime - btime
        if deltim lt 0.5 or -delt2 lt 0.5 then $
           ua(bads(k)).(idx) = bval + (aval - bval)*deltim/timint
    endfor
    ua.northward_wind = ua.northward_wind*latsign
    ua.northward_ion_drift = ua.northward_ion_drift*latsign
    deua_clear_window, widz.output
    deua_loadct
end

pro deua_density_proj, factor=fcf
@deua_inc.pro
if keyword_set(fcf) then plot.hc_fix=fcf
ng = 0
goodtemp = where(ua.neutral_temp gt 500. and ua.neutral_temp lt 2500., ng)
if ng gt 0 then begin
   avtemp = total(ua(goodtemp).neutral_temp)/ng
endif else avtemp = 1000.
hc = 0.001*1.380658e-23*avtemp/(9.8*1.672623e-27)
print, 'Average temperature = ', avtemp, ' Kelvins.'
print, 'Average atomic oxygen scale height = ', hc/16., ' kilometers.'

if plot.hc ne 0 then begin ; Undo any previous scaling:
   ua.n2_density = ua.n2_density/exp((ua.altitude - 300.)/(plot.hc/28.))
   ua.o_density  = ua.o_density/exp((ua.altitude - 300.)/(plot.hc/16.))
   ua.he_density = ua.he_density/exp((ua.altitude - 300.)/(plot.hc/4.))
   ua.ar_density = ua.ar_density/exp((ua.altitude - 300.)/(plot.hc/18.))
   ua.n_density  = ua.n_density/exp((ua.altitude - 300.)/(plot.hc/14.))
endif

hc = hc*plot.hc_fix
ua.n2_density = ua.n2_density*exp((ua.altitude - 300.)/(hc/28.))
ua.o_density  = ua.o_density*exp((ua.altitude - 300.)/(hc/16.))
ua.he_density = ua.he_density*exp((ua.altitude - 300.)/(hc/4.))
ua.ar_density = ua.ar_density*exp((ua.altitude - 300.)/(hc/18.))
ua.n_density  = ua.n_density*exp((ua.altitude - 300.)/(hc/14.))
plot.hc = hc
end

pro deua_scat_plot
@deua_inc.pro
    deua_plot_pars, xpars, 'X', 0
    deua_plot_pars, ypars, 'Y', 1
    deua_open_outwin, /make_draw
    !P.multi = [0, 1, plot.ypar_count]
    reserve_colors, shades
    ptit = 'DE Unified Abstract Data'
    orblo = min(ua._orbit)
    orbhi = max(ua._orbit)
    orbmd = (orblo+orbhi)/2
    orbrg = orbhi - orblo
    gfxok = 1
    while gfxok gt 0 do begin
       xwin = plot.limz(*,1)
       for j=0,n_elements(ypars) - 1 do begin
           xdat = ua(*).(xpars(0))
           ydat = ua(*).(ypars(j))
           nk   = -1
           keep = where(float(ydat) ne 0. and $
                        ua._orbit ge plot.limz(0,0) and $
                        ua._orbit le plot.limz(1,0), nk)
           if nk ne 0 then begin
              xdat = xdat(keep)
              ydat = ydat(keep)
              if j eq 0 then begin
                 kept  = keep
                 datlo = min(xdat)
                 dathi = max(xdat)
              endif else begin
                 kept  = [kept, keep]
                 datlo = min([datlo, xdat])
                 dathi = max([dathi, xdat])
              endelse
           endif
       endfor
       xwin(0) = max([xwin(0), min(datlo)])
       xwin(1) = min([xwin(1), max(dathi)])
       for j=0,n_elements(ypars) - 1 do begin
           xdat = ua(*).(xpars(0))
           ydat = ua(*).(ypars(j))
           nk   = -1
           keep = where(float(ydat) ne 0. and $
                        ua._orbit ge plot.limz(0,0) and $
                        ua._orbit le plot.limz(1,0), nk)
           if nk ne 0 then begin
              xdat = xdat(keep)
              ydat = ydat(keep)
           endif
           if j eq 0 then kept = keep
           if j ne 0 then kept = [kept, keep]
           plot, xdat, ydat, /nodata, $
                 xtitle=plot.parnamz(1), ytitle=plot.parnamz(j+2), $
                 xrange=xwin,  yrange=plot.limz(*,j+2), $
                 xmargin=[13,3], ymargin=[4,1], $
                 xstyle=2, /ystyle, $
                 color=shades-1, xthick=2, ythick=2, charsize=2, charthick=2
           if nk gt 0 then begin
              for k=0,n_elements(xdat)-1 do begin
                  orbcul = shades/2 + $
                          (ua(keep(k))._orbit - orbmd)*(host.colsat*shades)/orbrg
                  if plot.xypt_style gt 0 then begin
                     oplot, [xdat(k)], [ydat(k)], psym=plot.xypt_style, $
                             symsize=.6, color=orbcul
                  endif else begin
                     orbcul = host.colsat*shades*k*1./n_elements(xdat)
                     if k gt 0 then oplot, [xdat(k-1),xdat(k)],$
                                           [ydat(k-1), ydat(k)], $
                                            psym=plot.xypt_style, $
                                            symsize=.6, color=orbcul
                  endelse
              endfor
           endif
       endfor
       opts = ['Next Orbit', $
               'Previous Orbit', $
               'Specific Orbit', $
               'Orbit Range', $
               'Independent Variable Range', $
               'Dependent Variable Range', $
               'Interactive']
       nk  = -1
       sel = where(kept ne -1, nk)
       if nk gt 0 then kept = kept(sort(kept))
       nk  = -1
       sel = where(kept ne -1, nk)
       if nk gt 0 then begin
          deua_legend,  kept(sel)
          deua_gfx_ctl, opts, gfxok, kept(sel)
       endif else deua_gfx_ctl, opts, gfxok, kept(0)
    endwhile
end

pro deua_plot_map, proj_list, map_title, recsel, oldproj=op, rotation=rot
@deua_inc.pro
      deua_clear_window, widz.output
      deua_clear_window, widz.dialogue
      widz.choice = plot.map_proj
      if not keyword_set(op) then begin
         deua_open_window,  widx, 'Choose Map Projection'
                            widz.dialogue = widx
         deua_scalar_menu, proj_list, /column
      endif
    reserve_colors, shades
    plot.map_proj = widz.choice
    rtn = 180
    if keyword_set(rot) then rtn = rot
    !P.multi = 0
    if widz.choice eq 'Transverse Mercator' then begin
       deua_open_outwin, /make_draw, aspect=1
       map_set, 0, 0, 90, /merc,   color=0
    endif
    if widz.choice eq 'North Polar Stereographic' then begin
       deua_open_outwin, /make_draw, aspect=1
       map_set, 90, 0, rtn, /stereo, limit=[35, -180, 90, 180], $
                color=0
    endif
    if widz.choice eq 'South Polar Stereographic' then begin
       deua_open_outwin, /make_draw, aspect=1
       map_set,-90, 0, rtn, /stereo, limit=[-90, -180, -35, 180], $
                color=0
    endif
    if widz.choice eq 'Oblique Cylindrical Equidistant' then begin
       deua_open_outwin, /make_draw, aspect=1.3
       map_set, 0, 0, 45, /cyl,    color=0
    endif

;   Remove data points from the selected set if they fall outside the map area
    if recsel(0) ne -1 then begin
        maploc = convert_coord(ua(recsel).longitude, ua(recsel).latitude, $
                           /data, /to_normal)
        nok = -1
        ok  = where(maploc(0, *) gt 0.04 and maploc(0, *) lt 0.96 and $
                    maploc(1, *) gt 0.04 and maploc(1, *) lt 0.96, nok)
        if nok gt 0 then recsel = recsel(ok)
        deua_time_span, recsel, span, mid_ut, rtn
    endif

    if widz.choice eq 'Transverse Mercator' then begin
       map_set, 0, 0, 90, /continent, /merc,   color=plot.coast_cull, $
                title=map_title
    endif
    if widz.choice eq 'North Polar Stereographic' then begin
       map_set, 90, 0, rtn, /continent, /stereo, limit=[35, -180, 90, 180], $
                color=plot.coast_cull, title=ttl
    endif
    if widz.choice eq 'South Polar Stereographic' then begin
       map_set,-90, 0, rtn, /continent, /stereo, limit=[-90, -180, -35, 180], $
                color=plot.coast_cull, title=ttl
    endif
    if widz.choice eq 'Oblique Cylindrical Equidistant' then begin
       map_set, 0, 0, 45, /continent, /cyl,    color=plot.coast_cull, title=ttl
    endif

    map_grid, latdel=15, londel=20, color=shades/6
    lolef = convert_coord(0., 0., /normal, /to_device)
    uprit = convert_coord(1., 1., /normal, /to_device)
    plot.map_pix = uprit(0:1) - lolef(0:1)

;   Mark magnetic L-poles:
    oplot, [-68.7], [76.6], psym=4, color=host.shades-1, symsize=1
    oplot, [-68.7], [76.6], psym=6, color=host.shades-1, symsize=1
    oplot, [ 122.], [-75.], psym=4, color=host.shades-1, symsize=1
    oplot, [ 122.], [-75.], psym=6, color=host.shades-1, symsize=1
end

pro deua_orbit_plot
@deua_inc.pro
    keep = indgen(n_elements(ua))
    deua_plot_map, ['North Polar Stereographic', $
                    'South Polar Stereographic', $
                    'Transverse Mercator', $
                    'Oblique Cylindrical Equidistant'], $
                    'Satellite Orbit', keep
    orblo = min(ua._orbit)
    orbhi = max(ua._orbit)
    orbmd = (orblo+orbhi)/2
    orbrg = orbhi - orblo
    if keep(0) ne -1 then begin
       for k=0,n_elements(keep)-1 do begin
           orbcul = host.shades/2 + $
                   (ua(keep(k))._orbit - orbmd)*(host.colsat*host.shades)/orbrg
           oplot, [ua(keep(k)).longitude], [ua(keep(k)).latitude], $
                  psym=1,  symsize=.2, color=orbcul
       endfor
    endif
    deua_legend,  keep
end

pro deua_time_span, keep, span, mid_ut, rotn
@deua_inc.pro
    mid_ut = 12.
    rotn   = 180.
    span   = 0
    nk = -1
    ok = where(keep ge 0, nk)
    if nk le 0 then return

    hiday = max(ua(keep)._date)
    loday = min(ua(keep)._date)
    hihr  = max(ua(keep).time_ut)
    lohr  = min(ua(keep).time_ut)
    span  = 24.*(hiday - loday) + hihr - lohr
    if span lt 1. then begin
       mid_ut = (hihr + lohr)/2
       rotn   = - 360.*mid_ut/24
    endif
end


pro deua_scalar_map
@deua_inc.pro
    deua_plot_pars, ypars, 'Y', 0
    ypar  = ua(*).(ypars(0))
    gfxok = 1
    opr   = 0
    while gfxok gt 0 do begin
       nk   = -1
       keep = where(float(ypar) ne 0. and $
                    ua._orbit ge plot.limz(0,0) and $
                    ua._orbit le plot.limz(1,0), nk)
       deua_plot_map, ['North Polar Stereographic', $
                       'South Polar Stereographic', $
                       'Transverse Mercator', $
                       'Oblique Cylindrical Equidistant'], $
                       xtit, keep, oldproj=opr
       if keep(0) ne -1 then begin
          ydat = ypar(keep)
       endif
       ymin = plot.limz(0,2)
       ymax = plot.limz(1,2)
       ymid = (ymin + ymax)/2
       yrg  = (ymax - ymin)
       opr = 1
       if keep(0) ne -1 then begin
          for k=0,n_elements(ydat)-1 do begin
              idx    = keep(k)
              orbcul = host.shades/2 + $
                       (ydat(k) - ymid)*(host.colsat*host.shades)/yrg
              oplot, [ua(idx).longitude], [ua(idx).latitude], $
                     psym=1, symsize=.2, color=orbcul
           endfor
       endif
       opts = ['Next Orbit', $
               'Previous Orbit', $
               'Specific Orbit', $
               'Orbit Range', $
               'Dependent Variable Range', $
               'Interactive']
       deua_legend,  keep
       deua_gfx_ctl, opts, gfxok, keep
    endwhile
end

pro deua_vecplot, xbeg, ybeg, xlen, ylen, color=culin
@deua_inc.pro
cul = host.shades-1
if keyword_set(culin) then cul = culin
org    = convert_coord(xbeg, ybeg,    /to_normal)
dnorth = convert_coord(xbeg, ybeg+.01, /to_normal) - org
nhat   = dnorth/sqrt(total(dnorth*dnorth))
ehat   = [nhat(1), -nhat(0)]
dv     = xlen*ehat + ylen*nhat
vend   = org + dv
head1  = -[-dv(1),  dv(0)]/10
head2  = -[ dv(1), -dv(0)]/10
plots, org(0),  org(1), /normal
plots, vend(0), vend(1), /normal, /continue, color=cul, thick=plot.vecthick
plots, vend(0), vend(1), /normal
plots, vend(0) - dv(0)/10 + head1(0), vend(1) - dv(1)/10 + head1(1), $
      /normal, /continue, color=cul, thick=plot.vecthick
plots, vend(0), vend(1), /normal
plots, vend(0) - dv(0)/10 + head2(0), vend(1) - dv(1)/10 + head2(1), $
      /normal, /continue, color=cul, thick=plot.vecthick

end

pro deua_cendif, vecin, difvec
@deua_inc.pro
       deua_latsign, latsign
       difvec = latsign*(shift(latsign*vecin, 1) - shift(latsign*vecin, -1))/2
end

pro deua_vector_map
@deua_inc.pro
    deua_clear_window, widz.dialogue
    deua_open_window, widx, 'Neutral or Ion Vectors?' & widz.dialogue=widx
                      widz.output_window = !D.window
    deua_scalar_menu, ['Wind Vectors', $
                       'Wind Difference Vectors', $
                       'Low-Pass Filtered Winds', $
                       'High-Pass Filtered Winds', $
                       'Ion Drift Vectors', $
                       'Cancel'], /column
    if widz.choice eq 'Cancel' then return
    if widz.choice eq 'Wind Vectors' then begin
       xpar = ua.eastward_wind
       ypar = ua.northward_wind
       plot.parnamz(2)   = 'Neutral Wind Vector [m/s]'
       plot.limz(*,2) = [0,500]
    endif
    if widz.choice eq 'Wind Difference Vectors' then begin
       deua_cendif, ua.eastward_wind, xpar
       deua_cendif, ua.northward_wind, ypar
       plot.parnamz(2)   = 'Wind Central Difference Vector [m/s]'
       plot.limz(*,2) = [0,100]
    endif
    if widz.choice eq 'Low-Pass Filtered Winds' then begin
       deua_latsign, latsign
       xpar = latsign*smooth(ua.eastward_wind*latsign, 5)
       ypar = latsign*smooth(ua.northward_wind*latsign, 5)
       plot.parnamz(2)   = 'Low-Pass Filtered Wind [m/s]'
       plot.limz(*,2) = [0,500]
    endif
    if widz.choice eq 'High-Pass Filtered Winds' then begin
       deua_latsign, latsign
       xpar = ua.eastward_wind - latsign*smooth(ua.eastward_wind*latsign, 5)
       ypar = ua.northward_wind - latsign*smooth(ua.northward_wind*latsign, 5)
       plot.parnamz(2)   = 'High-Pass Filtered Wind [m/s]'
       plot.limz(*,2) = [0,100]
    endif
    if widz.choice eq 'Ion Drift Vectors' then begin
       xpar = ua.eastward_ion_drift
       ypar = ua.northward_ion_drift
       plot.parnamz(2)   = 'Ion Drift Vector [m/s]'
       plot.limz(*,2) = [0,2000]
    endif

    orblo = min(ua._orbit)
    orbhi = max(ua._orbit)
    orbmd = (orblo+orbhi)/2
    orbrg = orbhi - orblo
    gfxok = 1
    opr   = 0
    while gfxok gt 0 do begin
       nk   = -1
       keep = where(float(xpar) ne 0. and float(ypar) ne 0 and $
                    ua._orbit ge plot.limz(0,0) and $
                    ua._orbit le plot.limz(1,0), nk)
       deua_plot_map, ['North Polar Stereographic', $
                       'South Polar Stereographic', $
                       'Transverse Mercator'], $
                        xtit, keep, oldproj=opr
       if keep(0) ne -1 then begin
          xdat = xpar(keep)
          ydat = ypar(keep)
       endif
       opr = 1
       if keep(0) ne -1 then begin
          for k=0,n_elements(xdat)-1 do begin
              idx = keep(k)
              orbcul = host.shades/2 + $
                      (ua(idx)._orbit - orbmd)*(host.colsat*host.shades)/orbrg
              xpos = ua(idx).longitude
              ypos = ua(idx).latitude
              xlen = xdat(k)*plot.vecfrac/plot.limz(1,2)
              ylen = ydat(k)*plot.vecfrac/plot.limz(1,2)
              deua_vecplot, xpos, ypos, xlen, ylen, color=orbcul
          endfor
       endif
       opts = ['Next Orbit', $
               'Previous Orbit', $
               'Specific Orbit', $
               'Orbit Range', $
               'Dependent Variable Range', $
               'Interactive']
       deua_legend,  keep
       deua_gfx_ctl, opts, gfxok, keep
    endwhile
end

pro deua_colvec_map
@deua_inc.pro
    deua_plot_pars, ypars, 'Y', 0
    zpar = ua.(ypars(0))
    deua_clear_window, widz.dialogue
    deua_open_window, widx, 'Neutral or Ion Vectors?' & widz.dialogue=widx
                      widz.output_window = !D.window
    deua_scalar_menu, ['Wind Vectors', $
                       'Wind Difference Vectors', $
                       'Low-Pass Filtered Winds', $
                       'High-Pass Filtered Winds', $
                       'Ion Drift Vectors', $
                       'Cancel'], /column
    if widz.choice eq 'Cancel' then return
    if widz.choice eq 'Wind Vectors' then begin
       xpar = ua.eastward_wind
       ypar = ua.northward_wind
       plot.parnamz(3)   = 'Neutral Wind Vector [m/s]'
       plot.limz(*,3) = [0,500]
    endif
    if widz.choice eq 'Wind Difference Vectors' then begin
       deua_cendif, ua.eastward_wind, xpar
       deua_cendif, ua.northward_wind, ypar
       plot.parnamz(3)   = 'Wind Central Difference Vector [m/s]'
       plot.limz(*,3) = [0,100]
    endif
    if widz.choice eq 'Low-Pass Filtered Winds' then begin
       deua_latsign, latsign
       xpar = latsign*smooth(ua.eastward_wind*latsign, 5)
       ypar = latsign*smooth(ua.northward_wind*latsign, 5)
       plot.parnamz(3)   = 'Low-Pass Filtered Wind [m/s]'
       plot.limz(*,3) = [0,100]
    endif
    if widz.choice eq 'High-Pass Filtered Winds' then begin
       deua_latsign, latsign
       xpar = ua.eastward_wind - latsign*smooth(ua.eastward_wind*latsign, 5)
       ypar = ua.northward_wind - latsign*smooth(ua.northward_wind*latsign, 5)
       plot.parnamz(3)   = 'High-Pass Filtered Wind [m/s]'
       plot.limz(*,3) = [0,100]
    endif
    if widz.choice eq 'Ion Drift Vectors' then begin
       xpar = ua.eastward_ion_drift
       ypar = ua.northward_ion_drift
       plot.parnamz(3)   = 'Ion Drift Vector [m/s]'
       plot.limz(*,3) = [0,2000]
    endif
    plot.ypar_count = 2
    gfxok = 1
    opr   = 0
    while gfxok gt 0 do begin
       nk   = -1
       keep = where(float(xpar) ne 0. and float(ypar) ne 0 and $
                    zpar ne 0. and $
                    zpar ge plot.limz(0,2) and $
                    zpar le plot.limz(1,2) and $
                    ua._orbit ge plot.limz(0,0) and $
                    ua._orbit le plot.limz(1,0), nk)
       deua_plot_map, ['North Polar Stereographic', $
                       'South Polar Stereographic', $
                       'Transverse Mercator'], $
                        xtit, keep, oldproj=opr
       if keep(0) ne -1 then begin
          xdat = xpar(keep)
          ydat = ypar(keep)
          zdat = zpar(keep)
       endif
       zmin = plot.limz(0,2)
       zmax = plot.limz(1,2)
       zmid = (zmin + zmax)/2
       zrg  = (zmax - zmin)
       opr = 1
       if keep(0) ne -1 then begin
          for k=0,n_elements(xdat)-1 do begin
              idx = keep(k)
              orbcul = host.shades/2 + $
                       (zdat(k) - zmid)*(host.colsat*host.shades)/zrg
              xpos = ua(idx).longitude
              ypos = ua(idx).latitude
              xlen = xdat(k)*plot.vecfrac/plot.limz(1,3)
              ylen = ydat(k)*plot.vecfrac/plot.limz(1,3)
              deua_vecplot, xpos, ypos, xlen, ylen, color=orbcul
          endfor
       endif
       opts = ['Next Orbit', $
               'Previous Orbit', $
               'Specific Orbit', $
               'Orbit Range', $
               'Dependent Variable Range', $
               'Interactive']
       deua_legend,  keep
       deua_gfx_ctl, opts, gfxok, keep
    endwhile
end

pro deua_deflection_plot
@deua_inc.pro
    deua_plot_pars, ypars, 'Y', 0
    plot.limz(*,2) = [0, max(abs(plot.limz(*,2)))]
    ypar  = ua(*).(ypars(0))
    orblo = min(ua._orbit)
    orbhi = max(ua._orbit)
    orbmd = (orblo+orbhi)/2
    orbrg = orbhi - orblo
    gfxok = 1
    opr   = 0
    while gfxok gt 0 do begin
       nk   = -1
       keep = where(float(ypar) ne 0. and $
                    ua._orbit ge plot.limz(0,0) and $
                    ua._orbit le plot.limz(1,0), nk)
       deua_plot_map, ['North Polar Stereographic', $
                       'South Polar Stereographic', $
                       'Transverse Mercator'], $
                       xtit, keep, oldproj=opr
       if keep(0) ne -1 then begin
          ydat = ypar(keep)
       endif
       ymin = 0
       ymax = plot.limz(1,2)
       yrg  = (ymax - ymin)
       opr = 1
       if keep(0) ne -1 then begin
          for k=0,n_elements(ydat)-1 do begin
              idx = keep(k)
              orbcul = host.shades/2 + $
                      (ua(idx)._orbit - orbmd)*(host.colsat*host.shades)/orbrg
              xpos = ua(idx).longitude
              ypos = ua(idx).latitude
              xlen = ydat(k)*plot.vecfrac/yrg
              ylen = 0
              deua_vecplot, xpos, ypos, xlen, ylen, color=orbcul
          endfor
       endif
       opts = ['Next Orbit', $
               'Previous Orbit', $
               'Specific Orbit', $
               'Orbit Range', $
               'Dependent Variable Range', $
               'Interactive']
       deua_legend,  keep
       deua_gfx_ctl, opts, gfxok, keep
    endwhile
end


pro deua_interactive_output
@deua_inc.pro
     deua_clear_window, widz.dialogue
     deua_open_window,  widx, 'Command Window'
                       widz.dialogue = widx
;     deua_open_outwin, /make_draw

     widz.dialz(0) = cw_field (widz.dialogue, $
                                title='Enter IDL Command>  ', $
                                value=' ', $
                               /frame, $
                               /return_events, $
                               /string)
     button = [{CW_PDMENU_S, flags: 0, name: 'Cancel'}]
     widz.dialz(1) = cw_pdmenu (widz.dialogue, button, $
                               /return_full_name, $
                                delimiter='|')
    WIDGET_CONTROL, widz.dialogue, /realize
    xmanager, 'interactive', widz.dialogue, group_leader=widz.top, /modal

end

pro interactive_event, event
@deua_inc.pro
    widget_control, widz.top, /show
    if event.id    eq  widz.dialz(0) then begin
       wset, widz.output_window
       ok = execute(event.value(0))
       ok = execute('print, event.value')
       widget_control, widz.dialz(0), set_value=' '
    endif
    if event.value eq 'Cancel' then begin
;       deua_clear_window, widz.output
       deua_clear_window, widz.dialogue
    endif
    widget_control, widz.top, /show
end

pro deua_write_gif
@deua_inc.pro
    plot.gifnum = plot.gifnum + 1
    seq = strcompress(string(plot.gifnum), /remove_all) + '.gif'

;   Write a gif file for the plot window:
    choice = '!No File!'
    choice = pickfile(file='deua_'+seq, $
                      path=plot.path, get_path=path, $
                      filter='*.gif', $
                     /fix_filter, /write)
    if choice ne '!No File!' then begin
       wset, widz.output_window
       dump = tvrd()
       tvlct, r, g, b, /get
       write_gif, choice, dump, r, g, b
    endif

;   Write a gif file for the legend window:
    choice = '!No File!'
    choice = pickfile(file='lgnd_'+seq, $
                      path=plot.path, get_path=path, $
                      filter='*.gif', $
                     /fix_filter, /write)
    if choice ne '!No File!' then begin
       wset, widz.legwin
       dump = tvrd()
       tvlct, r, g, b, /get
       write_gif, choice, dump, r, g, b
    endif
end

;===================================================================
; Install the user-defined color table palette by default:

pro deua_loadct
@deua_inc.pro
ct = byte(plot.coltab)
loadct, ct
reserve_colors, shades
plot.coast_cull = shades-1
end

;========================================================================
; Reserve colours for labelling and background jobbies:

pro reserve_colors, shades, black=blk
@deua_inc.pro
bgnd = host.background
if keyword_set(blk) then bgnd = 0
tvlct, r, g, b, /get
shades = min([n_elements(r), n_elements(g), n_elements(b)])
host.shades = shades
r = [bgnd, r(1:shades-2), 255-bgnd]
g = [bgnd, g(1:shades-2), 255-bgnd]
b = [bgnd, b(1:shades-2), 255-bgnd]
tvlct, r, g, b
end


;========================================================================
;
;  This procedure initialise the screen graphics:
;

pro deua_open_screen
@deua_inc.pro
set_plot, host.windev
if host.windev eq 'X' then device, pseudo_color=8, retain=2
device, get_screen_size=box, /cursor_original
box = 0.95*box
host.resln = box
while (!D.window ge 0) do wdelete, !D.window
deua_clear_window, widz.dialogue
deua_open_window,  widx, 'Dummy' & widz.dialogue = widx
deua_clear_window, widz.dialogue
end



;========================================================================
;
;  This is the MAIN procedure for the 'simetal' program.  It merely does
;  all the required setting-up, then passes control to the XMANAGER
;  procedure which dispatches to the event handler if an event
;  occurs from a widget defined in this program:


@deua_inc.pro

deua_data_init
deua_open_screen
deua_loadct
deua_setup_widgets
xmanager, 'deua', widz.top, group_leader=widz.top
end


