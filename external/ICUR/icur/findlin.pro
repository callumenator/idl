;*************************************************************************
PRO FINDLIN,WAVE,disc,LEVEL=LEVEL,noid=noid,noquery=noquery,longid=longid, $
    top=top,STP=STP,helpme=helpme,linfile1=linfile1
; PROCEDURE TO PRINT LINE LIST
COMMON COM1,H,IK,IFT,NSM,C,NDAT,IFSM,KBLO,H1,ipdv,ihcdev
COMMON COMXY,XCUR,YCUR,ZERR,resetscale,lu3
COMMON ICDISK,ICURDISK,ICURDATA,ismdata,objfile,stdfile,idat,recno,linfile
common icurunits,xunits,yunits,title,c1,c2,c3,ch,c4,c5,c6,c7,c8,c9
common radialvelocity,radvel0
common findlin,lf,zlin,orv,vc
;
if keyword_set(helpme) then begin
   print,' '
   print,'* FINDLIN - list lines from .lin file in plotted region'
   print,'* calling sequence: FINDLIN,wave,disc'
   print,'* '
   print,'* KEYWORDS:'
   print,'* LEVEL,noid,noquery,longid,top'
   print,'* '
   print,' '
   endif
;
if n_params(0) lt 1 then begin
   print,' FINDLIN must be called with one parameter - the W vector'
   return
   endif
;
if (wave(0) gt 0.8) and (max(wave) lt 2.5) then mum=1.e4 else mum=1.0
fmto='(F8.3)'
if !d.name eq 'X' then csize=1. else csize=0.7
nrads=n_elements(radvel0)                  ;number of radial velocities passed
if nrads eq 0 then radvel=0. else radvel=radvel0
nrads=n_elements(radvel) 
if n_elements(icurdata) eq 0 then icurdata=''
if n_elements(linfile) eq 0 then linfile='nofile'
if n_elements(level) eq 0 then level=0
l0=level
if n_elements(orv) eq 0 then orv=0.
if n_elements(c2) eq 0 then c2=!p.color<255
if n_elements(c3) eq 0 then c3=!p.color<255
if n_elements(c4) eq 0 then c4=4
if n_elements(c5) eq 0 then c5=5
if n_elements(c6) eq 0 then c6=6
if n_elements(c7) eq 0 then c7=7
if n_elements(c8) eq 0 then c8=1
if n_elements(c9) eq 0 then c9=9
vc=2.99792E5               ;velocity of light
l=n_elements(wave)
ab=(wave(l-1)-wave(0))/float(l-1)  ;angstroms/bin
tol=5.*ab   ;5 channels
Z=' Findlines: 0 for visible region, 1 for line, space for region'
w1=!x.crange(0) & w2=!x.crange(1)
if not keyword_set(noquery) then begin
   PRINT,Z
   opstat,'  Waiting'
   blowup,-1
   opstat,'  Working'
   case zerr of
      48:              ;<0>
      49: begin        ;<1>
         w0=Xcur
         w1=w0-tol & w2=w0+tol
         end
      else: begin    ; anything else
         WA=Xcur
         BLOWUP,-1
         WB=Xcur
         IF WA EQ WB THEN BEGIN
            wa=wa-tol & wb=wb+tol
            ENDIF
         w1=wa<wb & w2=wa>wb
         END
       endcase
   endif
;
range=w2-w1             ;W1,W2 ARE WAVELENGTH RANGES
wmid=range/2.+w1
HM=1.
if n_params(0) lt 2 then begin
   case 1 of
      range le HM: disc='high'
      (range gt HM) and (range le 200): disc='mid'
      else: disc='low'
      endcase
   endif
if n_elements(lf) eq 0 then lf=''
if (strupcase(strmid(lf,0,2)) eq 'H2') and (l0 eq 0) then h2=1 else h2=0
;
for irad=1,nrads do begin                   ;loop through all radial velocities
   radvel=radvel0(irad-1)
   dw=radvel/vc*wmid
