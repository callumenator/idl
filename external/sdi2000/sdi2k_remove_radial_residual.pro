pro sdi2k_remove_radial_residual, resarr, parname=parname, multiplicative=mp, recsel=recsel
@sdi2kinc.pro

  if n_elements(resarr) lt 3 then return
  rex = indgen(n_elements(resarr))
  if keyword_set(recsel) then rex = recsel
  if not(keyword_set(parname)) then parname = 'VELOCITY'
  nn   = 0
  yidx = where(strupcase(parname) eq strupcase(tag_names(resarr(0))), nn)
  if nn le 0 then return
  yidx = yidx(0)


  nz       = fix(total(host.operation.zones.sectors(0:host.operation.zones.fov_rings-1)))
  ncrecord = n_elements(resarr)
  ncnrings = host.operation.zones.fov_rings
  radres = fltarr(ncnrings)
  lims   = intarr(ncnrings)
  nsum   = intarr(ncnrings)
  ridx   = intarr(nz)
  zres   = fltarr(nz)

; Build an array specifying ring numbers for each zone:
  for rr=0,ncnrings-1 do lims(rr) = total(host.operation.zones.sectors(0:rr))
  for zz=0,nz-1 do begin
      ringz  = where(lims gt zz)
      ridx(zz) = ringz(0)
  endfor

; Compute average shift in each ring:
  for rr=0,ncnrings-1 do begin
      rzz    = where(ridx eq rr)
      radres(rr) = median(resarr(rex).(yidx)(rzz))
  endfor

; Force the center correction to be 1 (multiplicative) or the center correction to be zero (additive):
  if keyword_set(mp) then radres = radres/radres(0) else radres = radres - radres(0)
; Note: For zero average additive correction use radres = radres - total(radres)/ncnrings


; Assign a residual value for each zone from the values for each ring:
  for zz=0,nz-1 do begin
      zres(zz) = radres(ridx(zz))
  endfor
  
; Subtract the residual map:
  for rcd=0,ncrecord-1 do begin
      if keyword_set(mp) then resarr(rcd).(yidx) = resarr(rcd).(yidx)/zres $
      else resarr(rcd).(yidx) = resarr(rcd).(yidx) - zres
  endfor
end

