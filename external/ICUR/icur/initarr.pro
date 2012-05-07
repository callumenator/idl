;****************************************************************
PRO INITARR,MODE,VAR
; initialize ICFIT arrays
;
COMMON COM2,A,B,FH,FIXT,ISHAPE
case 1 of
   MODE EQ 1: BEGIN      ;zero everything
      A=FLTARR(18)
      VAR=FLTARR(18)
      FIXT=INTARR(18)+1
      B=INTARR(4)-1
      FH=FLTARR(15)-1.
      ISHAPE=0
      END
;
   else: begin          ;mode = 0
      ab=mean(var(1:*)-var)
      FOR I=0,ISHAPE-2 DO BEGIN
         ILIN=4+I*3
         i1=xindex(var,a(ilin))               ;TABINV,VAR,A(ILIN),I1
         A(ILIN)=I1                    ;+1
         A(ILIN-1)=A(ILIN-1)+A(0)
;                                             fix up FWHM's
         J=(I+2)*2
         FH(J+1)=FH(I)
         FH(J+2)=FH(J+1)+A(ILIN+1)*ab
         ENDFOR
      tn=fltarr(18) & tn(0)=a & a=tn
      tn=fltarr(15) & tn(0)=fh & fh=tn
      tn=intarr(18)+1 & tn(0)=fixt & fixt=tn
      end
   endcase
;
RETURN
END
