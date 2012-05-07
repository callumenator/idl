;****************************************************************************
function zendist,a1,a2,ha=ha,lat=lat,altaz=altaz
if n_params(0) lt 2 then begin
   print,' '
   print,'* ZENDIST - compute zenith distance given HA and dec -OR- '
   print,'*           compute HA for given zenith distance and dec'
   print,'*   calling sequence: X=ZENDIST(a1,a2)
   print,'*      a1: hour angle (default), or zenith distance if /HA is set'
   print,'*      a2: target declination'
   print,'*   
   print,'*    KEYWORDS: HA - set to return hour angle. In this case the'
   print,'*                  variable a1 represents the zenith distance'
   print,'*            ALTAZ - compute azimuth and altitude. '
   print,'*                    Inputs a1,a2= HA, dec'
   print,'*                    Output ZD, Az, in a1,a2.'
   print,'*              LAT - observers latitude, def=+31.963 (KPNO)'
   print,'*
   print,'*   all inputs are in decimal degrees'
   print,' '
   return,-1
   endif
;
np=n_elements(a1)        ;number of points
out=a1
if not keyword_set(lat) then lat=31.963/!radeg
case 1 of
   keyword_set(ha): begin      ;return HA
      delta=a2/!radeg
      a=(90.-a1)/!radeg        ;convert ZD to elevation
      out=acos((sin(a)-sin(delta)*sin(lat))/cos(delta)*cos(lat))*!radeg
      end
;
   keyword_set(altaz): begin
      delta=a2/!radeg
      ha=a1/!radeg
      elev=asin(sin(delta)*sin(lat)+cos(delta)*cos(ha)*cos(lat))
      az=atan(-cos(delta)*sin(ha),sin(delta)*cos(lat)-cos(delta)*cos(ha)*sin(lat))
      out=90.-elev*!radeg         ;zenith distance
      a1=out
      a2=az*!radeg
      k=where(az lt 0.,count)
      if count gt 0 then a2(k)=360.+a2(k)
      end
;
   else: begin    ;default - give zenith distance
      out=angd(a1,a2,0.,lat)
      end
   endcase
;
return,out
end
