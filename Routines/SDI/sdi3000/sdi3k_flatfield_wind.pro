 done = 0
 first = 1
 path= 'd:\users\sdi3000\data\'
 while not(done) do begin
     these = dialog_pickfile(title="Sky spectra file(s) for flat field:", path=path, get_path=path, /must_exist, /multiple, filter=['*.pf', '*.nc', '*.sky'], /read)
     if strlen(these(0)) ne 0 then begin
        if (first) then flis = these else flis = [flis, these]
     endif
     first = 0
     mcchoice, 'Action?', [flis, 'Add More Files', 'Done'], choice, help='NOTE: Clicking on a file name will remove it from the list'
     if choice.name ne 'Add More Files' and choice.name ne 'Done' then begin
        victim = where(flis eq choice.name, nn)
        if nn ne 0 then veceldel, flis, victim(0)
     endif
     if choice.name eq 'Done' then done =1
 endwhile


 first       = 1
 n_exposures = 0
 hwm         = {plot_hwm: 1, $
                  f10pt7: 120., $
                      ap: 15., $
              hwm_height: 120.}
 load_pal, culz
 while !d.window ge 0 do wdelete, !d.window

 for j=0,n_elements(flis)-1 do begin
      sdi3k_batch_wind_summary, flis(j), culz, 150, hwm, box=[1200, 1000]
      sdi3k_read_netcdf_data, flis(j), metadata=mm, spekfits=spekfits, winds=winds, zone_centers=zone_centers, /close
      timelis = dt_tm_mk(js2jd(0d)+1, (winds.start_time + winds.end_time)/2, format='h$:m$:s$')
      mcchoice, 'Start Time: ', timelis, choice, $
      heading = {text: 'Start Time for Flat Field Data?', font: 'Helvetica*Bold*Proof*30'}
      jlo = choice.index
      mcchoice, 'End Time: ', timelis, choice, $
           heading = {text: 'Start Time for Flat Field Data?', font: 'Helvetica*Bold*Proof*30'}
      jhi = choice.index
      spekfits = spekfits(jlo:jhi)
      mm.maxrec = n_elements(spekfits) - 1

      sdi3k_drift_correct, spekfits, mm, /force, /data
      posarr = spekfits.velocity
      print, 'Time smoothing peak positions from ' + flis(j)
      sdi3k_timesmooth_fits,  posarr, 2., mm
      print, 'Space smoothing peak positions from ' + flis(j)
      sdi3k_spacesmooth_fits, posarr, 0.02, mm, zone_centers
      spekfits.velocity = posarr

      if first then begin
         windoff = total(posarr, 2)
         metadata = mm
         indices = [jlo, jhi]
         tsum = total(spekfits.start_time + spekfits.end_time)/2
      endif else begin
         windoff = windoff + total(posarr, 2)
         metadata = [mm, metadata]
         indices = [[indices], [jlo, jhi]]
         tsum = tsum + total(spekfits.start_time + spekfits.end_time)/2
      endelse
      n_exposures = n_exposures + mm.maxrec + 1
      first = 0
 endfor
 windoff = windoff/n_exposures
 windoff = windoff - total(windoff)/n_elements(windoff)
 avgtime = tsum/n_exposures

 while !d.window ge 0 do wdelete, !d.window
 window, xsize=1200, ysize=900
    title = " "

    mc_npanel_plot,  layout, yinfo, /setup
    layout.position = [0.14, 0.17, 0.96, 0.96]
    layout.charscale = 1.4
    layout.charthick = 4
    erase, color=culz.white
    layout.panels = 1
    layout.time_axis =0
    layout.xrange = [0, mm.nzones]
    layout.title  = title
    layout.xtitle = 'Zone Number'
    layout.erase = 0

    yinfo.charsize = 1.4
    yinfo.psym = 0
    layout.charthick = 4

    yinfo.symsize = 0.3
    yinfo.symbol_color = culz.black
    yinfo.title = ' '
    yinfo.right_axis = 1
    yinfo.rename_ticks = 1
    yinfo.thickness = 3
    yinfo.range = [-160., 160.]
    mc_npanel_plot,  layout, yinfo, indgen(mm.nzones), windoff*mm.channels_to_velocity, panel=0

    yinfo.title = 'Wind Offset m s!U-1!N'
    yinfo.right_axis = 0
    yinfo.rename_ticks = 0
    mc_npanel_plot,  layout, yinfo, indgen(mm.nzones), windoff*mm.channels_to_velocity, panel=0


oper = ' '
datestr = dt_tm_mk(js2jd(0d)+1, avgtime, format = 'Y$_0n$_0d$')
mc_input, oper, title='Operator specification', prompt='Name: ', $
       heading = {text: 'Operator', font: 'Helvetica*Bold*Proof*30'}

js_valid = [ymds2js(1900, 1, 1, 0.), ymds2js(3000, 1, 1, 0.)]
mcchoice, 'Set Range of Valid Dates?', ['Yes, set validity dates', "No, don't set"], choice, help='If not changed, the valid range spans the years from 1900 AD until 3000 AD'
if choice.index eq 0 then begin
   xlo =  mc_calendar(js=avgtime, title='Valid From?', help='Select the date on which this wind offset measurement FIRST became valid.')
   js_valid(0) = xlo.js
   wait, 0.5
   xhi =  mc_calendar(js=avgtime, title='Valid Until?', help='Select the LAST date on which this wind offset measurement was valid.')
   js_valid(1) = xhi.js +86398
endif

stars = ['1-Star *', '2-Stars **', '3-Stars ***', '4-Stars ****', '5-Stars *****']
mcchoice, 'Star Rating?', stars, choice, help="This will be used to help choose which flat field file to use when analysing each day's data. "

wind_flat_field = {wind_offset: windoff, metadata: metadata, indices: indices, js_average: avgtime, js_valid: js_valid, operator: oper, stars: choice}
flatfield_spekfits = spekfits
fname = 'Wind_flat_field_' + datestr + '_' + mm.site_code + '_' + string(fix(10*mm.wavelength_nm), format='(i4.4)') + 'A_created_by_' + oper + '.sav'
fullname = dialog_pickfile(title="Save flat field data as:", path=path, get_path=path, file=fname)
save, wind_flat_field, file=fullname, description="SDI3000 Wind Flat Field Data " + datestr
gif_this, /png, file=path + '\Wind_flat_field_' + datestr + '_' + mm.site_code + '_' + string(fix(10*mm.wavelength_nm), format='(i4.4)') + 'A_created_by_' + oper + '.png'
mcchoice, 'Set environment?', ['Yes, set an environment variable', "No, don't set"], choice, help='This will set SDI_ZERO_VELOCITY_FILE=' + fullname
if choice.index eq 0 then setenv, 'SDI_ZERO_VELOCITY_FILE=' + fullname
end