;
if keyword_set(linfile1) then linfile=linfiles
case 1 of
   (strupcase(lf) eq strupcase(linfile(0))) and (n_elements(zlin) gt 0) and $
      (radvel(0) eq orv(0)) and (nrads eq 1): ;data exist
   irad gt 1:      ;data exist
   else: begin                ;read new file
      if strupcase(linfile(0)) eq 'NOFILE' then begin
         linefl='uv'
         if max(wave) lt 80. then linefl='xray'
         if wave(0) gt 3120. then linefl='opt'   ;optical data
         if (wave(0) gt 0.8) and (max(wave) lt 2.5) then linefl='ir'  ;IR data
         linefl=icurdata+linefl+'.lin'
         endif else linefl=linfile(0)
      if strlen(get_ext(linefl)) eq 0 then linefl=linefl+'.lin'
      if not ffile(linefl) then begin
         if not ffile(icurdata+linefl) then begin
            print,' File ',linefl,' not found - returning'
            return
            endif else linefl=icurdata+linefl
         endif
      lf=linefl
      if n_elements(lu3) gt 0 then begin
         PRINTF,lu3,'-7' & PRINTF,lu3,W1,W2
         endif
;
      maxlines=9999
      zlin=strarr(maxlines)
      i=0
      z=''
;
      OPENR,LUN,linefl,/get_lun   ; LINES LISTED BY INCREASING WAVELENGTH
      while not eof(lun) do begin    ;read data
         readf,lun,z
         zlin(i)=z
         i=i+1
         endwhile
      close,lun
;
   if n_elements(linfile) gt 1 then begin            ;read second file
      linefl=linfile(1)
      if strlen(get_ext(linefl)) eq 0 then linefl=linefl+'.lin'
      if not ffile(linefl) then begin
         if not ffile(icurdata+linefl) then begin
            print,' File ',linefl,' not found - skipping'
            goto,allreadin
            endif else linefl=icurdata+linefl
         endif
      lf=linefl
      OPENR,LUN,linefl,/get_lun   ; LINES LISTED BY INCREASING WAVELENGTH
      while not eof(lun) do begin    ;read data
         readf,lun,z
         zlin(i)=z
         i=i+1
         endwhile
      endif    ;more than one line file
;
allreadin:
      free_lun,lun
      k=where(strlen(zlin) gt 0,maxlines)
      if maxlines eq 0 then return
      zlin=zlin(k)
      end
   endcase
;
if wave(0) gt 10000. then fmto='(F8.2)'
if radvel ne 0. then begin
   zrad=' FINDLIN: Lines shifted by '+string(radvel,'(F8.2)')+' km/s (~'+ $
       strtrim(string(dw,'(F8.2)'),2)+' Angstroms)'
   print,zrad
   endif
px=9
if strpos(strupcase(lf),'H2') ne -1 then nx=2 else nx=1
maxlines=n_elements(zlin)
wlin=fltarr(maxlines)-1. & wp=intarr(maxlines) & wid=strarr(maxlines)
WLIN=FLOAT(STRMID(zlin,0,px))/mum & wp=fix(strmid(zlin,px,nx))
WID=STRMID(zlin,10+nx,20)
k=where(((wlin+dw) ge w1>!x.crange(0)) and ((wlin+dw) le w2<!x.crange(1)),ng)
;
if ng eq 0 then begin
   print,' FINDLIN: line list ',linfile,' contains no lines in this region '
   goto,irloop
   endif
wlin=wlin(k) & wp=wp(k) & wid=wid(k)
;
case 1 of
   h2 eq 1: begin                  ;H2 molecule
      kb=strmid(wid,3,1)
      b=intarr(ng)
      kp=where(kb eq 'P',nkp)
      kr=where(kb eq 'R')
      offsets=intarr(ng)
      clr=wp*0+c8
      if nkp gt 0 then clr(kp)=c3    ; P branch blue
      k=where(wp eq -1,nk) & if nk gt 0 then clr(k)=-c3
      end
   level ne 0: begin                           ;select by levels
      if level eq -99 then l0=0                ;special case for R0 lines
      if l0 ge 0 then k=where(wp le abs(l0),nk) else $
         k=where(wp eq abs(l0),nk)
      if nk eq 0 then begin
         print,' FINDLIN: line list ' $
            ,linfile,' contains no valid lines in this region '
         return
         endif
      kp=where(wp eq -1,nkp)               ;pumping lines
      if nkp gt 0 then begin
         wlin1=wlin(kp) & wp1=wp(kp) & wid1=wid(kp)
         endif
      wlin=wlin(k) & wp=wp(k) & wid=wid(k)
      if nkp gt 0 then begin
         wlin=[wlin,wlin1] & wp=[wp,wp1] & wid=[wid,wid1]
         endif
