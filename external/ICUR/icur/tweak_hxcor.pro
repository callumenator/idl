;**************************************************************
pro tweak_hxcor,file,record,xxc,x,arr,ids,flag,helpme=helpme,wave=wave, $
    do2=do2,halpha=halpha,second=second,auto=auto
COMMON COMXY,XCUR,YCUR,ZERR,RESETSCALE,lu3
COMMON VARS,VAR1,VAR2,VAR3,Vrot,VAR5,psdel,prffit,vrot2
COMMON COM1,H,IK,IFT,NSM,C,NDAT,IFSM,KBLO,H2,ipdv,ihcdev
common com2,a,ea,fh,fixt,ishape
common icurunits,xunits,yunits,title,c1,c2,c3,ch
;
h2=0
nsm=1
c1=!p.color
var1=0
ihcdev='PS'
flag=0
lu3=-1
nofile=1
update=0
xunits='km/s'
!p.title=''
if not keyword_set(do2) then second=0
case 1 of
   ifstring(file): begin
      nofile=0
      if strlen(get_ext(file)) eq 0 then file=file+'_xcor'
      case 1 of
         keyword_set(auto): file=file+'_a'
         keyword_set(wave): file=file+'_w'
         keyword_set(do2): file=file+'_2'
         keyword_set(halpha): file=file+'_h'
         else:
         endcase
      file=file+'.sav'
      x=fltarr(1024)
      xxc=fltarr(1024,100)
      if keyword_set(do2) then begin
         x2=fltarr(1024)
         xxc2=fltarr(1024,100)
         endif
      if keyword_set(do2) then nel=12 else nel=7
      arr=fltarr(nel,100)
      ids=strarr(100)
      restore,file
      nr=n_elements(ids)
      if n_elements(record) eq 0 then begin
         record=0
         read,prompt=' Enter record number: ',record
         record=(record>0)<(nr-1)
         endif
      end
   n_params() eq 6:         ;data passed from HXCOR
   n_params() eq 7:         ;data passed from HXCOR
   else: helpme=1
   endcase
;
if keyword_set(helpme) then begin
   print,' '
   print,'* TWEAK_HXCOR,file,record '
   print,' '
   return
   endif
;
restart:
a=0.
if keyword_set(second) then off=7 else off=0
mcz=arr(0+off,record)
hv=arr(1+off,record)
v0=mcz-hv
mwid=arr(2+off,record)    ;a(2)
dw=arr(6,record)
print,ids(record)
x0=mcz/dw     ;a(1)
nrecords=n_elements(ids)
title=ids(record)
;
!p.title='!6 Record= '+strtrim(record,2)+' velocity='+strtrim(hv,2)
!x.title='!6 km/s'
!y.title='!6 Correlation product'
;
setxy,-1000.,1000.,0.,0.
xc=xxc(*,record)
xv=x*dw
plot,xv,xc,ps=10
oplot,[hv,hv],!y.crange,linesty=1,color=5
wshow
xcur=0 & ycur=mean(!y.crange)
a=fltarr(4)
a(2)=2.
a(3)=mean(xc)
ifit=0
zerr=0
newrec=0
k=indgen(1024) & nk=1024
while zerr ne 48 do begin
   blowup,-1
   if (zerr eq 32) then begin      ;space
      print,xcur,' km/s'
      endif
   if (zerr eq 63) then begin      ;?
      print,' A: plot entire range'
      print,' C: plot central 1000 km/s'
      print,' F: Fit using ICFIT'
      print,' G: perform Gaussian Fit - place cursor at peak'
      print,' I: restart this star'
      print,' M: mark mean level'
      print,' U: update array'
      print,' X: select X range'
      print,' Z: stop'
      print,' Q, 0: exit'
      endif
   if (zerr eq 65) or (zerr eq 97) then begin      ;A
      setxy
      k=indgen(1024)
      nk=1024
      plot,xv,xc,ps=10
      oplot,[hv,hv],!y.crange,linesty=1,color=5
      wshow
      endif
   if (zerr eq 67) or (zerr eq 99) then begin      ;C
      setxy,-1000.,1000.
      plot,xv,xc,ps=10
      oplot,[hv,hv],!y.crange,linesty=1,color=5
      wshow
      k=where((xv gt !x.range(0)) and (xv lt !x.range(1)),nk)
      endif
   if (zerr eq 70) or (zerr eq 102) then begin      ;F
      defsysv,'!verbose',0

      !p.title=''
      icpars=0
      yf=100
      icfit2,xv,xc,yf,icpars,dtype=2
      nlines=(n_elements(a)-3)/3
      zv='velocit' & zw='net width'
      if nlines gt 1 then zv=zv+'ies: ' else zv=zv+'y: '
      if nlines gt 1 then zw=zw+'s: ' else zw=zw+': '
      zs=' '
      errfmt='(F6.2)'
      hbin=dw                  ;1 bin error
      xbin=hbin*.1                 ;adopted systematic errors = +\-0.1 bins
      print,' +/- 0.5 bin uncertainty  -> +/-',string(hbin,errfmt),' km/s.'
      netwid=0. & neterr=0.
      hv=a(4)
      ifit=1
      for i=1,nlines do begin
         if i gt 1 then zs=', '
         ic=i*3+1
         i0=xindex(xv,a(ic))
         wl=abs(a(ic+1))
         i1=(fix(i0-wl-0.5)<(n_elements(xc)-1))>0
         i2=(fix(i0+wl+0.5)>0)<(n_elements(xc)-1)
         if i1 gt i2 then begin
            tmp=i1 & i1=i2 & i2=tmp
            endif
         vh=a(ic)
         ctrd=total(xc(i1:i2)*xv(i1:i2))/total(xc(i1:i2))+hbin/2.
         vu=ea(ic)>xbin          ;   vu=ea(ic)*mdw*vc>xbin
         wu=ea(ic+1)>0.5
         si=string(i,'(I2)')
         zv=zv+zs+string(vh,'(F7.2)')+' +/- '+string(vu,errfmt)+' km/s'
    print,' heliocentric velocity of component',si,' is ',string(vh,'(F7.2)'),' 
         print,'                          centroid at    ',string(ctrd,'(F7.2)')
