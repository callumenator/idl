;==========================================================================================
;   This routine maintains a lookup table of ncids versus filename:
function sdi3k_nc_get_ncid, filename, write_allowed=write_allowed
@sdi3k_ncdf_inc.pro
  if not(keyword_set(write_allowed)) then write_allowed = 0
  if n_elements(ncid_index) lt 1 then ncid_index = {filename: "bound_to_not_exist", ncid: -1, write_allowed: write_allowed}
  idx  = where(ncid_index.filename eq filename, nfnd)
  idx  = idx(0)
  if idx ge 0 then begin
     on_error, 3
     on_ioerror, inq_cont
     res = ncdf_inquire(idx)
inq_cont:
     if n_elements(res) gt 0 then begin
        if ncid_index(idx).write_allowed eq write_allowed then return, ncid_index(idx).ncid
        ncdf_close, ncid_index(idx).ncid
     endif
     veceldel, ncid_index, idx
  endif
  ncid_index = [ncid_index, ncid_index(0)]
  this_nc    = n_elements(ncid_index) - 1
  ncid       = ncdf_open(filename, write = write_allowed)
  ncid_index(this_nc).filename      = filename
  ncid_index(this_nc).ncid          = ncid
  ncid_index(this_nc).write_allowed = write_allowed
  return, ncid
end

;==========================================================================================
;   Read the metadata:
pro sdi3k_read_metadata, filename, ncid, metadata

  mtr = {s_sdi3k_ncdf_metadata, $
         valid: 0, $
         start_time: 0D, $
         end_time: 0D, $
         maxrec: 0L, $
         rings: -1, $
         zone_radii: fltarr(64), $
         zone_sectors: bytarr(64), $
         nzones: 0, $
         scan_channels: 0, $
         rows: 0, $
         columns: 0, $
         x_center_pix: 0., $
         y_center_pix: 0., $
         gap_mm: 0., $
         nm_per_step: 0., $
         start_spacing: 0., $
         gap_refractive_index: 0., $
         ref_finesse: 0., $
         wavelength_nm: 0., $
         mass_amu: 0., $
         cal_temperature: 0., $
         sky_fov_deg: 0., $
         site: 'unkown', $
         site_code: 'ukn', $
         start_day_ut: 0L, $
         year: 0, $
         longitude: 0., $
         latitude: 0., $
         altitude: 0., $
         operator: 'unknown', $
         comment: 'none', $
         notes: strarr(32), $
         file_name: filename, $
         file_accessed: 0D, $
         file_created: 0D, $
         file_modified: 0D, $
         file_bytes: 0L}

         ifo = file_info(filename)
         mtr.file_accessed = ifo.atime + ymds2js(1970,1,1,0)
         mtr.file_created  = ifo.ctime + ymds2js(1970,1,1,0)
         mtr.file_modified = ifo.mtime + ymds2js(1970,1,1,0)
         mtr.file_bytes     = ifo.size

        nc_desc = NCDF_INQUIRE(ncid)
        if nc_desc.ndims ge 7 then begin
            rname = 'Rings'
            radii = 'Zone_Radii'
            sectr = 'Zone_Sectors'
            gap   = 'Gap'
         ncdf_diminq, ncid, ncdf_dimid(ncid, 'XDim'),    dummy,  xdim
         ncdf_diminq, ncid, ncdf_dimid(ncid, 'YDim'),    dummy,  ydim
         mtr.columns = xdim
         mtr.rows    = ydim
        endif else begin
            rname = 'Ring'
            radii = 'Ring_Radii'
            sectr = 'Sectors'
            gap   = 'Plate_Spacing'
        endelse
        rfov  = 'Rings2'

;------Get dimension sizes:
       dummy = 'Return Name'
       ncdf_diminq, ncid, ncdf_dimid(ncid, 'Time'),    dummy,  maxrec
       ncdf_diminq, ncid, ncdf_dimid(ncid, 'Zone'),    dummy,  nzones
       ncdf_diminq, ncid, ncdf_dimid(ncid, 'Channel'), dummy,  nchan
       ncdf_diminq, ncid, ncdf_dimid(ncid,  rname),    dummy,  nrings
       mtr.maxrec        = maxrec
       mtr.nzones        = nzones
       mtr.scan_channels = nchan
       mtr.rings         = nrings-1

       mc_nc_varget, ncid, ['Ring_Radii', 'Zone_Radii'], radii, intarr(nrings-1), 0, nrings-1
       if max(radii) lt 2. then radii = radii * 100

