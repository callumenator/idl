;*****************************************************************************
pro wiyn_icur,file,out=out,examine=examine,helpme=helpme,stp=stp, $
              nosave=nosave,plt=plt,etype=etype,debug=debug, $
              sky=sky,meansky=meansky,trim=trim
if (not ifstring(file)) and (n_elements(meansky) eq 0) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* WIYN_ICUR - convert WIYN .MS spectra in .FITS files to ICD format'
   print,'*    calling sequence: WIYN_ICUR,file'
   print,'*       file: input file name'
   print,'* '
   print,'*    KEYWORDS:'
   print,'*       OUT:     name of output .ICD file'
   print,'*       PLT:     set to plot spectra'
   print,'*       SKY:     set to do sky spectra only'
   print,'*       TRIM:    points to trim, def=[2,10]'
   print,'*       EXAMINE: set to examine data'
   print,'*       NOSAVE:  set to bypass .ICD file'
   print,'*       MEANSKY: name of mean sky file'
   print,' '
   return
   endif
;
if n_elements(trim) ne 2 then trim=[2,10]
tr1=trim(0) & tr2=trim(1)
if n_elements(meansky) gt 0 and not keyword_set(sky) then msky=1 else msky=0
if not keyword_set(sky) then sky=0 else sky=1
if sky or msky then begin
   if not ifstring(meansky) then begin
      meansky=''
      read,meansky,prompt=' Please enter name of .FITS file containing mean sky spectrum: '
      endif
   dsky=readfits(meansky,h,/short)
   if msky then data=dsky
   endif
if (n_elements(file) eq 0) and not msky then begin
   file=''
   read,file,prompt=' Enter name of .FITS file (no extension): '
   if strlen(file) eq 0 then return
   endif
if keyword_set(out) then icdf=out else icdf='wiyn'
if strlen(get_ext(icdf)) eq 0 then icdf=icdf+'.icd'
;
if not msky then begin
   if strlen(get_ext(file)) eq 0 then file=file+'.fits'
   data=readfits(file,h,/shorth)
   endif
nx=fix(getval('naxis',h))          ;number of axes
np=fix(getval('naxis1',h))          ;number of points
if nx eq 1 then ns=1 else ns=fix(getval('naxis2',h))           ;number of stars
;
;set up header info
;
case 1 of
   strupcase(getval('ctype1',h,/noap)) eq 'MULTISPE': begin
      ww=getval('wat2_001',h,/noap)
      k=strpos(ww,'1 1 0 ')
      ww=strmid(ww,k+6,60)
      k=strpos(ww,' ')
      w0=double(strmid(ww,0,k)) & dw=double(strmid(ww,k,24))
      end
   strupcase(getval('ctype1',h,/noap)) eq 'LINEAR': begin
      w0=double(getval('crval1',h)) & dw=double(getval('cd1_1',h))
      if dw le 0. then dw=double(getval('cdelt1',h))
      end
   else: begin
      print,' ERROR: unknown CTYPE = ',getval('ctype1',h)
      stop
      return
      end
   endcase
wave=w0+dw*findgen(np)
wave=wave(tr1:np-tr2)
if sky then dsky=dsky(tr1:np-tr2)
eps=100
;
title=''
obs=strtrim(getval('OBSERVAT',h,/noap),2)
tel=strtrim(getval('TELESCOP',h,/noap),2)
instr=strtrim(getval('instrume',h,/noap),2)
head=intarr(512)
case 1 of
   strupcase(getval('detector',h,/noap)) eq 'GCAM': head(3)=10 
   strupcase(strmid(tel,0,4)) eq 'WIYN': head(3)=15
   else: head(3)=11
   endcase
ncomb=fix(getval('ncombine',h))
if ncomb lt 1 then ncomb=1
time=double(getval('exptime',h))*ncomb
if time lt 32767. then head(5)=fix(time) else head(5)=-fix(time/60.)
head(6)=1
head(7)=np
d=getval('date-obs',h,/noap)              ;date
if ifstring(d) then begin
   head(10)=fix(strmid(d,3,2)) & head(11)=fix(strmid(d,0,2))
   head(12)=fix(strmid(d,6,2))
   print,d,head(10:12)
   endif
d=getval('ut',h,/noap)              ;UT
if ifstring(d) then begin
   head(13)=fix(strmid(d,0,2)) & head(14)=fix(strmid(d,3,2))
   head(15)=fix(strmid(d,6,2))
   print,d,head(13:15)
   endif
d=getval('st',h,/noap)              ;ST
if ifstring(d) then begin
   head(16)=fix(strmid(d,0,2)) & head(17)=fix(strmid(d,3,2))
   head(18)=fix(strmid(d,6,2))
   print,d,head(16:18)
   endif
head(19)=30000
head(20)=fix(w0) & head(21)=head(19)*(w0-fix(w0))
head(22)=fix(dw) & head(23)=head(19)*(dw-fix(dw))
head(199)=333
print,w0,dw,head(20:23)
head(33)=0
airmass=float(getval('airmass',h))
head(49)=fix(100.*airmass)
print,'airmass: ',airmass,head(49)
;
kfib=where(strmid(h,0,5) eq 'SLFIB',nkfib)
hfib=h(kfib)
hfib=strmid(hfib,11,80)
ftype=intarr(nkfib)
i1=0 & i2=0
for i=0,nkfib-1 do begin
   reads,hfib(i),i1,i2
   ftype(i)=i2
   endfor
