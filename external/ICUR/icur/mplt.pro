;***********************************************************************
PRO MPLT,infile,fsm,helpme=helpme,stp=stp,nxtb=nxtb,nxtr=nxtr,ynzb=ynzb, $
         ynzr=ynzr,summary=summary,wrange=wrange,title=title,queue=queue, $
         start=start,noplot=noplot,debug=debug,page=page,screen=screen, $
         ymax=ymax,yminr=yminr,yminb=yminb,docaps=docaps
;PROCEDURE TO PLOT 8 PLOTS PER PAGE
;
if n_params(0) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* MPLT - make 8 plots per page from ICUR spectra'
   print,'*    calling sequence: MPLT,input,fsm'
   print,'*      INPUT: input .INP text file containing setup information'
   print,'*             line 1: number of data files referenced (N)'
   print,'*             lines 2 - 2+N-1: names of N data files referenced'
   print,'*             line 2+N: 6 xl1,xh1,xsty,xl2,xh2, ysty -- plot limits'
   print,'*             line 2+N+1 ... : 2 lines per star. Line 1 has pairs of'
   print,'*                              (ICUR record number/file reference)'
   print,'*                              followed by string ID.'
   print,'*        FSM: positive for FFT smoothing, units of HPP/Nyq freq.'
   print,'*'
   print,'*    KEYWORDS'
   print,'*        NXTR,NXTB: number of X ticks'
   print,'*        YNZR,YNZB: set /ynozero on plot?'
   print,'*        SUMMARY: do summary plot of full .ICD file'
   print,'*        QUEUE:   queue to send hard copy plots to'
   print,' '
   return
   endif
;
ymx0=1.0
psfile=''
icurdata=getenv('icurdata')
pdev=!d.name
if n_params(0) lt 2 then fsm=-1
if ((fsm le 0.) or (fsm gt 5.)) then fsm=-1
if not keyword_set(ynzb) then ynb=0 else ynb=1
if not keyword_set(ynzr) then ynr=0 else ynr=1
qt=!quiet
za=''
type=0    ;normal
case 1 of
   ffile(infile+'.inp') eq 1 and keyword_set(summary): begin
      ppr=4 & auto=0
      type=1
      useinput=1
      end
   keyword_set(summary): begin
      useinput=0
      ppr=8 & auto=1
      if keyword_set(screen) then auto=0 else auto=1
      ficd=infile+'.icd'
      if not ffile(ficd) then ficd=icurdata+ficd
      if not ffile(ficd) then begin
         bell
         print,'file ',ficd,' was not found.  Returning'
         return
         endif
      stars=1
      !QUIET=3
      ldat,ficd,heads=stars
      ngood=n_elements(stars)
      if (ngood eq 1) and not ifstring(stars(0)) then ngood=-1
      if ngood le 0 then begin
         print,' no records used'
         return
         endif
      xsty=1 & ysty=1
      if n_elements(wrange) ge 2 then begin
         xlim=[wrange,wrange] 
         za='w'
         endif else begin
         xlim=[0.,0.,0.,0.]
         za=''
         endelse
      rec=indgen(ngood)
      icurfiles=ficd
      n=ngood-1
      file=replicate(0,8) 
      end
   else: begin
      ppr=4 & auto=0
      useinput=1
      end
   endcase
;
if useinput then begin
   if not ffile(infile+'.inp') then begin
      bell
      print,'file ',input,'.inp was not found.  Returning'
      return
      endif
   openr,lu,infile+'.inp',/get_lun
   nf=0
   readf,lu,nf
   if nf le 0 then begin
      print,' number of input files=',nf,'. This is incorrect!'
      return
      endif
   icurfiles=strarr(nf)
   z=''
   readf,lu,z
   icurfiles(0)=z
   if nf gt 1 then for i=1,nf-1 do begin
      readf,lu,z
      icurfiles(i)=z
      endfor
   print,icurfiles
   xlim=fltarr(5)
   readf,lu,xlim
   xsty=fix(xlim(2))
   xlim=[xlim(0:1),xlim(3:4)]
   readf,lu,rec1,file1,rec2,file2
   readf,lu,z
   rec=[rec1,rec2]
   file=[file1,file2]
   stars=z
   n=0
   while not eof(lu) do begin
      n=n+1
      readf,lu,rec1,file1,rec2,file2
      readf,lu,z
      rec=[rec,rec1,rec2]
      file=[file,file1,file2]
      stars=[stars,z]
      endwhile
   ngood=n+1
   close,lu & free_lun,lu
   file=fix(file)
   endif
