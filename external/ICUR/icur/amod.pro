;*********************************************************
PRO AMOD,A,ISHAPE
;*********************************************************
;
PARAM=-1 & FACTOR=1. & OPERATION='*'
REPEAT BEGIN
    IF (PARAM EQ -1) THEN BEGIN
      PRINT,'Here is the A vector, as it now stands:'
      PRINT,' '
      PRINT,'                     INTENSITY  POSITION    WIDTH'
      FORM='("LINE #",I2,11X,E11.4,F10.2,F9.2)'
      FOR I=0,ISHAPE-1 DO PRINT,format=form,I,A(3*I),A(3*I+1),A(3*I+2)
      PRINT,' '
      PRINT,'YOU will be prompted for the PARAMeter to fudge and'
      PRINT,'then the fudge FACTOR and OPERATION (+,-,*,/,=)'
      PRINT,' '
      PRINT,'Enter -9 to RETURN;  ENTER -1 to display current A vector'
      PRINT,' '
      PRINT,' '
    ENDIF  ELSE BEGIN
      IF (PARAM GE 3*ISHAPE) OR (PARAM LT -1) THEN BEGIN
        PRINT,'NO SUCH PARAMETER, TRY AGAIN'
        PARAM=-1
      ENDIF  ELSE BEGIN
        PRINT,' Original PARAMeter (',PARAM,') = ',A(PARAM)
        READ,'fudge FACTOR? ',FACTOR
        READ,'   OPERATION? ',OPERATION
        OPERATION=STRTRIM(OPERATION)
        IF OPERATION EQ '*' THEN A(PARAM)=A(PARAM)*FACTOR
        IF OPERATION EQ '/' THEN A(PARAM)=A(PARAM)/FACTOR 
        IF OPERATION EQ '+' THEN A(PARAM)=A(PARAM)+FACTOR
        IF OPERATION EQ '-' THEN A(PARAM)=A(PARAM)-FACTOR
        IF OPERATION EQ '=' THEN A(PARAM)=FACTOR 
        PRINT,'   FUDGED PARAMeter (',PARAM,') = ',A(PARAM)
      ENDELSE
    ENDELSE
  READ,'PARAMETER? ',PARAM
ENDREP UNTIL (PARAM EQ -9)
;
PRINT,'continue entering parameters to fix... (-9 when finished; -10 to stop)'
RETURN
END
