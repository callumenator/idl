;*****************************************************************
PRO BLOWUP,I,prt=prt,readout=readout       ; PROCEDURE TO EXPAND PLOT
; I=-1 FOR CURSOR CALL
; I=0 FOR COMPLETE BLOWUP
; I=1 FOR X ONLY
; I=2 FOR Y ONLY
COMMON COMXY,XCUR,YCUR,ZERR
common vars,var1,var2,var3,var4,var5,psdel,prffit,vrot2
if n_elements(xcur) eq 0 then xcur=mean(!x.crange)
if n_elements(ycur) eq 0 then ycur=mean(!y.crange)
;if n_elements(x) eq 0 then x=200
;if n_elements(y) eq 0 then y=200
;if n_elements(var3) eq 0 then var3=0
;NAX=rdbit(var3,0)
FORM1="($,A7)"
if strupcase(!d.name) eq 'X' or strupcase(!d.name) eq 'WIN' then isrc=1 else isrc=0
IF I EQ 91 THEN GOTO,EXPAND  ;EXPAND PLOT    ;[
IF I GE 30 THEN GOTO,SHFT                    ;<,>,^,6
IF I EQ -1 THEN BEGIN
if (xcur le !x.crange(0)) or (xcur gt !x.crange(1)) then xcur=mean(!x.crange)
if (ycur le !y.crange(0)) or (ycur gt !y.crange(1)) then ycur=mean(!y.crange)
   case 1 of
      isrc: begin
         tvcrs,xcur,ycur,/data
         if n_elements(readout) ne 0 then kwhere,readout else begin
            key=" "
            key=get_kbrd(1)
            zerr=FIX(byte(key))
            ZERR=ZERR(0)
            CURSOR,xcur,ycur,/NOWAIT
            endelse
         end
      strupcase(!d.name) eq 'TEK': begin
         CURSOR,xcur,ycur
         zerr=!err
         key=" "
         key=get_kbrd(1)
         end
      ELSE: begin
         key=get_kbrd(1)
         zerr=FIX(byte(key))
         ZERR=ZERR(0)
         end
      endcase
   if keyword_set(prt) then print,xcur,ycur
   RETURN
   ENDIF                       ;i=-1
;
; second call for i=0,1,2
;
XMAX=!X.range(1)
XMIN=!X.range(0)
YMAX=!Y.range(1)
YMIN=!Y.range(0)
X1=Xcur
Y1=Ycur
case 1 of
   isrc: begin
      OPSTAT,'  Waiting'
      tvcrs,xcur,ycur,/data
      z0=zerr
      if n_elements(readout) ne 0 then kwhere,readout else begin
         key=" "
         key=get_kbrd(1)
         CURSOR,xcur,ycur,/NOWAIT
         endelse
      zerr=z0
      end
   strupcase(!d.name) eq 'TEK': begin
      PRINT,FORMAT=FORM1,'Waiting'
      CURSOR,xcur,ycur,/WAIT,/data
      zerr=!err
      key=" "
      key=get_kbrd(1)
      PRINT,FORMAT=FORM1,'       '
      print,format="($,A)",string("12b)
      end
   ELSE: begin
      key=" "
      key=get_kbrd(1)
      end
   endcase
X2=Xcur
Y2=Ycur
!x.range=[(x1<x2),(x1>x2)]
!y.range=[(y1<y2),(y1>y2)]
;
IF I EQ 1 THEN !Y.range=[YMIN,ymax] ; EXPAND X AXIS ONLY
IF I EQ 2 THEN !X.range=[XMIN,xmax] ; EXPAND Y AXIS ONLY
ZERR=68
RETURN
;
EXPAND: ;EXPAND SCALES 2 TIMES
RX=(!X.range(1)-!X.range(0))
CX=RX/2.+!X.range(0)
RY=(!Y.range(1)-!Y.range(0))
CY=RY/2.+!Y.range(0)
!X.RANGE=[CX-RX,CX+RX]
!Y.RANGE=[CY-RY,CY+RY]
I=68
RETURN
;
SHFT:     ; SHIFT ALONG AXES
; > (62) SHIFT UP 1 FRAME (X)
; < (60) SHIFT DOWN 1 FRAME (X)
; ^ (94) SHIFT UP IN Y
; 6 (54) SHIFT DOWN IN Y
DX=!X.crange(1)-!X.crange(0)
DY=!Y.crange(1)-!Y.crange(0)
ISIGN=1
IF (I EQ 60) OR (I EQ 62) THEN BEGIN
   IF I EQ 60 THEN ISIGN=-1
   !X.range(0)=!X.crange(0)+ISIGN*DX
   !X.range(1)=!X.crange(1)+ISIGN*DX
   ENDIF
IF (I EQ 94) OR (I EQ 54) THEN BEGIN
   IF I EQ 54 THEN ISIGN=-1
   !Y.range(0)=!Y.crange(0)+ISIGN*DY
   !Y.range(1)=!Y.crange(1)+ISIGN*DY
   ENDIF
I=68
RETURN
END