;
if useinput eq 1 then file=[file,-999+intarr(8)]
rec=fix(rec)
rec=[rec,-999+intarr(8)]
nr=n_elements(rec)
if (nr mod 2) eq 1 then begin
   rec=[rec,-999] & nr=nr+1
   endif
na=nr/2
recs=intarr(2,na) & recs(0)=fix(rec)
files=intarr(2,na) & files(0)=fix(file)
;
yzt=ytit(0)
xzt='!6Angstroms'
if keyword_set(nxtb) then xtb=nxtb else XTB=0
if keyword_set(nxtr) then xtr=nxtr else XTr=0
IQMS=0  ;plot to terminal
DX=0.00   ;1  ;X distance between plots
PC=.50   ;PLOT CENTER
PR=0.40  ;PLOT RANGE     ;.1-.9
y0=.15
z=''
npg=(ngood-1)/ppr+1
NVERT=4   ;4 PLOTS VERTICALLY
if npg eq 1 then begin
   nt=recs(0,*) & nt=nt(where(nt ge 0))
   if n_elements(nt) lt 4 then nvert=n_elements(nt)
   endif
dy=(pr*2.-dx*(nvert-1.))/float(nvert)
;
autopage=0
if n_elements(start) gt 0 then autopage=start
if n_elements(page) gt 0 then autopage=page-1
;
if n_elements(ymax) eq 1 then noyscale=1 else noyscale=0
if n_elements(ymax) eq 0 then ymax=1.2
if n_elements(yminb) eq 0 then yminb=0.
if n_elements(yminr) eq 0 then yminr=0.
;
;****************************************************************
newpage:
if not auto then begin
   if npg eq 1 then begin
      z1='is' & z2=' '
      endif else begin
      z1='are' & z2='s'
      endelse
   print,' there ',z1,npg,' page',z2
   if npg gt 1 then begin
      read,' enter page, -1 to end: ',ipage
      if ipage eq -9 then stop
      if ipage lt 0 then goto,done
      if ipage*4 gt n then begin
         print,'gone too far, ipage,n=',ipage,n
         goto,done
         endif 
      endif else ipage=0
   endif else ipage=autopage
;
brec=recs(0,4*ipage:(4*(ipage+1)-1)<(ngood-1))
rrec=recs(1,4*ipage:(4*(ipage+1)-1)<(ngood-1))
bfile=files(0,4*ipage:(4*(ipage+1)-1)<(ngood-1))
rfile=files(1,4*ipage:(4*(ipage+1)-1)<(ngood-1))
nstar=stars(ppr*ipage:(ppr*(ipage+1)-1)<(ngood-1))
; PLOT LHS   ;************************************
NEWPLOT:
!y.style=1
docap=intarr(4)
if useinput eq 0 then begin
   if keyword_set(debug) then summary=3
   case 1 of
      keyword_set(screen): sp,pdev
      summary ne 1: sp,pdev 
      else: sp,'ps' 
      endcase
   endif else begin
   if iqms then sp,'ps' else SP,pdev
   endelse
