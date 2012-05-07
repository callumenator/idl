;****************************************************************************
pro mkmean,file,recs,mw,mf,me,data,helpme=helpme,stp=stp,xcor=xcor, $
    plt=plt,lc=lc,save=save,title=title
if n_params(0) lt 4 then helpme=1
if not ifstring(file) then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* MKMEAN - get mean of multiple spectra
   print,'*    calling sequence: mkmean,file,recs,w,f
   print,'*       FILE: name of data file'
   print,'*       RECS: record numbers added, -1 for all'
   print,'*       W,F: output mean spectrum'
   print,'*'
   print,'*   KEYWORDS:'
   print,'*      LC: wavelength range to correlate'
   print,'*      PLT: set to plot data'
   print,'*      XCOR: set to cross-correlate'
   print,' '
   return
   endif
;

if strlen(get_ext(file)) eq 0 then ext='.icd' else ext=''
if not ffile(file+ext) then begin
   icd=getenv('icurdata')
   if ffile(icd+file+ext) then file=icd+file else begin
      print,' file ',file,' not found'
      return
      endelse
   endif
S=n_elements(RECS)
IF S EQ 1 THEN BEGIN   ;1 ENTRY
   T=RECS
   RECS=INTARR(1)+T
   ENDIF
if recs(0) Le -1 then recs=indgen(999)
N=N_ELEMENTS(RECS)
PRINT,N,' RECORDS TO BE MEASURED'
GDAT,file,mH,mW,mF,mE,recs(0)
np=n_elements(mw)
data=fltarr(np,n)
data(0)=mf
mf0=mf
dw=mw(1)-mw(0)
time=mh(5)
case mh(33) of
   30: begin 
      k0=where(me eq 0,nk)
      if nk gt 0 then begin
         me(k0)=1.
         eb0=mf/me
         for ik=0,nk-1 do eb0(k0)=(eb0((k0-1)>0)+eb0(k0+1))/2.
         endif else eb0=mf/me 
       end
   40: eb0=me
   else: eb0=1
   endcase
eb0=eb0*eb0
me=me*me
if keyword_set(plt) then plot,mw,mf
if n_elements(lc) eq 2 then begin
  index=fix(xindex(mw,lc)+0.5)
  k=index(0)+indgen(index(1)-index(0)+1)
  print,index,n_elements(k)
  endif else k=indgen(n_elements(mw))
FOR I=1,N-1 DO BEGIN
   GDAT,file,H,W,F,E,recs(i)
   IF N_ELEMENTS(H) LT 2 THEN GOTO,DONE
   time=time+h(5)
   nw=n_elements(w)
   dnf=n_elements(f)-nw
   dne=n_elements(e)-nw
   if nw ne n_elements(f) then begin
      print,' ERROR: W,F different lengths'
      help,w
      help,f
      stop
      endif
   if nw ne n_elements(e) then begin
      print,' ERROR: W,E different lengths'
      help,w
      help,e
      stop
      endif
   if dnf gt 0 then f=f(0:n_elements(f)-dnf)
   if dne gt 0 then e=e(0:n_elements(e)-dne)
   if dnf lt 0 then w=w(0:nw-1+dnf)
   if dne lt 0 then w=w(0:nw-1+dnf)
;
   case h(33) of
      30: begin 
         k0=where(e eq 0,nk)
         if nk gt 0 then begin
         e(k0)=1.
         eb=f/e
         for ik=0,nk-1 do eb(k0)=(eb((k0-1)>0)+eb(k0+1))/2.
         endif else eb=f/e 
         end
      40: 
      else: eb=1
      endcase
   f=interpol(f,w,mw)     ; f on mw scale
   eb=interpol(eb,w,mw)     ; e on mw scale
   if keyword_set(xcor) then begin
      crosscor,mw(k),mf(k),mw(k),f(k),dw,xc,1,cut,m    ;m(1)=shift
      m0=m(1)
      dww=m0*dw
      print,m0,dww
      w1=mw-dww
      f=interpol(f,w1,mw)
      eb=interpol(eb,w1,mw)
      endif 
   mf=mf+f
   eb0=eb0+eb*eb
   data(i*np)=f
;
   if keyword_set(plt) then begin
      oplot,mw,f
      if !d.name eq 'X' then wshow
      endif
;if keyword_set(stp) then stop,'MKMEAN>>>'
   done:
   endfor
mf=mf/n 
me=sqrt(eb0)/n
if mh(33) eq 30 then me=mf/me
if n_elements(save) gt 0 then begin
   mh(5)=time
   zn=' mean of '+strtrim(n,2)+' spectra'
   if n_elements(title) gt 0 then zn=zn+' '+title
   title=string(byte(mh(100:160)))+zn
   mh(100)=fix(byte(title))
   kdat,file,mh,mw,mf,me,-1
   endif
if keyword_set(plt) then begin
   gc,13 & oplot,mw,mf,color=2
   endif
if keyword_set(stp) then stop,'MKMEAN>>>'
return
end
;
