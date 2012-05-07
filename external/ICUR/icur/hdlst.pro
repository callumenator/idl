;******************************************************************
PRO HDLST,IAR                          ;HELP LISTING OF CURSOR COMMANDS
;VAX VERSION 1.0 8/15/86
; IAR = 0,1 FOR ICUR (1 FOR KPNO DATA, 0 FOR IUE DATA)
; IAR = 2 FOR FUN1
; IAR = 3 FOR FUN2
if !d.name eq 'TEK' then erase
nullz='                                   '
Z='(ICUR)'
IF IAR EQ 2 THEN Z='(FUN1)'
IF IAR EQ 3 THEN Z='(FUN2)'
PRINT,'    CURSOR COMMANDS: '+Z+' * ->2 INPUTS EXPECTED            '
PRINT,'  A:  PLOT ALL DATA                  a:  ADD LINE TO DATA     '
PRINT,'  B:  BLOW UP PLOT; ENTER CORNERS *  b:  REDEFINE BAD DATA    '
PRINT,'  C:  COMPUTE CENTROID OF FEATURE *  c:  COADD BINS           '
Z='  '
IF IAR LT 3 THEN Z='  d:  DIVIDE KPNO DATA BY ND         '
IF IAR EQ 0 THEN Z='  d:  DEGRADE IUE HI-RES TO LO-RES   '
PRINT,'  D:  PLOT AND INDICATE BAD DATA   ',Z
IF IAR EQ 2 THEN Z='  e:  DIVIDE IIDS DATA (F1) BY ND   '
IF IAR LT 2 THEN Z='  e:  FOURIER SMOOTHING     '
IF IAR EQ 3 THEN Z='  e:  RESTORE EPS VECTOR    '
PRINT,'  E:  MEASURE FEATURES *           ',Z
PRINT,'  F:  ENTER IFIT TO FIT DATA         f:  LIST LINES IN REGION     '
Z='g:  GET DATA FROM -.STD FILE    '
z1='g:  MULTISUM                   '
IF IAR LT 2 THEN PRINT,'  G:  RETRIEVE DATA                  ',Z
IF IAR EQ 2 THEN PRINT,'  G:  OFFSET WAVELENGTH SCALE        ',Z
IF IAR EQ 3 THEN PRINT,'  G:  REFLECT DATA                   ',z1
Z=' '
z1=nullz
IF IAR LT 2 THEN Z='  h:  FOURIER SMOOTH SECOND SPECTRUM   '
IF IAR EQ 2 THEN Z='  h:  AS G, BUT USE HALF BINS          '
IF IAR EQ 3 THEN Z='  h:  update current disk record    '
if iar le 1 then z1='  H:   Restore initial vectors     ' else z1=nullz
 PRINT,z1,Z
 PRINT,'  I:  INITIALIZE SCREEN              i:  LINEAR INTERP. W/ X MARKED *  '
 PRINT,'  J:  JUMP ALONG X AXIS              j:  LINEAR INTERP. W/X,Y MARKED * '
Z='  k:  MAKE SMOOTHING PERMANENT  '
IF IAR EQ 2 THEN Z='  k:  DIVIDE IIDS DATA (F) BY ND   '
IF IAR LT 2 THEN Z='  k:  AUTO/CROSS CORRELATION       '
 PRINT,'  K:  SAVE DATA ON DISK            ',Z
IF IAR EQ 1 THEN Z='  l:  LIST CONTENTS OF STDFILE     ' ELSE                  Z='  l:  LIST CONTENTS OF OBJFILE     '
 PRINT,'  L:  LOCATE WAVELENGTH            ',Z
IF IAR EQ 3 THEN PRINT,'  M:  MEAN, S/N *                    m:  SPECMERGE' ELSE $
    PRINT,'  M:  MEAN, S/N *                    m:  CALL FUN2     '
IF IAR LT 2 THEN Z='  n:  NORMALIZE FLUX TO MAXIMUM   ' ELSE Z=' '
 PRINT,'  N:  RESET Y SCALING TO 0.        ',Z
IF IAR GE 2 THEN Z='OVERWRITE INPUT DATA    ' ELSE Z='NEGATE G COMMAND     '
 PRINT,'  O:  OVERPLOT DATA (DO G FIRST)     o:  ',Z
 PRINT,'  P:  CHANGE !P.PSYM 0 <-> 10        p:  PRINT STATUS     '