;
      clr=wp*0+c2
      if l0 gt 0 then begin
         l0=abs(l0)
         if l0 ge 1 then begin
            k=where(wp le 0,nk) & if nk gt 0 then clr(k)=c3
            endif   
         if l0 ge 2 then begin
            k=where(wp eq 2,nk) & if nk gt 0 then clr(k)=c4
            endif   
         if l0 ge 3 then begin
            k=where(wp eq 3,nk) & if nk gt 0 then clr(k)=c5
            endif   
         if l0 ge 4 then begin
            k=where(wp eq 4,nk) & if nk gt 0 then clr(k)=c6
            endif   
         if l0 ge 5 then begin
            k=where(wp eq 5,nk) & if nk gt 0 then clr(k)=c7
            endif   
         if l0 ge 6 then begin
            k=where(wp eq 6,nk) & if nk gt 0 then clr(k)=c8
            endif   
         if l0 ge 7 then begin
            k=where(wp eq 7,nk) & if nk gt 0 then clr(k)=c9
            endif   
         endif
      k=where(wp lt 0,nk) & if nk gt 0 then clr(k)=-c3
      end                  ;H2 level ne 0
   else: begin
      case 1 of
      disc eq 'high': begin
         k=where(wp eq 0,nk)
         if nk gt 0 then wp(k)=-99
         end
      disc eq 'low': begin
         k=where(wp ge 2,nk)
         if nk gt 0 then wp(k)=-99
         end
     disc eq 'mid':
     disc ne 'high': begin
         k=where(wp eq 3,nk)
         if nk gt 0 then wp(k)=-99
         end
      endcase
   k=where(wp gt -99,nk)
   if nk eq 0 then begin
      print,' FINDLIN: line list ', $
            linfile,' contains no valid lines in this region '
      return
      endif else begin
      wlin=wlin(k) & wp=wp(k) & wid=wid(k)
      endelse
      case irad of
         2: clr=wp*0+c8
         3: clr=wp*0+c3
         4: clr=wp*0+c4
         5: clr=wp*0+c5
         else: clr=wp*0+c2
         endcase
      k=where(wp le 0,nk) & if nk gt 0 then clr(k)=-c3
      end
   endcase
;
nlines=n_elements(wlin)
if nlines le 0 then return
if radvel ne 0. then dellam=WLIN*radvel/2.99792E5 else dellam=0.*wlin
if keyword_set(top) then yoffset=0.88 else yoffset=0.01
xoffset=0.01*(!x.CRANGE(1)-!x.CRANGE(0))
DY=!Y.CRANGE(0)+yoffset*(!Y.CRANGE(1)-!Y.CRANGE(0))
;
dz=1.+radvel/vc
for i=0,nlines-1 do begin
   WL=STRTRIM(STRING(WLIN(i),fmto),2)
   if radvel ne 0. then wl=wl+' --> '+STRTRIM(STRING(WLIN(i)*dz,'(F8.3)'),2)
   z=STRTRIM(WID(i),2)
   if not keyword_set(noid) then XYOUTS,wlin(i)-xoffset+dellam,DY,z, $
      orient=90.,charsize=csize
;   if keyword_set(longid) then Z=WL+' : '+z
   Z=WL+' : '+z
;   if irad eq 1 then begin
      PRINT,Z
      if n_elements(lu3) gt 0 then PRINTF,lu3,Z
;      endif
   if CLR(i) lt 0 then ls=0 else ls=1              ;solid line
   clr1=abs(clr(i))<(!d.n_colors-1)
   if clr(i) eq -9 then clr1=!d.n_colors
   OPLOT,[WLIN(i),WLIN(i)]+dellam(i),!Y.CRANGE,linestyle=ls,COLOR=CLR1
   endfor
irloop:
   endfor    ;irad
;
if keyword_set(stp) then stop,'FINDLIN>>>'     
return
end