!QUIET=3
!X.TITLE=''
!Y.TITLE=''
!p.TITLE=''
!p.PSYM=0
xl=xlim
SETXY,xl(0),xl(1),yminb,ymax
tv=[' ',' ',' ',' ',' ',' ',' ']
if not keyword_set(ynb) then ytv=[0.,.5,1.] else ytv=[0.,.2,.4,.6,.8,1.]
nyt=n_elements(ytv)-1
!X.TICKS=XTB
ilow=where(brec ge 0) & ilow=ilow(0)
if (!d.name eq 'X') and (!d.window gt -1) then wshow
nh=n_elements(brec)
xtickn=strarr(30)+' '
if !x.ticks ne 0 then minticks=!x.ticks else minticks=4
pno=ipage*8
FOR ii=0,nh-1 DO BEGIN             ;0-4
   i=nh-1-ii
   pno=ipage*8+i*2
   if useinput eq 0 then j=i*2 else j=i
   YH=y0+dy*Ii
   !p.position=[PC-PR-DX,yh,PC-DX,YH+dy]
;   SET_VIEWPORT,PC-PR-DX,PC-DX,YH,YH+dy
   if ii eq 0 then begin              ;annotate axis
     xax0=xl(0) & xax1=xl(1)
     if xax0 eq xax1 then begin     ;determine X axis
         it=brec(i)
         iit=i
         while (it eq -999) and (iit lt nh-1) do begin
            iit=iit+1
            it=brec(iit)
            endwhile
         if it NE -999 then BEGIN 
   if useinput eq 0 then zf=ficd else zf=strtrim(icurfiles(bfile(iit)),2)
            GDAT,zf,H,W,F,E,it
            ztit=strtrim(byte(h(100:160)),2)
            xax0=min(w) & xax1=max(w)
            xl(0)=xax0 & xl(1)=xax1
            endif else begin            ;no data read - fudge it
            kk=where(brec ge 0,ngk)
            if ngk gt 0 then begin
               if useinput eq 0 then zf=ficd else $
                  zf=strtrim(icurfiles(bfile(kk(0))),2)
               GDAT,zf,H,W,F,E,brec(kk(0))
               ztit=strtrim(byte(h(100:160)),2)
               xax0=min(w) & xax1=max(w)
               xl(0)=xax0 & xl(1)=xax1
               endif
            endelse
         endif
      plot,[xax0,xax1],[yminb,ymax],/nodata,ystyle=5,xtitle='',xstyle=5
      xrange=!x.crange(1)-!x.crange(0)
      nfig=fix(alog10(xrange/minticks)) & f10=10^nfig
      if !x.ticks gt 0 then delta=xrange/!x.ticks else $
         delta=float(fix(xrange/minticks/f10))*f10
      n_xt=fix(xrange/delta)
      if delta ge 10. then xfmt='(I6)' else xfmt='(F6.1)'
;      delta=xrange/minticks
      delta=xrange/n_xt
      for ix=0,n_xt-1 do xtickn(ix)=string(!x.crange(0)+ix*delta,xfmt)
      xtickn(n_xt)=' '
      print,n_xt,delta,xtickn
      if xrange gt 0. then $
        axis,xaxis=0,xtitle='',charsize=1.0,xticks=n_xt,xtickname=xtickn,xsty=1
if keyword_set(debug) then stop
      endif
   if BREC(I) NE -999 then BEGIN                   ;data exists
      if useinput eq 0 then zf=ficd else zf=strtrim(icurfiles(bfile(i)),2)
      GDAT,zf,H,W,F,E,BREC(I)
      ztit=strtrim(byte(h(100:159)),2)
      print,zf,brec(i),' ',ztit
      nsm=fsm
      if fsm ne -1 then fftsm,f,1,nsm
      if xl(0) eq xl(1) then begin
         k=indgen(n_elements(f)) & nk=n_elements(k)
         endif else K=WHERE((W GE xl(0)) AND (W LE xl(1)),nk)
      fmin=min(f(k))
      if nk gt 0 then FMAX=MAX(F(K))*ymx0 else fmax=max(f)*ymx0
      if noyscale then fmax=1.
      F=F/FMAX  ;SCALE 0-1
      if ynb then setxy,xl(0),xl(1),(fmin/fmax)<0.8,ymax else $
         setxy,xl(0),xl(1),yminb,ymax
      PLOT,W,F,/noerase,yticks=1,xtickname=tv,xtitle='', $
         xsty=xsty,ysty=4+!y.style,charsize=1.0,xticks=n_xt
      axis,yaxis=0,yticks=nyt,ytickn=tv,ynoz=ynb,ytitle='',ytickv=ytv
      axis,yaxis=1,yticks=nyt,ytickn=tv,ynoz=ynb,ytitle='',ytickv=ytv
      x1=!x.crange(0)+.01*(!x.crange(1)-!x.crange(0))
      y1=!y.crange(1)-.08*(!y.crange(1)-!y.crange(0))
      if useinput eq 0  then spno=string(pno,'(I3)')+' ' else spno=''
      case 1 of
         type eq 1:
         strlen(strtrim(nstar(j),2)) eq 0: 
         strmid(nstar(j),0,1) eq '-':
         else: ztit=spno+STRTRIM(nstar(j),2)
         endcase
      xyouts,x1,y1,ztit,charsize=1.
      docap(ii)=1
