;*****************************************************************************
PRO EWLIM,file,w1,w2,iprt=iprt,iint=iint
common comxy,xcur,ycur,zerr
;
if string(file) eq '-1' then begin
   print,'*'
   print,'* EWLIM - estimate minimun detectable equivalent widths'
   print,'*    calling sequence: EWLIM,file,w1,w2,iprt=iprt,iint=iint'
   print,'*      file : name of data file'
   print,'*      w1,w2: wavelength region for S/N determination (IINT not set)'
   print,'*      IPRT : set to print .LST file when done'
   print,'*      IINT : set for interactive processing'
   return
   endif
;
;
if n_params(0) eq 0 then read,' enter name of data file',file
if (n_params(0) lt 3) and (not keyword_set(iint)) then $
   read,' enter wavelengths of continuum region',w1,w2
siglim=3.
;
if keyword_set(iint) then begin
   read,' enter record number: ',irec 
   irec=fix(irec)
   i0=irec & i1=irec
   endif else begin
   openw,lu,'ewlim.lst',/get_lun
   printf,lu,' EWLIM output, run at ',systime(0)
   printf,lu,' data file=',file
   wlim=[w1<w2,w1>w2]
   printf,lu,' wavelengths region = ',wlim
   printf,lu,' ' 
   i0=0 & i1=999
   endelse
;
for i=i0,i1 do begin
print,i,i0,i1
   gdat,file,h,w,f,e,i
   if n_elements(h) lt 3 then goto,done
   dw=w(1)-w(0)
   title=strtrim(byte(h(100:160)>32),2)
   f1=optfilt(f,e)
   ff=f/f1
   if keyword_set(iint) then begin
      plot,w,ff
      print,' use X command to reset limits, other to mark region'
      blowup,-1
      if (zerr eq 88) or (zerr eq 120) then begin
          x1=xcur
          blowup,-1
          x2=xcur
          !x.range=[x1<x2,x1>x2]
          plot,w,ff
          print,' Now mark region'
          blowup,-1
          endif
      w1=xcur
      blowup,-1
      w2=xcur
      wlim=[w1,w2]
      endif 
   ii=fix(xindex(w,wlim)+0.5)              ;tabinv,w,wlim,ii
   np=1+ii(1)-ii(0)
   tf=total(ff(ii(0):ii(1)))/float(np)
   tk=(ff-tf)*(ff-tf)
   tk=total(tk(ii(0):ii(1)))/float(np-1)
   rms=sqrt(tk)
   sn=abs(tf/rms)
   minew=siglim/sn*3.*dw
   minew=fix(minew*1000.+0.5)
   si=string(i,format='(I3)')
   if not keyword_set(iint) then $
      printf,lu,'Record ',si,': min EW detectable (mA)=',minew,' Obj=',title
   print,'Record ',si,': min EW detectable (mA)=',minew,' Obj=',title
   endfor
done:
close,lu
free_lun,lu
if not keyword_set(iint) then begin
   if keyword_set(iprt) then spawn_print,'ewlim.lst' else $
      print,' output in EWLIM.LST'
   endif
return
end
