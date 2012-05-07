;***********************************************************************
PRO MULTSUM,W,F,EPS,BW,BF,r,zrec     ; ADD OR CONCATENATE MULTIPLE DATA SETS
COMMON COM1,HD,IK,IFT,NSM,C,NDAT,IFSM,KBLO
COMMON COMXY,XCUR,YCUR,ZERR
COMMON icdisk,icurdisk,icurdata,ismdata,objfile,stdfile
dfile=objfile
if strupcase(objfile) eq 'NOFILE' then reda,' Enter name of file: ',objfile
h2=hd
nh=n_elements(hd)
if n_params(0) lt 7 then r=-1
if n_params(0) lt 8 then zrec=intarr(1)-1
rec=-1
if n_elements(zrec) le 1 then begin
   print,' MULTSUM: sum multiple spectra from current OBJFILE.'
   PRINT,' Enter 2 or more record numbers, -1 to end'
   READ,REC
   INREC=FIX(REC)
   WHILE REC GE 0 DO BEGIN
      READ,REC
      INREC=[INREC,FIX(REC)]
      ENDWHILE
   endif else inrec=zrec
if r eq -1 then begin
   PRINT,' '
   READ,' Add (0) or concatenate (1) ',R
   endif
IF R EQ 1 THEN Z0=38 ELSE Z0=43
K=WHERE(INREC GE 0)
iF k(0) eq -1 then goto,retn
INREC=INREC(K)
N=N_ELEMENTS(INREC)
IF N LT 2 THEN goto,retn
FUN3,0,0,0,HD,H2     ;RESET TITLE
hd=h2
if (hd(3) le 4) and (hd(39) gt 0) then begin
   if hd(39) gt 540 then hd(5)=-hd(39) else hd(5)=60*hd(39)+hd(40)
   hd(39:41)=0
   endif
HD(34)=N
PRINT,'TIME:',HD(5)
time=float(hd(5))
if hd(5) lt 0 then time=abs(time)*60.
TVECT=F*0.
;******
F0=F & W0=W
;***********
FOR I=0,N-1 DO BEGIN
   GDAT,dfile,H1,W1,F1,E1,INREC(I)
   if (h1(3) le 4) and (h1(39) gt 0) then begin
      if h1(39) gt 540 then h1(5)=-h1(39) else h1(5)=60*h1(39)+h1(40)
      h1(39:41)=0
      endif
   HD(200)=H1(0:nh-201)
   dw=w1(1)-w1(0)
   wmax=max(w1)
   s=size(e1) & st=s(s(0)+1)
   if st eq 1 then me=0 else me=-3200
   wx=[w1(0)-2.*dw,w1(0)-dw,w1,wmax+dw,wmax+2.*dw]
   f1=interpol([0.,0.,f1,0.,0.],wx,w)
   e1=interpol([me,me,e1,me,me],wx,w)
;   RREBIN,W,W1,F1,E1
   WSHIFT,0,W,F,EPS,F1,E1,E,W1
   ZERR=Z0
   MANIP,F,F1,TF,EPS,E1,TIME=TVECT  ;TVECT IS TIME VECTOR FOR CONCATENATING
   F=TF
   TE=E>EPS
   EPS=E
   if hd(205) lt 0 then time=time+abs(hd(205))*60. else time=time+hd(205)
   PRINT,'I,TIME:',I,time
   ENDFOR
IF Z0 EQ 43 THEN F=F/FLOAT(N) ELSE E=TE
if time lt 32767. then hd(5)=fix(time) else hd(5)=-fix(time/60.)
BDATA,hd,-1,W,F,E,BW,BF
BF=BF*0.
PLDATA,0,w,f,bw,bf,/bdata
ZERR=111
bell
RETURN
;
retn:
PRINT,STRING(BYTE(7)),' RETURNING - TOO FEW RECORDS '
ZERR=0
RETURN
END
