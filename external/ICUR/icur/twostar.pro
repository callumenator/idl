;***************************************************************
pro twostar,sp1,sp2,w1,f,H1,dm=dm,av=av,outfile=outfile,blue=blue,helpme=helpme, $
     file=file,hcpy=hcpy,NOPLOT=NOPLOT,ECH=ECH,shft=shft
COMMON COM1,HD,IK,IFT,NSM,C,NDAT,IFSM,KBLO,H10
;
icurdata=getenv('icurdata')
if n_params(0) eq 1 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'*** TWOSTAR calling sequence'
   print,'* TWOSTAR,sp1,sp2,file,w,f'
   print,'*   sp1: primary spectral type'
   print,'*   sp2: secondary spectral type'
   print,'*  w,f:  optional output wavelength and flux vectors'
   print,'* KEYWORDS:
   print,'*    OUTFILE: optional output file for summed spectrum'
   print,'*         DM:  magnitude difference (+ if sp1 brighter than sp2), def=1.'
   print,'*         AV:  visual extinction (default=0.0)'
   print,'*       BLUE:  blue spectrum, default=red'
   print,'*       FILE:  ICUR data file, default=optstd.icd'
   print,'*        ECH:  echelle data, file=echstd.icd'
   print,'*       SHFT:  wavelength shift to apply to second spectrum'
   print,' '
   return
   endif
if n_params(0) eq 0 then sp1=-1
if n_params(0) le 1 then sp2=-1
if not keyword_set(dm) then dm=1.
if not keyword_set(av) then av=0.0
if not keyword_set(blue) then blue=0
if not keyword_set(file) then fl='optstd' else fl=file
if keyword_set(ech) then fl='echstd'
if not keyword_set(shft) then shft=0.
;
file=fl
if strlen(get_ext(file)) eq 0 then file=file+'.icd'
if not ffile(file) then file=icurdata+file
if not ffile(file) then begin
   print,' File ',file,' not found'
   return
   endif
;
case 1 of
   fl eq 'optstd': begin
indb=[1,1,1,3,8,8,12,16,19,25,25,29,34,37,40,44,50,51,54,56,58,58,61,63,65,67]
         indb=[indb,68+intarr(6)]
      indr=[70,70,70,70,72,72,74,80,82,89,91,95,99,104]
         indr=[indr,107,108,110,111,114,118,120,121,125,125,128,128,131]
         indr=[indr,134,136+intarr(4)]
      if keyword_set(blue) then ind=indb else ind=indr
      end
   fl eq 'echstd': begin
      IND=[0,0,0,0,1,2,3,5,7,8,12,13,15,15,16,17,19,19,20,20,21,21,22,22,23,23]
      IND=[IND,24,25,25]
      end
   fl eq 'tiostd': begin
      IND=[0,0,0,0,1,1,1,5,6,7,8,9,10,10,12,12,14,14,15,15,16,16,17,17,17,18]
      IND=[IND,18,19,20,20]
      end
   fl eq 'optstd2': begin
      IND=[0,0,0,2,3,6,8,9,10,12,13,15,18,18,19,19,21,21,23,23,25,25]
      ind=[ind,26,26,27,27,29,31,31,32]
      end
   fl eq 'echstdl': begin
      IND=[0,0,3,6,10,11,11,15,16,18,20,22,23,23,24,24,25,27,28,29,30]
;23,23,25,25,26,27,28]
;      IND=[IND,29,30,30,32,32,33,34,34,35]
      IND=[IND,31,32,32,34,34,35,36,36,37]
      end
   endcase
;
if sp1 ne -1 then print,' first star is of spectral type ',spectype(sp1) else $
     read,' Enter first spectral type (0-31): ',sp1
if sp2 ne -1 then print,' second star is of spectral type ',spectype(sp2) else $
     read,' Enter second spectral type (0-31): ',sp2
if dm le -90. then read,' enter magnitude difference, + if 1st star brighter: ',DM
frat=10^(dm/2.5)
gdat,file,h1,w1,f1,e1,ind(sp1)
hd=h1
h10=h1
gdat,file,h2,w2,f2,e2,ind(sp2)
hd=h1
w2=w2+shft
initf1,w1,f1,e1,w2,f2,e2,f,e,reset,bw,bf,/noplot
mt='!6'+strtrim(spectype(sp1),2)+'+'+strtrim(spectype(sp2),2)
mt=mt+', A!Dv!N='+string(av,'(F3.1)')
mt=mt+' !7D!6m='+string(dm,'(F5.2)')
z=strtrim(spectype(sp1),2)+'+'+strtrim(spectype(sp2),2)
z=z+' Dmag='+string(dm,'(F5.2)')
h1(100)=BYTE(z)
PRINT,Z
;n=n_elements(w1)
;print,' Flux ratio=',total(f1)/total(f2)
f2=f2/frat
ebmv=-av/3.1
addred,-1,w1,f1,ebmv
addred,-1,w1,f2,ebmv
f=f1+f2
if keyword_set(outfile) then kdat,outfile,hd,w1,f,e,-1
if not keyword_set(noplot) then begin
   !p.title=mt
   plot,w1,f
   oplot,w1,f1
   oplot,w1,f2
   endif
if keyword_set(hcpy) then begin
   dv=!d.name
   !p.title=mt
   sp,'ps'
   plot,w1,f
   oplot,w1,f1
   oplot,w1,f2
   lplt,dv
   endif
return
end
