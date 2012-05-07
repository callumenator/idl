
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; write a FITS file containing the image array
;
; if flag write_full_fits is set, the full frame
; array (600x140) is written to the FITS file.
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 18-Dec-2003

pro write_fits_image, out

@euv_imtool-commons

hdr = strarr(30)

; ------------------------------
; create the header string array
; ------------------------------
simple  = 'SIMPLE  =                    T /'
bitpix  = 'BITPIX  =                  -32 /'
naxis   = 'NAXIS   =                    2 /'

if(write_full_fits) then begin
    naxis1  = 'NAXIS1  =                  600 /'
    naxis2  = 'NAXIS2  =                  140 /'
endif else begin
    naxis1  = 'NAXIS1  =                  140 /'
    naxis2  = 'NAXIS2  =                  150 /'
endelse

linear  = 'LINEAR  =                    T /'
overlap = 'OVERLAP =                    4 /'
comment = 'IMTIME  = ' + "'" + STRING(s0year,s0doy,$
                                      s0hour,s0min,$
                                      s0sec,$
                                      format='(i4,"/",i3.3,"/",i2.2,":",i2.2,":",i2.2)') + "'" + '  / (sensor 0 time)'

imagex = 'IMAGE_X = ' + STRING(image_x,format='(11x,f9.2)') + $
  ' / (km, GCI system)'
imagey = 'IMAGE_Y = ' + STRING(image_y,format='(11x,f9.2)') + $
  ' / (km, GCI system)'
imagez = 'IMAGE_Z = ' + STRING(image_z,format='(11x,f9.2)') + $
  ' / (km, GCI system)'

imagevx = 'IMAGE_VX= ' + STRING(image_vx,format='(12x,f8.2)') + $
  ' / (km/sec, GCI system)'
imagevy = 'IMAGE_VY= ' + STRING(image_vy,format='(12x,f8.2)') + $
  ' / (km/sec, GCI system)'
imagevz = 'IMAGE_VZ= ' + STRING(image_vz,format='(12x,f8.2)') + $
  ' / (km/sec, GCI system)'

sunx = 'SUN_X   = ' + STRING(sun_x,format='(6x,f14.2)') + $
  ' / (km, GCI system)'
suny = 'SUN_Y   = ' + STRING(sun_y,format='(6x,f14.2)') + $
  ' / (km, GCI system)'
sunz = 'SUN_Z   = ' + STRING(sun_z,format='(6x,f14.2)') + $
  ' / (km, GCI system)'

moonx = 'MOON_X  =  ' + STRING(moon_x,format='(5x,f14.2)') + $
  ' / (km, GCI system)'
moony = 'MOON_Y  =  ' + STRING(moon_y,format='(5x,f14.2)') + $
  ' / (km, GCI system)'
moonz = 'MOON_Z  =  ' + STRING(moon_z,format='(5x,f14.2)') + $
  ' / (km, GCI system)'

simlat = 'IMAGELAT= ' + STRING(image_gci_lat,format='(13x,f7.2)') + $
  ' / (degrees, GCI system)'
simlong= 'IMAGELON= ' + STRING(image_gci_lon,format='(13x,f7.2)') + $
  ' / (degrees, GCI system)'
simlongw = 'IMAGWLON= ' + STRING(image_w_lon,format='(13x,f7.2)') + $
  ' / (degrees, GEO system)'
sunlong= 'IMAGSLON= ' + STRING(solarlong,format='(13x,f7.2)') + $
  ' / (degrees)'

julday = 'JUL_DAY = ' + STRING(jd+2400000.0,format='(7x,f13.5)') + $
  ' / (Julian Day of midpoint)'

spinx = 'SPINAXX = ' + STRING(spin_axis_x,format='(10x,f10.7)') + ' /'
spiny = 'SPINAXY = ' + STRING(spin_axis_y,format='(10x,f10.7)') + ' /'
spinz = 'SPINAXZ = ' + STRING(spin_axis_z,format='(10x,f10.7)') + ' /'

tau = 'TAU     = ' + STRING(tau,format='(17x,f3.1)') + ' /'


hdr[0] =  simple + string( replicate(32b,80-strlen(simple)))
hdr[1] =  bitpix + string( replicate(32b,80-strlen(bitpix)))
hdr[2] =  naxis +  string( replicate(32b,80-strlen(naxis)))
hdr[3] =  naxis1 + string( replicate(32b,80-strlen(naxis1)))
hdr[4] =  naxis2 + string( replicate(32b,80-strlen(naxis2)))
hdr[5] =  linear + string( replicate(32b,80-strlen(linear)))
hdr[6] =  overlap + string( replicate(32b,80-strlen(overlap)))
hdr[7] =  tau + string( replicate(32b,80-strlen(tau)))
hdr[8] =  comment + string( replicate(32b,80-strlen(comment)))
hdr[9] =  imagex + string( replicate(32b,80-strlen(imagex)))
hdr[10] =  imagey + string( replicate(32b,80-strlen(imagey)))
hdr[11] =  imagez + string( replicate(32b,80-strlen(imagez)))
hdr[12] =  imagevx + string( replicate(32b,80-strlen(imagevx)))
hdr[13] =  imagevy + string( replicate(32b,80-strlen(imagevy)))
hdr[14] =  imagevz + string( replicate(32b,80-strlen(imagevz)))
hdr[15] =  sunx + string( replicate(32b,80-strlen(sunx)))
hdr[16] = suny + string( replicate(32b,80-strlen(suny)))
hdr[17] = sunz + string( replicate(32b,80-strlen(sunz)))
hdr[18] = moonx + string( replicate(32b,80-strlen(moonx)))
hdr[19] = moony + string( replicate(32b,80-strlen(moony)))
hdr[20] = moonz + string( replicate(32b,80-strlen(moonz)))
hdr[21] = simlat + string( replicate(32b,80-strlen(simlat)))
hdr[22] = simlong + string( replicate(32b,80-strlen(simlong)))
hdr[23] = simlongw + string( replicate(32b,80-strlen(simlongw)))
hdr[24] = sunlong + string( replicate(32b,80-strlen(sunlong)))
hdr[25] = spinx + string( replicate(32b,80-strlen(spinx)))
hdr[26] = spiny + string( replicate(32b,80-strlen(spiny)))
hdr[27] = spinz + string( replicate(32b,80-strlen(spinz)))
hdr[28] = julday + string( replicate(32b,80-strlen(julday)))
hdr[29] =  'END' + string(replicate(32b,77))

; ----------------------------------
; write the FITS file (linear array)
; ----------------------------------
if(write_full_fits) then begin
    writefits,out,working_dmap,hdr
endif else begin
    writefits,out,workarray[*,75:224],hdr
endelse

end

