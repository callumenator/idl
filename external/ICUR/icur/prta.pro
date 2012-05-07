;**********************************************************************
PRO PRTA,I,J,Z
COMMON COM2,A
IF I EQ 1 THEN BEGIN
   Z='A: '+STRING(FORMAT='(E10.3)',A(J))+STRING(FORMAT='(F8.2)',A(J+1))
   Z=Z+STRING(A(J+2),FORMAT='(F8.2)')
   ENDIF
IF I EQ 2 THEN BEGIN
   Z='A: '+STRING(A(J),FORMAT='(E10.3)')+STRING(A(J+1),FORMAT='(F8.2)')
   Z=Z+STRING(A(J+2),FORMAT='(F8.2)')
   Z=Z+STRING(A(J+3),FORMAT='(E10.3)')+STRING(A(J+4),FORMAT='(F8.2)')
   Z=Z+STRING(A(J+5),FORMAT='(F8.2)')
   ENDIF
RETURN
END
