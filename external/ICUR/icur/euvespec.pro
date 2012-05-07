;****************************************************************************
pro euvespec,lam,d,icd=icd,helpme=helpme,stp=stp,sw=sw,mw=mw,lw=lw, $
    allspec=allspec,title=title,file=file
if keyword_set(helpme) then begin
   print,' '
   print,'* EUVESPEC - transform EUVE *_SPEC.FITS files into .ICD format'
   print,'* calling sequence: EUVESPEC,W,F'
   print,'*    W,F: output wavelength, flux vectors'
   print,'* '
   print,'* KEYWORDS'
   print,'*    ALLSPEC:'
   print,'*    FILE:'
   print,'*    SW, MW, LW:'
   print,'*    ICD:'
   print,'*    TITLE:'
   print,' '
   return
   endif
if n_elements(root) eq 0 then root=''
if (not keyword_set(sw)) and (not keyword_set(mw)) and (not keyword_set(lw)) $
   then allspec=1
if ifstring(file) then allspec=0
if not keyword_set(sw) then sw=0
if not keyword_set(mw) then mw=0
if not keyword_set(lw) then lw=0
if keyword_set(icd) then begin
;   allspec=1
   if not ifstring(icd) then icdfile='euve' else icdfile=icd
   endif
if not keyword_set(title) then title=''
if keyword_set(allspec) then begin
   sw=1 & mw=1 & lw=1
   endif
nspec=fix(total((sw<1)+(mw<1)+(lw<1)))
if n_elements(file) gt 0 then nspec=1
;
for i=0,nspec-1 do begin
   case 1 of
      ifstring(file):
      keyword_set(sw): begin
         file='sw_spec'
         sw=0
         end
      keyword_set(mw): begin
         file='mw_spec'
         mw=0
         end
      keyword_set(lw): begin
         file='lw_spec'
         lw=0
         end
      else: begin
         print,' ERROR'
         stop
         return
         end
      endcase
   print,' Reading ',file+'.fits'
   dd=readfits(file+'.fits',h)
   d=dd(*,0,0)
   nax=getval('naxis',h)
   case 1 of
      nax eq 3: begin                        ;APEXTRACT
         nax3=getval('naxis3',h)
         t=getval('wat2_001',h)
         k=strpos(t,'"')
         t=strmid(t,k+1,80)
         i1=0 & i2=0 & i3=0 & w0=0. & dw=0.
         reads,t,i1,i2,i3,w0,dw
         case 1 of
            nax3 eq 4: begin                ;variance weighting
               sn=dd(*,0,3)
               e=abs(d/sn)
               end
            nax3 eq 2: begin                ;normal extraction
               b=dd(*,0,1)
               e=sqrt((b+d)*(b+d)+b*b)
               end
            else: begin
               print,' NAXIS2=',nax3,' is invalid'
               return
               end
            endcase
         end
      else: begin
         w0=float(strtrim(getval(h,'crval1'),2))
         dw=float(strtrim(getval(h,'cdelt1'),2))
         e=dd(*,0,1)
         end
      endcase
   nl=fix(strtrim(getval(h,'naxis1'),2))
   lam=w0+findgen(nl)*dw
   expt=float(getval(h,'exptime'))
   if keyword_set(icd) then begin
      head=intarr(400)
      date=getval(h,'date',/noap)
      head(10)=fix(strmid(date,3,2))
      head(11)=fix(strmid(date,0,2))
      head(12)=fix(strmid(date,6,2))
      head(3)=80                            ;EUVE type
      head(5)=-fix(expt/60.)                ;exp time in minutes
      head(19)=10000   
      head(20)=fix(w0) & head(21)=fix(head(19)*(w0-fix(w0)))
      head(22)=fix(dw) & head(23)=fix(head(19)*(dw-fix(dw)))
      head(199)=333
      k=strpos(file,']',0)
      if k gt 0 then sf=strmid(file,k+1,32) else sf=file
      kdat,icdfile,head,lam,d,e,-1,title=title+' '+sf,/islin
      endif
   endfor
;
if keyword_set(stp) then stop,'EUVESPEC>>>'
return
end
