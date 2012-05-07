;***************************************************************
PRO PLDATA,I0,W,F,BW,BF,pcol=pcol,psdel=psdel,PSM=PSM,bdata=bdata,eps=eps, $
     ebcol=ebcol
;I=-2 : INITIAL PLOT (A)
;I=-1 : CLEAR SCREEN (I)
;I= 0 : NORMAL PLOT  (R)
;I= 1 : OVERPLOT (O)
;i=10 : laser plot
COMMON COM1,H,IK,IFT,NSM,C,NDAT,ifsm,kblo,h2,ipdv,ihcdev
common vars,var1,var2,var3,var4,BDF
COMMON COMXY,XCUR,YCUR,ZERR,RESETSCALE,lu3,ieb
;
if not keyword_set(pcol) then pcol=255                      ;default color
if not keyword_set(psdel) then psdel=0                      ;delete IDL.PS
if n_ELEMENTS(psm) EQ 0 then psm=!P.PSYM                    ;delete symbol
if n_elements(ieb) eq 0 then ieb=0
nocap=rdbit(var3,4)
i=i0
MT=!p.TITLE
if n_elements(ndat) eq 0 then ndat=1
if n_elements(ik) eq 0 then ik=0
case 1 of
   i eq 3: i=0             ;obsolete parameter
   i eq 10: begin          ;hard copy
      i=0 & sp,ihcdev
      end
   else:
   endcase
;
IF N_ELEMENTS(NSM) EQ 0 THEN NSM=1
IF (NSM GT 0) AND (NSM LT 1000) THEN insm=1 else insm=0    ;use boxcar smoothing
IF strupcase(!D.name) ne 'X' THEN SCALE=10. ELSE SCALE=1.
ynz=rdbit(var3,3)                ;set YNOZERO keyword?
;
; check whether bad data exists to be will be overplotted
; bdata is primary indicator
;
if keyword_set(bdata) then bad=1 else bad=0               ;overplot bad data?
if n_elements(bdf) eq 0 then bdf=0                        ;not defined
if bdf ne 0 then bad=1                                    ;plot bad data
IF N_PARAMS(0) LE 3 THEN BAD=0                            ;BADW,BADF NOT PASSED
;
H0=H
IF N_ELEMENTS(H) LE 1 THEN NOHEAD=1 ELSE NOHEAD=0
if nohead eq 0 then if h(33) eq 30 then sn=1 else sn=0          ;SN vector?
!C=-1
IF (!Y.range(0) EQ 0.) AND (!Y.range(1) EQ 0.) THEN YSC=1 ELSE YSC=0
IF NOHEAD EQ 0 THEN BEGIN                               ;HEADER EXISTS
   LB2=''
   IF (NDAT EQ 1) OR (H(34) EQ 2) THEN BEGIN            ; TWO DATA SETS
      IF H(34) EQ 2 THEN FCTN=H(37) ELSE FCTN=0
      IF FCTN EQ 1 THEN H5=H(5)+H(205)
      WORD=STRMID('  ,  +  -  *  /  &  -%  -%',FCTN*3,5)
;
      IF H(34) EQ 2 THEN BEGIN                ;2 SETS MANIPULATED
         IF H(3) LT 5 THEN BEGIN
            IF (H(203) NE 0) AND (H(204) NE 0) THEN BEGIN
               I2=FIX(STRTRIM(H(204),2)) & IF I2 LT 0 THEN I2=65536L+I2
               SI2=STRTRIM(I2,2)
               LB2=STRMID('    LWP LWR SWP SWR ',H(203)*4,4)+SI2
               ENDIF ELSE LB2=''       ;NO SECOND HEADER
            ENDIF ELSE LB2=STRTRIM(BYTE(H(300:339)>32B),2)
         ENDIF ELSE BEGIN                  ;NDAT=1
            IF n_elements(h2) GE 140 then begin   ;2nd header exists
               IF H(3) LT 5 THEN BEGIN
                  IF (H2(3) NE 0) AND (H2(4) NE 0) THEN BEGIN
                     I2=FIX(STRTRIM(H(4),2)) & IF I2 LT 0 THEN I2=65536L+I2
                     SI2=STRTRIM(I2,2)
                     LB2=STRMID('    LWP LWR SWP SWR ',H2(3)*4,4)+SI2
                     ENDIF ELSE LB2=''       ;NO SECOND HEADER
                  ENDIF ELSE LB2=STRTRIM(BYTE(H2(100:139)>32B),2)
               ENDIF
            ENDELSE    ;NDAT=1
         if lb2 ne '' then !p.TITLE=!p.TITLE+WORD+LB2
;
      ENDIF      ;2 DATA SETS
   ENDIF         ; HEADER EXISTS
