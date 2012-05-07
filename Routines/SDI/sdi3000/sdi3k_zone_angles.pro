pro sdi3k_zone_angles, mm, sky_fov, rad, theta, ridx
;-For each zone, calculate the mean zenith angle and bearing values analytically:
       nz       = mm.nzones
       rad   = fltarr(nz)
       theta = fltarr(nz)
       ridx  = bytarr(nz)
       sidx  = ridx
       rcnt  = 0
       resulr= fltarr(nz)
       for j=1,nz-1 do begin
           rcnt = rcnt + 1
           ridx(j) = ridx(j-1)
           sidx(j) = sidx(j-1) + 1
           if rcnt eq mm.zone_sectors(ridx(j-1)) then begin
              ridx(j) = ridx(j-1) + 1
              sidx(j) = 0
              rcnt = 0
           endif
           if ridx(j) eq 0 then begin
              rad(j) = 0
              theta(j) = 0
           endif else begin
              rad(j)   = (mm.zone_radii(ridx(j)) + mm.zone_radii(ridx(j)-1))/2
              theta(j) = (sidx(j) + 0.5)*360/mm.zone_sectors(ridx(j)) + 90. + mm.rotation_from_oval
              if strpos(strupcase(strcompress(mm.site, /remove_all)), 'MAWSON') ge 0 then begin
              	theta(j) = theta(j) + 180.
              endif
              while theta(j) lt 0.   do theta(j) = theta(j) + 360.
              while theta(j) gt 360. do theta(j) = theta(j) - 360.
           endelse
       endfor
       rad   = (rad*sky_fov/100)*!pi/180
       theta = theta*!pi/180
end