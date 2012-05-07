;**************************************************************************
;+
;FMEDIAN : variant of Gmedian
;*NAME: 
;    GMEDIAN  (General IDL Library 01) May 20, 1980 
; 
;*CLASS:
;    Smoothing
;
;*CATEGORY:
;
;*PURPOSE:  
;    To perform a median filter on an one-dimensional array. The type of the
;    array is not converted to BYTE (as in the IDL MEDIAN), but is left the
;    same as the input type. 
; 
;*CALLING SEQUENCE: 
;     out=GMEDIAN(IN,M)
; 
;*PARAMETERS:
;     IN   (REQ) (I) (1) (I L F D)
;          Required input vector containing the data which are to be filtered.
;          If OUT is omitted from the calling sequence, the filtered data are
;          returned in IN. 
;
;     M    (REQ) (I) (0) (I)
;          Length of the median filter
;
;     OUT  (OPT) (O) (1) (I L F D)
;          Output median-filtered vector.
; 
;*EXAMPLE:
;      To median filter a data vector BKG:
;        GMEDIAN,BKG,63,FBKG  ;63 point filter
;
;*SYSTEM VARIABLES USED:
;      None.
;
;*INTERACTIVE INPUT:
;      None.
;
;*SUBROUTINES CALLED:
;    PARCHECK
;
;
;*FILES USED: 
;    IUER_USERDATA:GMEDIAN.TMP -temporary scratch data set
;
;*SIDE EFFECTS:
;    You may not execute this procedure from two or more simultaneous
;    sessions in your account. There will be conflicts over the .TMP
;    file.
;
;*RESTRICTIONS:
;    None 
;
;*NOTES:
;    Fortran Task  IUER_SOFTDISK:[IUERDAF.PRODUCTION]GMEDIAN.EXE is 
;    called to do the median filter.
;    The fortran task forces the filter with to be odd.
;    Widths less than 2 result in no filtering.
;    The data array is truncated to 4096 points in length.
;    The first and last M/2 points are copied from the 
;    input to the output arrays with no filtering.
; 
;*PROCEDURE:
;    The length of the filter and the input array are copied
;    to a temporary file GMEDIAN.TMP and the task GMEDIAN.EXE
;    called.
;    For I = M/2 to N - M/2 - 1 where N is the length 
;    of IN the median is computed by:
;    OUT(I) = Median value of (IN(J),J=I-M/2 to I+M/2)
;    Points for I=0, M/2 - 1 and I=N-M/2,N  OUT(I) = IN(I)
;    The fortran task writes the sizes and the filtered results
;    to the file GMEDIAN.TMP and exits with a stop.
;    The procedure reads the lengths and the filtered results.
;    If errors arose, a message is output.
; 
;*MODIFICATION HISTORY:
;    Jul 31 1980 D. Lindler initial version
;    Sep 13 1982 FHS3  GSFC CR#047 increase vector sizes to 4096 points.
;    Apr 15 1985 RWT   GSFC name changed to GMEDIAN to make routine 
;                           compatible with XIDL.
;    Jun  8 1987 RWT   GSFC add PARCHECK, use N_ELEMENTS, and make OUT
;                           optional.
;    Jun 22 1987 RWT   GSFC fix error with N not being defined
;    Mar 10 1988 CAG   GSFC add VAX RDAF-style prolog, and print
;                           statement if the procedure is executed
;                           without parameters.
;-
;*************************************************************************
function FMEDIAN,INP,M
in=inp
;
; CHECK INPUT PARAMETERS
;
  IF N_PARAMS(0) EQ 0 THEN BEGIN
     PRINT,'out=fMEDIAN(IN,M)'
     RETALL
    ENDIF
  PARCHECK,N_PARAMS(0),[2,3],'GMEDIAN'
  PCHECK,IN,1,010,0111
  PCHECK,M,2,100,0010
  N = FIX(N_ELEMENTS(IN))
  IF (M GT N) OR (M LT 2) THEN BEGIN
     PRINT,'INVALID FILTER WIDTH '
     RETALL
     END; IF
;
  R=1.0*IN                            ;CONVERT TO REAL
;
; WRITE INFO TO THE INTERMEDIATE DATA SET
;
  CLOSE,3
  OPENW,3,'MEDIAN.TMP/UNF'
  FORWRT,3,N,FIX(M)                          ;WRITE OUT PARAMETERS
  FORWRT,3,R
  CLOSE,3
; 
; EXECUTE THE FORTRAN TASK
;
  SPAWN,'RUN IUER_GL01:GMEDIAN.EXE'    ;RUN MEDIAN TASK
;
; READ RESULTS FROM THE INTERMEDIATE DATA SET
;
  OPENR,3,'MEDIAN.TMP/UNF'
  NN=N
  NM=M
  FORRD,3,NN,NM
  OUT=FLTARR(NN)
  FORRD,3,OUT                          ;GET RESULTS
  CLOSE,3
  if !version.os eq 'vms' then z='DELETE/noconfirm MEDIAN.TMP;*' else z='rm median.tmp'
  spawn,z                      ;DELETE SCRATCH DATA SET
;
; CHECK FOR ERROR CONDITIONS
;
  IF NN NE N THEN PRINT,'*** DATA SET TOO BIG - TRUNCATED TO',NN,' POINTS'
;  IF N_PARAMS(0) EQ 2 THEN IN = OUT    ;redefine input array
RETURN,out  ;GMEDIAN
END     ;GMEDIAN
