;*************************************************************************
pro stack,dfile
icurdata=getenv('icurdata')
if n_elements(icurdata) eq 0 then icurdata='[]'
if n_elements(file) eq 0 then dfile='scooph'
rec=0 & file=0
f1=99
read,' enter pairs (IDS/record); 0,0 to end',file,rec
while f1 ge 1 do begin
   read,f1,r1
   file=[file,f1] & rec=[rec,r1]
   endwhile
np=n_elements(file)-1
file=fix(file(0:np-1))
rec=fix(rec(0:np-1))
;
i2=(np)/2
yh=0.7/float(np+1)
setxy
!yticks=3
!p.title=''
for i=0,np-1 do begin
case 1 of
   i eq 0: begin
      !xticks=0
      !x.title='!6Angstroms'
      !y.title=''
      if np eq 1 then !y.title=ytit(0)
      gdat,icurdata+'ids'+strtrim(file(0),2),h,w0,f,e,rec(0)
      mt=string(byte(h(100:159)>32))
      !p.noeras=0
      !p.position=[.2,.2,.9,.2+yh]
      !c=-1
      plot,w0,f
      f0=f
      time=h(5)
      setxy,!x.crange(0),!x.crange(1)
      !p.noeras=1
      !x.title=''
      !xticks=-1
      end
   i eq np-1: begin
      !y.title=''
      end
   i eq i2: begin
      !y.title=ytit(0)
      end
   else: begin
      !y.title=''
      end
   endcase
   if i gt 0 then begin
      gdat,icurdata+'ids'+strtrim(file(i),2),h,w,f,e,rec(i)
      !p.position=[.2,.2+yh*i,.9,.2+yh*(i+1.)]
;      set_viewport,.2,.9,.2+yh*i,.2+yh*(i+1.)
      plot,w,f
      w1=w0
      f1=f0
      addspec,w1,f1,w,f,eps,w0,f0
      time=time+h(5)
      endif
   endfor
!p.position=[.2,.2+yh*np,.9,.9]
;set_viewport,.2,.9,.2+yh*np,.9
!p.title=mt
plot,w0,f0
h(5)=time
if (!d.name eq 'X') or (!d.name eq 'TEK') then begin
      ldat,icurdata+dfile
      z=''
      endif else z=', -1 for next record'
   print,' save sum? enter record number',z
   read,ir
   if ir ge -1 then kdat,icurdata+dfile,h,w0,f0,e,ir
   endif
lplt
!xticks=0
!yticks=0
!p.noeras=0
setxy
if ir eq -9 then stop,'STACK stop:'
return
end
