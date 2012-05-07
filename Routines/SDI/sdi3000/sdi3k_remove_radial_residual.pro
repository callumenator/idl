pro sdi3k_remove_radial_residual, mm, spekfits, parname=parname, multiplicative=mp, recsel=recsel, zero_mean=zero_mean

  if n_elements(spekfits) lt 3 then return

  rex = indgen(n_elements(spekfits))
  if keyword_set(recsel) then rex = recsel
  if not(keyword_set(parname)) then parname = 'VELOCITY'
  nn   = 0
  yidx = where(strupcase(parname) eq strupcase(tag_names(spekfits(0))), nn)
  if nn le 0 then return
  yidx = yidx(0)

  nz        = mm.nzones
  ncrecord  = n_elements(spekfits)
  ncnrings  = mm.rings
  radres    = fltarr(ncnrings)
  lims      = intarr(ncnrings)
  nsum      = intarr(ncnrings)
  ridx      = intarr(nz)
  zres      = fltarr(nz)
  ringzones = fltarr(ncnrings)

; Build an array specifying ring numbers for each zone:
  for rr=0,ncnrings-1 do lims(rr) = total(mm.zone_sectors(0:rr))
  for zz=0,nz-1 do begin
      ringz  = where(lims gt zz)
      ridx(zz) = ringz(0)
  endfor

; Compute average shift in each ring:
  for rr=0,ncnrings-1 do begin
      rzz    = where(ridx eq rr, nn)
      if nn gt 0 then begin
         radres(rr) = median(spekfits(rex).(yidx)(rzz))
         ringzones(rr)  = nn
      endif
  endfor

; Force the center correction to be 1 (multiplicative) or the center correction to be zero (additive):
  if keyword_set(mp) then radres = radres/radres(0) else begin
     if keyword_set(zero_mean) then begin
        radres = radres - total(radres*ringzones)/total(ringzones)
     endif else radres = radres - radres(0)
  endelse
; Note: For zero average additive correction weighted equally per ring, use radres = radres - total(radres)/ncnrings


; Assign a residual value for each zone from the values for each ring:
  for zz=0,nz-1 do begin
      zres(zz) = radres(ridx(zz))
  endfor

; Subtract the residual map:
  for rcd=0,ncrecord-1 do begin
      if keyword_set(mp) then spekfits(rcd).(yidx) = spekfits(rcd).(yidx)/zres $
      else spekfits(rcd).(yidx) = spekfits(rcd).(yidx) - zres
  endfor
end