;      if type eq 1 then xyouts,x1,y1,ztit,charsize=1. else $
;         xyouts,x1,y1,spno+STRTRIM(nstar(j),2),charsize=1.
      ENDif
   ENDFOR
if keyword_set(debug) then stop
;
t0=''
if auto then begin
   if n_elements(title) ne 0 then t0=title else t0=infile
   t0=t0+' Page '+string(ipage+1,'(I2)')+' of '+string(npg,'(I2)')
   endif else if n_elements(title) ne 0 then t0=title
if t0 ne '' then begin
   sz=2.0
   tl=strlen(t0)*!d.x_ch_size*sz/!d.x_size
   xt0=0.5-tl/2.
   yt0=y0+dy*nh+0.01
   xyouts,xt0,yt0,t0,/norm,size=sz
   endif
;
; PLOT RHS   ;****************************************************
if not keyword_set(ynr) then ytv=[0.,.5,1.] else ytv=[0.,.2,.4,.6,.8,1.]
nyt=n_elements(ytv)-1
SETXY,xl(2),xl(3),yminr,ymax
!X.TICKS=XTR
if keyword_set(docaps) then docap=docap*0
FOR ii=0,nh-1 DO BEGIN  
   i=nh-1-ii
   if useinput eq 0 then j=i*2+1 else j=i
   pno=ipage*8+1+i*2
   YH=y0+dy*Ii
   !p.position=[PC+DX,yh,(PC+DX+PR < .99),YH+dy]