;------Get information regarding times, if the existing file has any:
       if maxrec gt 0 then begin
          ncdf_varget, ncid, ncdf_varid(ncid, 'Start_Time'), stime,   offset=(0), count=(1)
          ncdf_varget, ncid, ncdf_varid(ncid, 'End_Time'),   etime,   offset=(maxrec-1), count=(1)
          mtr.start_time = stime
          mtr.end_time   = etime
       endif

;------Get static variables:
       if nc_desc.ndims ge 7 or nrings gt 5 then begin
          ncdf_varget, ncid, ncdf_varid(ncid, 'X_Center'),             xcen,    offset=0, count=1
          ncdf_varget, ncid, ncdf_varid(ncid, 'Y_Center'),             ycen,    offset=0, count=1
          ncdf_varget, ncid, ncdf_varid(ncid, 'Nm_Per_Step'),          nmps,    offset=0, count=1
       endif else  begin
          xcen = 128
          ycen =128
          nmps = .8
       endelse
       ncdf_varget,  ncid, ncdf_varid(ncid, sectr), sectors,  offset=0, count=nrings-1
       mc_nc_varget, ncid, ['Gap', 'Plate_Spacing'],gap,      18.6,   0, 1
       mc_nc_varget, ncid, 'Start_Spacing',         strtspc,  0.,     0, 1
       mc_nc_varget, ncid, 'Gap_Refractive_Index',  refidx ,  1.,     0, 1
       mc_nc_varget, ncid, ['Sky_Wavelength', 'Wavelength'],  lambda, 630.03, 0, 1
       mc_nc_varget, ncid, ['Cal_Wavelength', 'Wavelength'],  lamcal, 632.8, 0, 1
       mc_nc_varget, ncid, 'Cal_Temperature',       caltemp,  300.,   0, 1
       mc_nc_varget, ncid, ['Mass', 'Sky_Mass', 'Cal_Mass'],  mass, 16., 0, 1
       mc_nc_varget, ncid, ['Ref_Finesse', 'Sky_Ref_Finesse'],nr,   20., 0, 1
       mc_nc_varget, ncid, 'Sky_FOV',               fov,      75.,    0, 1

       mtr.zone_radii            = radii
       mtr.zone_sectors          = sectors
       mtr.x_center_pix          = xcen
       mtr.y_center_pix          = ycen
       mtr.gap_mm                = gap
       mtr.start_spacing         = strtspc
       mtr.scan_channels         = nchan
       mtr.nm_per_step           = nmps
       mtr.gap_refractive_index  = refidx
       mtr.wavelength_nm         = lambda
       mtr.cal_temperature       = caltemp
       mtr.mass_amu              = mass
       mtr.ref_finesse           = nr
       mtr.sky_fov_deg           = fov

;------Get global attributes:

       mc_glob_attget, ncid, 'Site', site, 'Poker Flat'
       mc_glob_attget, ncid, ['Site_Code', 'Site_code'], sitecd, 'PKR'
       mc_glob_attget, ncid, ['Start_Day_UT', 'Start Day UT'], doy, 0L
       mc_glob_attget, ncid, 'Year', year, dt_tm_mak(js2jd(0d)+1, dt_tm_tojs(systime()), format='Y$')
       mc_glob_attget, ncid, 'Longitude', lon, -150.
       mc_glob_attget, ncid, 'Latitude',  lat,  65.
       mc_glob_attget, ncid, 'Operator',  oper, 'Conde'
       mc_glob_attget, ncid, 'Comment',   cmt,  'None'

       mtr.site         = string(site)
       mtr.site_code    = string(sitecd)
       mtr.start_day_ut = string(doy)
       mtr.year         = string(year)
       mtr.longitude    = lon
       mtr.latitude     = lat
       mtr.operator     = string(oper)
       mtr.comment      = string(cmt)

;------Read the notes back from the file:
       for i=0,31 do begin
           mc_glob_attget, ncid, 'Note_' + string(i, format='(i2.2)'),   note,  'None'
           mtr.notes(i) = string(note)
       endfor
       mtr.valid = 1
       metadata = mtr

end

;==========================================================================================
;   This routine reads the spectra from an SDI netCDF file:
pro sdi3k_read_spex, ncid, spex, metadata, range

;---Get the range of records to be read:
    limz = range
    limz = [(range(0) > 0) <  (metadata.maxrec-1), (range(1) > 0) <  (metadata.maxrec-1)]

;---Create a template record for spectral data, then replicate it to create an array to hold the requested records:
    spectra = lonarr(metadata.nzones, metadata.scan_channels)
    onespek = {s_sdi3k_ncdf_spex, $
                 valid: 0, $
               spectra: fltarr(metadata.nzones, metadata.scan_channels), $
            start_time: 0D, $
              end_time: 0D, $
                 scans: 0, $
                record: 0}
    spex = replicate(onespek, 1 + limz(1) - limz(0))