Z=' EXIT TO IDL      '
IF IAR EQ 2 THEN Z=' TO ICUR           '
IF IAR EQ 3 THEN Z=' TO ICUR OR FUN1   '
IF IAR LT 2 THEN PRINT,'  Q:  Quit              ','             q:  RETURN'
IF IAR GE 2 THEN PRINT,'  Q:  RETURN',Z,'      q:  RETURN',z
z='r:  ROTATIONAL BROADENING   '
 if iar lt 2 then PRINT,'  R:  Rest object file               ',z $
 else PRINT,            '  R:  REPLOT WITH CURRENT LIMITS     ',z
 PRINT,'  S:  BOXCAR SMOOTH, <0 =TRIANGLE    s:  GAUSSIAN SMOOTHING      '
IF IAR LT 3 THEN Z='  t:  OVERPLOT BLACK BODY   ' else Z='  t:  CHANGE TITLE   '
 PRINT,'  T:  TOTAL FLUX *                 ',Z
Z='u:  UNREDDEN DATA   '
IF IAR LT 2 THEN PRINT,'  U:  MANIPULATE DATA                ',Z
IF IAR EQ 2 THEN PRINT,'  U:  SCALE F1 TO LEVEL OF FLUX *    ',Z
IF IAR EQ 3 THEN PRINT,'  U:  FLUX HIGH RESOLUTION DATA      ',Z
CASE 1 OF
   IAR EQ 3: Z='  v:  RESET WAVELENGTH SCALE  '
   ELSE    : Z='  v:  FWHM                    ' 
   ENDCASE
 PRINT,'  V:  LOCATE WAVELENGTH AND EXPAND ',Z
IF IAR EQ 3 THEN Z='  w:  CHANGE WAVELENGTH UNITS   ' ELSE Z='  w: continuous cursor readout'
 PRINT,'  W:  PRINT CURSOR POSITION        ',Z
 PRINT,'  X:  EXPAND X AXIS *                x:  RESET EPS. VECTOR TO -1111 '
case 1 of
   iar lt 2: Z='  y:  continuum filter             '
   IAR EQ 3: Z='  y:  CHANGE FLUX UNITS            '
   else: Z='   '
   endcase
 PRINT,'  Y:  EXPAND Y AXIS *              ',Z
 PRINT,'  Z:  STOP; .CON TO RESUME           z:  SET BADF TO ZERO   '
 PRINT,'  @:  ENABLE/DISABLE AXIS SCALING    #:  SMOOTH ONLY SECOND DATA SET   '
 if iar lt 3 then $
 PRINT,'  =:  send plot to hard copy device  ):  Toggle plot captioning   '
Z='  [:  EXPAND PLOT SCALE x2   '
IF IAR LT 2 THEN PRINT,Z,'        $:  USER DEFINED PROCEDURE  '
 PRINT,'  0:  DRAW ZERO LEVEL             <>^6:  SHIFT PLOT L,R,UP,DOWN   '
 if iar le 1 then $
 PRINT,'  &:  Enable/Disable logging         %:  normalize and flatten spectrum'
IF IAR GE 2 THEN BEGIN
 PRINT,'  +:  ADD TWO SPECTRA                *:  MULTIPLY THE TWO SPECTRA   '
 PRINT,'  -:  SUBTRACT F1 FROM FLUX          /:  DIVIDE FLUX BY F1   '
 PRINT,'  &:  SUM AND AVERAGE GOOD DATA    ',Z
 PRINT,'  1:  DRAW LINE AT Y=1.              2:  DIVIDE FLUX BY 2.   '
ENDIF ELSE begin 
   if iar lt 2 then z=' ESC,~:  RETRIEVE NEW DATA        ' else z=nullz
   PRINT,z,'   -:  DIS/ENABLE FUN1 FLUX SCALING '
   endelse
if iar lt 2 then PRINT,'  ;:  GET NEXT RECORD (ESC)          :   GET previous RECORD (ESC)'
 if iar le 2 then z='  !:  TOGGLE PLOT DEVICE PS<->X    ' else z=nullz
 print,'  ?:  brief help                   ',z
RETURN
END