;   SET_VIEWPORT,PC+DX,(PC+DX+PR < .99),YH,YH+dy
   if ii eq 0 then begin
     xax2=xl(2) & xax3=xl(3)
     if xax2 eq xax3 then begin     ;determine X axis
         it=rrec(i)
         iit=i
         while (it eq -999) and (iit lt nh-1) do begin
            iit=iit+1
            it=rrec(iit)
            endwhile
         if it NE -999 then BEGIN 
   if useinput eq 0 then zf=ficd else zf=strtrim(icurfiles(rfile(iit)),2)
            GDAT,zf,H,W,F,E,it
            xax2=min(w) & xax3=max(w)
            xl(2)=xax2 & xl(3)=xax3
            endif else begin            ;no data read - fudge it
            kk=where(rrec ge 0,ngk)
            if ngk gt 0 then begin
               if useinput eq 0 then zf=ficd else $
                  zf=strtrim(icurfiles(rfile(kk(0))),2)
               GDAT,zf,H,W,F,E,rrec(kk(0))
               xax0=min(w) & xax1=max(w)
               xl(0)=xax0 & xl(1)=xax1
               endif
            endelse
         endif
      plot,[xax2,xax3],[yminr,ymax],/noerase,/nodata,ysty=4,xtitle='',xsty=5
      xrange=!x.crange(1)-!x.crange(0)
      nfig=fix(alog10(xrange/minticks)) & f10=10^nfig
      if !x.ticks gt 0 then delta=xrange/!x.ticks else $
         delta=float(fix(xrange/minticks/f10))*f10
      n_xt=fix(xrange/delta)
      if delta ge 10. then xfmt='(I6)' else xfmt='(F6.1)'
      ;delta=xrange/minticks
      delta=xrange/n_xt
      for ix=0,n_xt do xtickn(ix)=string(!x.crange(0)+ix*delta,xfmt)
      print,n_xt,delta,xtickn
      if xrange gt 0. then $
        axis,xaxis=0,xtitle='',charsize=1.0,xticks=n_xt,xtickname=xtickn,xsty=1
      endif
   if RREC(I) NE -999 then BEGIN
      if useinput eq 0 then zf=ficd else zf=strtrim(icurfiles(rfile(i)),2)
      GDAT,zf,H,W,F,E,RREC(I)
      ztit=strtrim(byte(h(100:159)),2)
      nsm=fsm
      if fsm ne -1 then fftsm,f,1,nsm
      if xl(2) eq xl(3) then k=indgen(n_elements(f)) else $
         K=WHERE((W GE xl(2)) AND (W LE xl(3)))
      fmin=min(f(k))
      FMAX=MAX(F(K))*ymx0
      if noyscale then fmax=1.
      F=F/FMAX  ;SCALE 0-1
      if ynr then setxy,xl(2),xl(3),(fmin/fmax)<0.8,ymax
      !C=-1
      PLOT,W,F,/noerase,yticks=1,xtickname=tv,xtitle='', $
         xsty=xsty,ysty=4+!y.style,charsize=1.0,xticks=n_xt
      axis,yaxis=0,yticks=nyt,ytickn=tv,ynoz=ynr,ytitle='',ytickv=ytv
      axis,yaxis=1,yticks=nyt,ytickn=tv,ynoz=ynr,ytitle='',ytickv=ytv
      x1=!x.crange(0)+0.01*(!x.crange(1)-!x.crange(0))
      y1=!y.crange(1)-0.08*(!y.crange(1)-!y.crange(0))
      if useinput eq 0 then spno=string(pno,'(I3)')+' ' else spno=''
      case 1 of
         type eq 1:
         BREC(I) EQ -999: ztit=''
;         useinput eq 0: ztit=''
         strlen(strtrim(nstar(j),2)) eq 0: 
         strmid(nstar(j),0,1) eq '-':
         else: ztit=spno+STRTRIM(nstar(j),2)
         endcase
         if docap(ii) eq 0 then xyouts,x1,y1,ztit,charsize=1
;      if type eq 1 then xyouts,x1,y1,ztit,charsize=1 else $
;         IF (useinput eq 0) or (BREC(I) EQ -999) THEN $
;           xyouts,x1,y1,spno+STRTRIM(nstar(j),2)
      endif
   ENDFOR
; label Y axis
!y.style=0
!p.position=[0,0,.999,.999]
xx=[0,1023] & yy=[0,768]
setxy
plot,xx,yy,/nodata,/noerase,xtitle='',ytitle='',xtickl=1.E-6,ytickl=1.e-6, $
      xstyle=4,ystyle=5
xyouts,50,320,yzt,size=1.5,orient=90.     ; label Y axis
xyouts,512,50,xzt,size=1.5,orient=0.        ; label X axis
;
if auto then begin
   psfile=infile+'_'+strtrim(autopage,2)+za
   lplt,pdev,file=psfile,queue=queue,noplot=noplot
   autopage=autopage+1
   if (autopage lt npg) and (n_elements(page) eq 0) then goto,newpage
   sp,pdev
   endif else begin
   if iqms eq 0 then begin   ;first pass
      psfile=''
      READ,' Redo to laser printer? Enter file name: ',psfile
      if strlen(psfile) gt 0 then iqms=1
      if strupcase(psfile) eq 'Z' then begin
         stop
         iqms=0
         endif
      IF IQMS EQ 1 THEN GOTO,NEWPLOT
      endif else BEGIN   ;send plot to laser printer
      lplt,pdev,file=psfile,queue=queue,noplot=noplot
      endelse
   iqms=0
   if npg gt 1 then goto,newpage
   endelse
done:
if !d.name eq 'PS' then lplt,/noplot
!quiet=qt
setxy
svp
if keyword_set(stp) then stop
END