;   if wl lt autowid then begin
;      z=' (Unresolved line)'
;      zw=zw+zs+z
;      endif else begin
;      netwid=sqrt(wl*wl-autowid*autowid)*mdw*vc/rotvelcal
;      errawid=xbin                             ;error 0.1 bins
;      neterr=sqrt(wu*wu+errawid*errawid)*mdw*vc
;      z=string(netwid,'(F6.2)')+' +/- '+string(neterr,'(F5.2)')
;      zw=zw+zs+z
;      z=' net width= '+z
;      endelse
;   wl=wl*mdw*vc
;   wu=wu*mdw*vc
;   print,' width of component',si,' is ',string(wl,'(F7.2)'),' +/-',string(wu,e
         endfor
      endif
;
   if (zerr eq 71) or (zerr eq 103) then begin      ;G  Gaussian fit
      a(3)=mean(xc(k))
      a(2)=4.
      a(0)=ycur-a(3) & a(1)=xcur
      if nk lt 2 then begin
         print,' ERROR:'
         help,nk
         stop
         endif
      y=gaussfit(xv(k),xc(k),a,order=1)
      mcz=a(1)  ;*dw            ;*c*vcal
      mwid=a(2)
      hv=mcz-v0
      ifit=1
      oplot,xv(k),y,color=1
      wshow
      z=string(record,'(I4)')+': Vhel='+string(hv,'(F7.1)')+' '+ids(record)
      print,z
      endif
;
   if (zerr eq 73) or (zerr eq 105) then begin      ;I
      flag=1
      ZERR=81
      endif
;
   if (zerr eq 77) or (zerr eq 109) then a(3)=ycur  ;M  mark mean continuum
   if not nofile and (zerr eq 59) then begin      ; ; - next record
      record=record+1
      newrec=1
      if record ge nrecords then begin
         print,' record out of bounds: returning'
         newrec=0
         endif
      zerr=81
      endif
   if (zerr eq 82) or (zerr eq 114) then begin      ;R - new record
      r0=record
      read,prompt=' Enter next record number, -1 for next, -9 to end: ',record
      if record eq -1 then record=r0+1
      if record gt 0 then newrec=1
      if record ge nrecords then begin
         print,' record out of bounds: returning'
         newrec=0
         endif
      zerr=81
      endif
   if (zerr eq 81) or (zerr eq 113) or (zerr eq 126) then zerr=48  ;Quit
   if (zerr eq 85) or (zerr eq 117) then begin      ;U
      if ifit eq 0 then begin
         print,' You must refit the data before saving it'
         endif else begin
         arr(0,record)=mcz
         arr(1,record)=hv
         arr(2,record)=mwid
         update=1
         print,' Fit to record ',record,' updated'
         endelse
      endif
   if (zerr eq 88) or (zerr eq 120) then begin   ;X
      blowup,1
      plot,xv,xc,ps=10
      oplot,[hv,hv],!y.crange,linesty=1,color=5
      wshow
      k=where((xv gt !x.range(0)) and (xv lt !x.range(1)),nk)
      endif
   if (zerr eq 90) or (zerr eq 122) then stop   ;Z
   endwhile
;
if newrec then goto,restart
if update and not nofile then begin
   save,arr,x,xxc,ids,file=file
   print,' Save file ',file,' updated'
   endif
return
end