;---Read the requested records:
    for j=limz(0),limz(1) do begin
        ncdf_varget,  ncid, ncdf_varid(ncid, 'Spectra'),       spectra, offset=[0,0,j], $
                      count=[metadata.nzones, metadata.scan_channels, 1]
        ncdf_varget,  ncid, ncdf_varid(ncid, 'Start_Time'),    stime, offset=[j], count=[1]
        ncdf_varget,  ncid, ncdf_varid(ncid, 'End_Time'),      etime, offset=[j], count=[1]
        mc_nc_varget, ncid, ['Number_Summed','Number_Scans'],  scanz, 1, [j], [1]
        k = j - limz(0)
        spex(k).start_time = stime
        spex(k).end_time   = etime
        spex(k).scans      = scanz
        spex(k).spectra    = float(spectra)/scanz
        spex(k).valid      = 1
        spex(k).record     = j
    endfor
end

;==========================================================================================
;   This routine reads the results of spectral fitting:
pro sdi3k_read_spekfits, ncid, spekfits, metadata, range
    ncdf_control, ncid, /sync

;---Return an error if there's no fit data in the file:
    id = ncdf_varid(ncid, 'Peak_Position')
    if id lt 0 then spekfits = 'Error: No fit data found in file: ' + metadata.file_name
    if id lt 0 then return

;---Get data sizes and the range of records to be read:
    maxrec = metadata.maxrec - 1
    nchan  = metadata.scan_channels
    nz     = metadata.nzones
    limz = range
    limz = [(range(0) > 0) <  (metadata.maxrec-1), (range(1) > 0) <  (metadata.maxrec-1)]

;---Create a template record for fit data, then replicate it to create an array to hold the requested records:
        resrec = {s_sdi3k_ncdf_spekfit, $
                 valid: 0, $
                record: 0, $
            start_time: 0D, $
              end_time: 0D, $
         number_summed: 0., $
              velocity: fltarr(nz, nchan), $
           temperature: fltarr(nz, nchan), $
             intensity: fltarr(nz, nchan), $
            background: fltarr(nz, nchan), $
           msis_height: fltarr(nz, nchan) - 9e9, $
 characteristic_energy: fltarr(nz, nchan) -9e9, $
        sigma_velocity: fltarr(nz, nchan), $
     sigma_temperature: fltarr(nz, nchan), $
     sigma_intensities: fltarr(nz, nchan), $
      sigma_background: fltarr(nz, nchan), $
          signal2noise: fltarr(nz, nchan), $
           chi_squared: fltarr(nz, nchan), $
     units_temperature: 'K', $
        units_velocity: 'm/s', $
     units_msis_height: 'km', $
     units_characteristic_energy: 'keV'}

    spekfits = replicate(resrec, 1 + limz(1) - limz(0))

;---Read the requested records:
    record = 0
    for j=limz(0),limz(1) do begin
        ncdf_varget, ncid, ncdf_varid(ncid, 'Peak_Position'),     positions,   offset=[0,  j], count=[nz, 1]
        ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Position'),    sigpos,      offset=[0,  j], count=[nz, 1]
        ncdf_varget, ncid, ncdf_varid(ncid, 'Temperature'),        widths,      offset=[0,  j], count=[nz, 1]
        ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Temperature'),       sigwid,      offset=[0,  j], count=[nz, 1]
        ncdf_varget, ncid, ncdf_varid(ncid, 'Peak_Area'),         areas,       offset=[0,  j], count=[nz, 1]
        ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Area'),        sigarea,     offset=[0,  j], count=[nz, 1]
        ncdf_varget, ncid, ncdf_varid(ncid, 'Background'),        backgrounds, offset=[0,  j], count=[nz, 1]
        ncdf_varget, ncid, ncdf_varid(ncid, 'Sigma_Bgnd'),        sigbgnd,     offset=[0,  j], count=[nz, 1]
        ncdf_varget, ncid, ncdf_varid(ncid, 'Signal_to_Noise'),   sig2noise,   offset=[0,  j], count=[nz, 1]
        ncdf_varget, ncid, ncdf_varid(ncid, 'Chi_Squared'),       chi_squared, offset=[0,  j], count=[nz, 1]
        ncdf_varget, ncid, ncdf_varid(ncid, 'Start_Time'),        stime,       offset=[j],     count=[1]
        ncdf_varget, ncid, ncdf_varid(ncid, 'End_Time'),          etime,       offset=[j],     count=[1]
        mc_nc_varget,ncid, ['Number_Summed','Number_Scans'],      scanz, 1,    [j],            [1]
        k = j - limz(0)
        spekfits(j).velocity          = positions
        spekfits(j).sigma_velocity    = sigpos
        spekfits(j).temperature       = widths
        spekfits(j).sigma_temperature = sigwid
        spekfits(j).intensity         = areas
        spekfits(j).sigma_intensities = sigarea
        spekfits(j).background        = backgrounds
        spekfits(j).sigma_background  = sigbgnd
        spekfits(j).signal2noise      = sig2noise
        spekfits(j).chi_squared       = chi_squared
        spekfits(j).start_time        = stime
        spekfits(j).end_time          = etime
        spekfits(j).signal2noise      = sig2noise
        spekfits(j).number_summed     = scanz
        spekfits(j).record            = k
    endfor