;
IF I LE -1 THEN BEGIN              ;INIT - PROCEDURE TO CLEAR SCREEN
     PRINT,' '
     ERASE
     !X.RANGE(*)=0. & !Y.RANGE(*)=0.
     !P.PSYM=0
     NSM=1
     C=FLTARR(1)+1.
     IFT=0
     IK=0
     IF I EQ -2 THEN BEGIN  ;option A, initial plot 
        IF NOHEAD EQ 0 THEN PLIHD,H0
        if nocap then PLOT,W,F,color=pcol,psym=psm,title='',subtitle='' else begin
           PLOT,W,F,color=pcol,psym=psm
           opdate,'ICUR'
           endelse
        ENDIF
     !P.SUBTITLE=''
     ENDIF
;
IF I EQ 0 THEN BEGIN   ;PLOT
   IF (NOHEAD EQ 0) AND (IK NE -777) THEN PLIHD,H0
   nax=rdbit(var3,1)
   maxw=w(n_elements(w)-1)
   if (!x.range(0) ne 0) and (!x.range(1) ne 0) then begin
      xok=1
      if (w(0) gt !x.range(1)) or (maxw lt !x.range(0)) then xok=0
      if xok EQ 0 then begin
        print,'Invalid data range: W from ',w(0),' to',maxw,'; axis =',!x.range 
          !p.TITLE=MT
          return
         endif
      endif
;
if nocap then begin
   ptt='' & pst=''
   endif else begin
   ptt=!p.title & pst=!p.subtitle
   endelse
   IF NAX EQ 1 THEN $
         PLOT,W,F,color=pcol,psym=psm,ynozero=ynz,title=ptt,subtitle=pst $
         else BEGIN                     ;NAX=1 -> DO NOT SMOOTH
      IF INSM EQ 1 THEN BEGIN
         IF NSM GE 3 THEN PLOT,W,SMOOTH(F,NSM),color=pcol,psym=psm,ynozero=ynz $
             ,title=ptt,subtitle=pst else $
             PLOT,W,F,color=pcol,psym=psm,ynozero=ynz,title=ptt,subtitle=pst
         ENDIF ELSE BEGIN
         IF YSC EQ 1 THEN BEGIN     ;DO NOT SCALE TO PTS ZEROED BY CONVOLUTION
            N=(N_ELEMENTS(C)-1)/2
            N0=N_ELEMENTS(F)-2*N
            k1=where(w gt !x.range(0)) & k1=k1(0)>n
            k2=where(w gt !x.range(1)) & k2=k2(0)
            if k2 eq -1 then k2=n_elements(F)-1
            k2=k2>n0
            !y.range(0)=MIN(F(k1:k2)) & !y.range(1)=MAX(F(k1:k2))
            !c=-1
            ENDIF
         PLOT,W,CONVOL(F,C),color=pcol,psym=psm,ynozero=ynz,title=ptt,subtitle=pst
         if ysc eq 1 then !y.range(*)=0.   ;reset scale
         ENDELSE
      ENDELSE
   !P.SUBTITLE=''
   IK=0
   if not nocap then opdate,'ICUR'
;
   IF BAD EQ 1 THEN begin
      c0=!p.color
      if sn eq 1 then begin         ;overplot error bars
         if strupcase(!d.name) eq 'X' then !p.color=15 else !p.color=PCOL  ;255
         for jj=0,n_elements(bf)-1 do $
            oplot,[bw(jj),bw(jj)],[f(jj)+bf(jj),f(jj)-bf(jj)],psym=0
         endif else begin           ; cross out bad data points
         if strupcase(!d.name) eq 'X' then !p.color=5 else !p.color=PCOL   ;255
         if n_elements(bf) eq 1 then bf=bf+fltarr(1)
         if n_elements(bf) eq n_elements(bw) then TKP,7,BW,BF  ;CROSS OUT BAD DATA
         endelse               ;sn
      !p.color=c0
      endif                    ;bad
   ENDIF          ;i=0
;
if ieb and (n_elements(eps) gt 1) then case 1 of     ;plot error bars
   h(33) eq 40: eb=eps
   h(33) eq 30: eb=f/eps
   else: ieb=0
   endcase
if ieb then erbar,2,f,eb,w,color=EBcol
;
IF I EQ 1 THEN BEGIN   ;OPLOT
   IF INSM EQ 1 THEN BEGIN
     IF NSM GT 2 THEN OPLOT,W,SMOOTH(F,NSM),color=pcol,psym=psm $
                 ELSE OPLOT,W,F,color=pcol,psym=psm
      ENDIF ELSE OPLOT,W,CONVOL(F,C),color=pcol,psym=psm
   ENDIF
;
if i0 ge 10 then lplt,ipdv,nodelete=rdbit(psdel,0),noplot=rdbit(psdel,1)
!p.TITLE=MT
RETURN
END
