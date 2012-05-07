;***********************************************
pro cleanspec,file,rec,helpme=helpme,stp=stp,autosave=autosave
common comxy,xcur,ycur,zerr
common com1,H,IK,IFT,NSM,C,NDAT,ifsm,kblo,h2,ipdv,ihcdev
if keyword_set(helpme) then begin
   print,' '
   print,'* CLEANSPEC - clean bad pixels in .ICD files'
   print,'*    calling sequence: CLEANSPEC,file,rec'
   print,'*       FILE: name of .ICD file'
   print,'*       REC:  record to clean, default=all'
   print,'* '
   print,'*    KEYWORDS:'
   print,'*       AUTOSAVE: automatically save cleaned spectrum; inquire if not set'
   print,'* '
   print,' '
   return
   endif
;
if n_elements(rec) eq 0 then rec=-999
if rec(0) eq -999 then begin
   icdfile,file,rec
   rec=indgen(rec+1)
   endif
nrec=n_elements(rec)
p0=!p.psym
gc,11
setxy
for irec=0,nrec-1 do begin
   gdat,file,h,w,f,e,rec(irec)
   if (n_elements(h) lt 2) and (h(0) eq -1) then return
   !p.title=get_title(h)
   etype=h(33)
   plot,w,f,/ynoz
   if !d.name eq 'X' then wshow
   zerr=1
   change=0
   while zerr eq 1 do begin          ;do a spectrum
      print,' click left button on bad point, right to quit'
      cursor,xcur,ycur
      zerr=!err
      if zerr eq 1 then begin
         change=1
         !p.psym=10
         locate,-1,w,f,nbins=25
         print,' mark left and right points to interpolate between'
         cursor,xl,y,wait=3
         print,' mark other point'
         wait,0.2
         cursor,xr,y,wait=3
         i1=fix(xindex(w,xl)+0.5)
         i2=fix(xindex(w,xr)+0.5)
         IF I2 LT I1 THEN BEGIN
            T=I1 & I1=I2 & I2=T
            T=Xl & Xl=Xr & xr=t
            ENDIF
         nb=i2-i1
print,i1,i2
         if nb gt 0 then begin
            SL=(F(I2)-F(I1))/FLOAT(NB)
            FOR I=I1+1,I2-1 DO F(I)=F(I1)+SL*FLOAT(I-I1)
            case 1 of
               etype eq 0:
               etype eq 1:
               etype eq 10: FOR I=I1+1,I2-1 DO e(I)=0
               etype eq 20: FOR I=I1+1,I2-1 DO e(I)=-200
               etype eq 30: FOR I=I1+1,I2-1 DO e(I)=-e(I1)+SL*FLOAT(I-I1)
               else:
               endcase
            endif
         oplot,w,f,color=15
         wait,1. & setxy & plot,w,f,/ynoz
         endif else zerr=0       ; interpolate one line
      endwhile        ; do a spectrum
;   setxy
;   plot,w,f
   if (change) then begin
      if keyword_set(autosave) then igo='0' else begin
         igo=''
         read,' OK? enter 0 to save, anything else to go on: ',igo
         endelse
      if strtrim(igo,2) eq '0' then kdat,file,h,w,f,e,rec(irec)
      endif
   endfor

!p.psym=p0
if keyword_set(stp) then stop,'CLEANSPEC>>>'
return
end
