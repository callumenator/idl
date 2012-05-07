;****************************************************************
pro irdefplt,wave,flux,xn,yn,flag,igo   ;default plot if flag=0,-1
COMMON VARS,VAR1,VAR2,VAR3
common icurunits,xunits,yunits,title,c1,c2,c3,ch
common tvcoltab,rr,gg,bb,opcol,ctnum
case 1 of
   !d.NAME EQ 'PS': col=0
   !d.NAME NE 'X': col=!p.color
   n_elements(ctnum) eq 0: col=!p.color
   ctnum eq 11: col=15
   ctnum eq 13: col=1
   else: col=!p.color
   endcase
nocap=rdbit(var3,4)
if nocap then begin
   ptt='' & pst=''
   endif else begin
   ptt=!p.title & pst=!p.subtitle
   endelse
if strlen(ptt) eq 0 then if n_elements(title) gt 0 then ptt=title
if !d.NAME NE 'X' then scale=10. else scale=1.
!c=-1
PLOT,WAVE,FLUX,PSYM=10,title=ptt,subtitle=pst
;stop,'IRDEFPLT>>>'
IF FLAG EQ 0 THEN RETURN
if igo eq 4 then ocomps,xn,yn
OPLOT,XN,YN,PSYM=0,COLOR=COL
if not nocap then opdate,'ICFIT'
return
END