;---The following code removes "wrapped" orders in the peak fitting:
    posarr = spekfits.velocity
    goods = where(abs(posarr) lt 1e4)
    cenpos = median(posarr(goods))
    nbad   = 1

    tries = 0
    while nbad gt 0 and tries lt 5000 do begin
          badz = where(posarr gt cenpos + nchan/2, nbad)
          if nbad gt 0 then posarr(badz) = posarr(badz) - nchan
          tries = tries + 1
    endwhile
    tries = 0
    nbad   = 1
    while nbad gt 0 and tries lt 5000 do begin
          badz = where(posarr lt cenpos - nchan/2, nbad)
          if nbad gt 0 then posarr(badz) = posarr(badz) + nchan
          tries = tries + 1
    endwhile
;---A second iteration of unwrapping, in case the median got changed by too much:
    goods = where(abs(posarr) lt 1e4)
    cenpos = median(posarr(goods))
    nbad   = 1
    tries = 0
    while nbad gt 0 and tries lt 5000 do begin
          badz = where(posarr gt cenpos + nchan/2, nbad)
          if nbad gt 0 then posarr(badz) = posarr(badz) - nchan
          tries = tries + 1
    endwhile
    nbad   = 1
    tries = 0
    while nbad gt 0 and tries lt 5000 do begin
          badz = where(posarr lt cenpos - nchan/2, nbad)
          if nbad gt 0 then posarr(badz) = posarr(badz) + nchan
          tries = tries + 1
    endwhile
    spekfits.velocity = posarr
end


;========================================================================
;   This routine tries to read an attribute, based on a list of possible names:
pro mc_nc_varget, ncid, namelist, targetvar, default, offset, count
    NCDF_CONTROL, 0, /NOVERBOSE
    targetvar = default
    for j = 0, n_elements(namelist)-1 do begin
        id = NCDF_VARID(ncid, namelist(j))
        if id ge 0 then ncdf_varget, ncid, ncdf_varid(ncid, namelist(j)), targetvar, offset=offset, count=count
    endfor
    NCDF_CONTROL, 0, /VERBOSE
end

;========================================================================
;   This routine tries to read an attribute, based on a list of possible names:
pro mc_glob_attget, ncid, namelist, targetvar, default
    NCDF_CONTROL, 0, /NOVERBOSE
    targetvar = default
    for j = 0, n_elements(namelist)-1 do begin
        desc = NCDF_ATTINQ( ncid,  namelist(j), /GLOBAL)
        if desc.datatype ne 'UNKNOWN' then ncdf_attget, ncid, namelist(j), targetvar, /GLOBAL
    endfor
    NCDF_CONTROL, 0, /VERBOSE
end

;========================================================================
;
;   This is the entry point for reading SDI netCDF data:
;
;========================================================================

pro sdi3k_read_netcdf_data, filename, $
                            metadata=metadata, $
                            spex=spex, $
                            spekfits=spekfits, $
                            winds=winds, $
                            image=image, $
                            phasemap=phasemap, $
                            zonemap=zonemap, $
                            range=range

@sdi3k_ncdf_inc.pro
;--Lookup the ncid from the filename. Use existing ncid if already open, else open it:
   ncid = sdi3k_nc_get_ncid(filename, write_allowed=0)

;--Always read the meta data, even if we're not returning it:
   sdi3k_read_metadata, filename, ncid, metadata

   if not(keyword_set(range)) then range = [0,metadata.maxrec-1]

;--Now read each of the data types requested by the keywords supplied:
   if arg_present(spex)     then sdi3k_read_spex,     ncid, spex,     metadata, range
   if arg_present(spekfits) then sdi3k_read_spekfits, ncid, spekfits, metadata, range
   if arg_present(winds)    then sdi3k_read_winds,    ncid, winds,    metadata, range
   if arg_present(image)    then sdi3k_read_image,    ncid, image,    metadata, range
   if arg_present(phasemap) then sdi3k_read_phasemap, ncid, phasemap, metadata, range
   if arg_present(zonemap)  then sdi3k_read_zonemap,  ncid, zonemap,  metadata, range
end
