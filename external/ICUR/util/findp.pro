;***************************************************************************
pro findp,all=all,usnoc=usnoc,gsc=gsc,hydra=hydra, $
      helpme=helpme,stp=stp
                       ;get position on sky plot
; 3/24/99: YBS not working
common grid,sc,atn,dtn,ddec,dr,equinox
common gsc,ras,decs,mags,cls,pe,me,rec,id,b,plate,mult,filename
common usnocat,usno,usno1,cd0
common hydra_pht,phot
;
if keyword_set(helpme) then begin
   print,' '
   print,'* FINDP - find/mark point on sky plot'
   print,'*    cursor readout is continuous'
   print,'*    hit LEFT mouse button to print coordinates'
   print,'*    hit CENTER mouse button to mark nearest star'
   print,'*    hit RIGHT mouse button to exit'
   print,'*'
   print,'*   KEYWORDS:'
   print,'*      ALL: include plate information in output list'
   print,' '
   return
   endif
if n_elements(sc) eq 0 then begin
   print,' COMMON array GRID must be filled'
   return
   endif
;
if (n_elements(ras) eq 0) then usnoc=1
if (n_elements(usno) eq 0) then gsc=1
if (n_elements(usno) eq 1) and keyword_set(usnoc) then gsc=0
hydra_ph=0 & hydra_in=0
if keyword_set(hydra) then case 1 of
   hydra eq 2: hydra_ph=1 
   n_tags(phot) gt 1: hydra_ph=1
   else: hydra_in=1
   endcase
print,hydra_in,hydra_ph
;
ybs=0
case 1 of
   keyword_set(hydra_in): begin
      if n_elements(ras) eq 0 then begin
      print,' FINDP: to use HYDRA keyword, the GSC common block must be filled'
         return
         endif
      ra0=ras & dec0=decs         ;read from common
      usnoc=0 & gsc=0
      end
   keyword_set(hydra_ph): begin
      if n_elements(sc) eq 0 then sc=-1
      if sc le 0 then begin
         print,' You must display and image and run SET_COORDS first!'
         return
         endif
      ra0=phot.ra & dec0=phot.dec         ;read from common
      usnoc=0 & gsc=0
      end
   keyword_set(gsc): begin
      ra0=ras & dec0=decs & mag0=mags         ;read from common
      usnoc=0
      end
   else: begin                    ;usno
      ra0=usno.ra & dec0=usno.dec
      all=0
      gsc=0
      if n_elements(cd0) eq 0 then begin
         ybs=1 & usnoc=0
         endif
      end
   endcase
;
cr = string("15b)
xsize=(!x.crange(1)-!x.crange(0))*0.015
form1="($,'RA=',I2,I3,F6.2,', DEC=',I3,I3,F6.2,a)" 
case 1 of
   keyword_set(ybs): form2="($,I4,' ',I3,I3,F6.2,'  ',I3,I3,F6.2,F7.1,F7.1,a)"
   keyword_set(usnoc): form2="($,'  ',I3,I3,F6.2,'  ',I3,I3,F6.2,F7.1,F7.1,a)"
   keyword_set(gsc): form2="($,A9,'  ',I3,I3,F6.2,'  ',I3,I3,F6.2,F4.1,F7.1,F4.1,I4,a)" 
   keyword_set(hydra_in): form2="($,A20,'  ',I3,I3,F6.2,'  ',I3,I3,F6.2,' ',A1,a)" 
   keyword_set(hydra_ph): form2= $
"($,A15,'  ',I3,I3,F6.2,'  ',I3,I3,F6.2,' ',F6.2,' ',F6.2,' ',f6.2,' ',I3,I3,a)" 
   else: form2="($,A9,'  ',I3,I3,F6.2,'  ',I3,I3,F6.2,F4.1,F7.1,F4.1,I4,a)" 
   endcase
print,' hit left mouse button at position; center to mark, right to end'
zerr=0
print,form="($,a)",string("12b)   ;print new line
case 1 of
   keyword_set(usnoc): z= $
        ' USNO:  RA  ('+string(equinox,'(F6.1)')+')  DEC    Bmag   Rmag '
   keyword_set(ybs): z= $
        ' BS        RA  ('+string(equinox,'(F6.1)')+')  DEC       Bmag   Vmag '
   keyword_set(gsc): z= $
'  GSC ID        RA   ('+string(equinox,'(F6.1)')+')  DEC    +/-    MAG +/-  class'
   keyword_set(hydra_in): z= $
'      ID                RA   ('+string(equinox,'(F6.1)')+')  DEC  class'
   keyword_set(hydra_ph): z= $
      '      ID             RA   ('+string(equinox,'(F6.1)')+ $
      ')  DEC        V     V-R    R-I   PMS  Xray'
   else: z='        RA  ('+string(equinox,'(F6.1)')+')  DEC    Bmag   '
   endcase
print,z
if !d.name eq 'X' then wshow
while (zerr lt 4) do begin
   wait,.1
   zerr=0
   cursor,x,y,2
   zerr=!err
   xytad,ra,dec,x,y
   degtohms,ra/dr,h,m,s
   degtodms,dec/dr,dd,dm,ds
   case 1 of
      zerr le 0: begin
         print,form=form1,h,m,s,dd,dm,ds,cr
         wait,.1
         end
      (zerr eq 1) or (zerr eq 2): begin
         d=angd(ra/dr,dec/dr,ra0,dec0) & k=where(d eq min(d)) & k=k(0)
         degtohms,ra0(k),h,m,s
         degtodms,dec0(k),dd,dm,ds
         case 1 of
            keyword_set(usnoc): $
                 print,form=form2,h,m,s,dd,dm,ds,usno(k).bmag,usno(k).rmag,cr
            keyword_set(ybs): $
                 print,form=form2,zone(k),h,m,s,dd,dm,ds,bmag(k),rmag(k),cr
            keyword_set(hydra_in): $
             print,form=form2,id(k),h,m,s,dd,dm,ds,cls(k),cr
            keyword_set(hydra_ph): $
             print,form=form2,phot(k).id,h,m,s,dd,dm,ds,phot(k).v, $
          phot(k).vmr,phot(k).rmi,(phot(k).pms and 15),(phot(k).xray and 15),cr
            else: $       ;keyword_set(gsc): $
             print,form=form2,id(k),h,m,s,dd,dm,ds,pe(k),mags(k),me(k),cls(k),cr
            endcase           
         print,form="($,a)",string("12b)   ;print new line
         if keyword_set(all) then print,'   ',b(k),' ',plate(k),' ',mult(k)
         adtxy,ra0(k)*dr,dec0(k)*dr,x,y
         tvcrs,x,y,/data
         if zerr eq 2 then begin
            x0=x-2.*xsize & x1=x-xsize
            oplot,[x0,x1],[y,y],psym=0
            x0=x+2.*xsize & x1=x+xsize
            oplot,[x0,x1],[y,y],psym=0
            endif
          wait,0.1
         end
      else:
      endcase
   endwhile
;
if keyword_set(stp) then stop,'FINDP>>>'
return
end
