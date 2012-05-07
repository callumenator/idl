;***********************************************************************
PRO SKYBAL,file,records,skyrec=skyrec,skyfile=skyfile, $
    stp=stp,helpme=helpme,autosave=autosave,wavelengths=wavelengths
common comxy,xcur,ycur,zerr,rsc,lu3
if not ifstring(file) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* SKYBAL '
   print,'* calling sequence: SKYBAL,file,records '
   print,'* set record=-N to start with record N'
   print,'* '
   print,'* KEYWORDS:'
   print,'*    SKYREC: record containing mean sky spectrum'
   print,'*    SKYFILE: file containing sky spectrum, def=FILE'
   print,'*    AUTOSAVE: if not set, prompt whether or not to save spectrum'
   print,'*    WAVELENGTHS: plot limits; def=[6550,6600]'
   print,' '
   return
   endif
;
nrec=get_nspec(file)-1
if n_elements(records) eq 0 then records=indgen(nrec)
if records(0) lt 0 then records=-records(0)+indgen(nrec+records(0))
if n_elements(records) eq 1 then records=records(0)
nrec=n_elements(records)
if n_elements(skyrec) eq 0 then read,skyrec,prompt=' enter sky record number: '
if n_elements(skyfile) eq 0 then skyfile=file
gdat,file,hs,ws,fs,es,skyrec
;
if n_elements(wavelengths) lt 2 then wavelengths=[6550.,6600.]
l1=wavelengths(0)
l2=wavelengths(1)
linec=6584.3
setxy,l1,l2,0,0
gc,13
;
; autofit sky
b=fix(xindex(ws,[6579.,6582.,6587.,6600.])+0.5)
plot,ws,fs,title='Sky'
if !d.name eq 'X' then wshow
for i=0,3 do oplot,[ws(b(i)),ws(b(i))],!y.crange,color=3
bk=mean([fs(b(0):b(1)),fs(b(2):b(3))])
;print,bk
oplot,!x.crange,[bk,bk],color=1
a=fltarr(6)
a(0)=max(fs(b(1):b(2)))
a(1)=linec
a(2)=1.
a(3)=bk
fs1=fs(b(0):b(3)) & ws1=ws(b(0):b(3))
y=gaussfit(ws1,fs1,a)
;print,a
oplot,ws1,y,color=8
xc=fix(xindex(ws1,a(1))+0.5)
fnets=total(y(xc-3:xc+3)-bk)
print,' Net sky flux in line:',fnets
wait,2.     ;stop
;
xcur=(l2+l1)/2. 
b=fix(xindex(ws,[6579.,6582.,6587.,6592.])+0.5)
ix=fix(xindex(ws,!x.crange)+0.5)
for irec=0,nrec-1 do begin
   gdat,file,h,w,f,e,records(irec)
   title=strtrim(byte(h(100:160)),2)
   scale=float(h(55))/1000.
   if scale le 0. then scale=1.
   if scale ne 1.0 then print,' Scale=',scale
   f0=f+fs*scale             ;original spectrum
   plot,w,f0,title=title, $
         yrange=[0.9*min(f(ix(0):ix(1))),1.05*max(f0(b(0):b(3)))]
   ycur=mean(f)
   oplot,ws,fs,color=3
   oplot,w,f,color=2
   if !d.name eq 'X' then wshow
;
; autofit
;
   for i=0,3 do oplot,[ws(b(i)),ws(b(i))],!y.crange,color=3,linestyle=1
   bk=mean([f0(b(0):b(1)),f0(b(2):b(3))])   ; & print,bk
   oplot,!x.crange,[bk,bk],color=1,linestyle=2
   a=fltarr(6)
   a(0)=max(f0(b(1):b(2)))
   a(1)=linec
   a(2)=0.8
   a(3)=bk
   f1=smooth(f0,5)
   f1=f1(b(0):b(3)) & w1=w(b(0):b(3))
   xc0=fix(xindex(w1,a(1))+0.5)
   npf=n_elements(f1)-1
   y=gaussfit(w1,f1,a)
   print,a(0:2)
   oplot,w1,y,color=8
   xc=fix(xindex(w1,a(1))+0.5)
   fneta=total(y((xc-3)>0:(xc+3)<npf)-bk)
   fnetm=total(f1((xc0-3)>0:(xc0+3)<npf)-bk)
   fnet=fneta
   if (abs(a(1)-linec) gt 1.) or (abs((fnetm-fneta)/fnet) gt 0.1)  then begin
      bell,3
      print,' WARNING: line may not have been fit'
      if abs(a(1)-linec) gt 1. then print,' Wavelength inconsistency'
      if abs((fnetm-fneta)/fnet) gt 0.1 then print,' Total count inconsistency'
      print,' Resetting counts to sum at expected line'
      print,' check and redo with manual option, if appropriate'
      fnet=fnetm
      endif
   print,' Fnet:',fnet,'   ',fneta,fnetm
;
   rat=fnet/fnets
   print,' Estimated ratio (mean sky/ sky in spectrum)= ',rat
   ff=f0-fs*rat
   oplot,w,ff,color=5                ;,title=title
   h(55)=fix(rat*1000.)
;
   stp1:
   ff=float(ff)
   print,' S to save (green trace), M for manual fit, E to enter ratio, other to go on'
   blowup,-1
   case 1 of
      (zerr eq 83) or (zerr eq 115): $
             if keyword_set(autosave) then kdat,file,h,w,ff,e,records(i) $
             else begin
                igo=0
                read,igo,prompt=' Save this spectrum? Enter 0: '
                if igo eq 0 then kdat,file,h,w,ff,e,records(irec)
                endelse
      (zerr eq 69) or (zerr eq 101): begin             ;enter ratio
          oplot,w,ff,color=0
          oplot,ws,fs,color=3
          oplot,w,f,color=2
          read,rat,prompt=' Enter desired ratio: '
          ff=f0-fs*rat
          oplot,w,ff,color=5                ;,title=title
          h(55)=fix(rat*1000.)
          goto,stp1
          end
      (zerr eq 77) or (zerr eq 109): begin             ;manual fit
          print,' mark line in target+sky'
          oplot,w,ff,color=0
          blowup,-1
          ifeat,w,f0,0,ftot,fnet,/noprint
          rat=fnet/fnets
          print,' Estimated ratio = ',rat
          ff=f0-fs*rat
          oplot,w,ff,color=5                ;,title=title
          h(55)=fix(rat*1000.)
          goto,stp1
          end
      (zerr eq 26) or (zerr eq 81) or (zerr eq 113): goto,finish
      (zerr eq 90) or (zerr eq 122): begin
                stop
                goto,stp1
                end
      else:
      endcase
   endfor
;
finish:
return
end