ksky=where(ftype eq 0,nksky)
if sky and (nx eq 1) then nksky=1
if sky then case 1 of
   nksky eq 0: begin
      print,' There are no SKY records in this file - returning
      return
      end
   else: print,nksky,' SKY spectra found'
   endcase
ktarget=where(ftype eq 1)
kc=strpos(hfib,':')-2
for i=0,nkfib-1 do hfib(i)=strmid(hfib(i),kc(i),80)
l=strlen(hfib)
for i=0,nkfib-1 do hfib(i)=strmid(hfib(i),0,l(i)-3)
hfib=strtrim(hfib,2)
hid=hfib(where((ftype eq 1) or (ftype eq 0)))
;
; fudges
if n_elements(m6) eq 0 then m6=0
if strupcase(file) eq 'MH061.FITS' then m6=1
if strupcase(file) eq 'MH062.FITS' then m6=2
if strupcase(file) eq 'MH063.FITS' then m6=3
if strupcase(file) eq 'MH151.FITS' then m6=4
if (m6 ge 1) and (m6 le 3) then begin
   hid=hfib(where((ftype le 1) and (ftype gt-2)))
   if m6 eq 1 then hid=[hid(0:2),hid(8:*)]
   k=strpos(strupcase(hid),'NOT ASSIGNED')
   na=where(k eq -1)
   if m6 lt 3 then hid=hid(na)
   if m6 eq 3 then hid=[hid(0:8),hid(10:40),hid(42:68),hid(70:71), $
         hid(73:79),hid(81),hid(83:*)]
   endif
;
if strupcase(file) eq 'ORI6B1.FITS' then begin
   k=where(strmid(h,0,6) eq 'APID88',nk) & k=k(0)
   t=["APID88  = '5:27:56.50 -01:44:53.7 GSC  4753 1658 12.41 (63)'", $
     "APID89  = '5:26:57.81 -01:39:58.8 GSC  4753 1188 12.64 (72)'", $
     "APID90  = '5:20:04.46 -01:42:31.6 GSC  4753 1760 13.90 (49)'"]
   h=[h(0:k-1),t,h(k+1:*)]
   m6=601
   endif
if strupcase(file) eq 'ORI6B3.FITS' then m6=603
if keyword_set(debug) then stop
;
ras=strtrim(strmid(hid,0,11),2)
decs=strtrim(strmid(hid,11,11),2)
;
for i=0,ns-1 do begin    ;loop over stars
   if msky then title=' Mean sky spectrum from '+strtrim(meansky,2) else begin
      id='APID'+strtrim(i+1,2)
      title=getval(id,h,/noap)
      endelse
   if m6 gt 0 then title=strtrim(strmid(title,22,40),2)
   title=title+'                                                           '
   title=strmid(title,0,59)
   head(100)=byte(title)
   print,title
;
   case 1 of
      strpos(strupcase(title),'NOT ASSIGNED') ne -1: print,' bypassing unassigned fiber'
      strpos(strupcase(title),'RANDOM POSITION') ne -1: print,' bypassing random fiber'
      (not sky) and (not msky) and (strpos(strupcase(title),'SKY') ne -1): $
                   print,' bypassing sky spectrum'
      sky and strpos(strupcase(title),'SKY') eq -1: print,' bypassing spectrum'
;      strupcase(strmid(title,0,3)) eq 'SKY': print,' bypassing sky spectrum'
      else: begin
         flux=data(*,i)
         flux=flux(tr1:np-tr2)             ;trim flux
         head(7)=n_elements(flux)
         d=ras(i)
         k=strpos(d,':')
         head(40)=fix(strmid(d,0,k)) & head(41)=fix(strmid(d,k+1,2))
         head(42)=fix(strmid(d,k+4,4)*100.)
         d=decs(i)
         sign=strmid(d,0,1)
         if sign ne '-' then d='+'+d
         k=strpos(d,':')
         head(43)=fix(strmid(d,0,k)) & head(44)=fix(strmid(d,k+1,2))
         head(45)=fix(strmid(d,k+4,4)*100.)
         dra=hmstodeg(head(40),head(41),head(42)/100.)  ; compute HA
         dst=hmstodeg(head(16),head(17),head(18))
         dha=dst-dra & if dha lt -180. then dha=360.-dha
         degtohms,dha,ha1,ha2,ha3
         head(46)=fix(ha1) & head(47)=fix(ha2) & head(48)=fix(ha3*100.)
;
         if sky then flux=flux+dsky
         if (keyword_set(examine)) or (keyword_set(plt)) then begin
            plot,wave,flux,title=file+': '+strtrim(title,2)
            if !d.name eq 'X' then wshow
            endif 
;
if keyword_set(debug) then stop
;
         if not keyword_set(nosave) then begin
            if keyword_set(etype) then $
               kdat,icdf,head,wave,flux,eps,-1,/islin,epstype=etype else $
               kdat,icdf,head,wave,flux,eps,-1,/islin
            endif else print,'Not saved: ',title
         end
      endcase
   endfor    ;ns
;
bell
if keyword_set(stp) then stop
return
end
