;***********************************************************************
PRO REcalh,HU,WU,FU,EU                  ; FLUX HIGH RESOLUTION DATA
; HU,WU,FU,EU are the unfluxed input data
; FU will be overwritten with the fluxed data vector
COMMON COM1,H,IK,IFT,NSM,C
READ,' Enter name of fluxed data file',file2
GDAT,file2,H,WF,FF,EF   ;fluxed data
F=FU
W=WU
EE=EU
RREBIN,WF,W,F,EE,FLAG
IF FLAG EQ -1 THEN RETURN                  ; NO OVERLAP
DISP=(WF(50)-WF(0))/(WU(50)-WU(0))
S=N_ELEMENTS(FU)
NBINS=FIX(S/DISP)
i=xindex(wf,wu(0))                   ;TABINV,WF,WU(0),I
I=FIX(I)+1
WF=WF(I:I+NBINS)
FF=FF(I:I+NBINS)
F=F(0:NBINS)
TF=TOTAL(FF)/TOTAL(F)   
F=F*TF   ;SCALE TWO FLUX VECTORS
N0=NSM & C0=C
NSM=1 & C=1.
WSHIFT,1,WF,FF,EF,F,EE,E,W
ZERR=47
MANIP,SMOOTH(FF,11),SMOOTH(F,15),FDIV,EF,EE
NSM=NO & C=C0
F=INTERPOL(FDIV,WF,WU)
F=SMOOTH(F,3)
FU=FU*SMOOTH(F,15)*TF
!ERR=0
HU(54)=1
RETURN
ERRRET: ;error - IDAT out of range
PRINT,' RETURNING: IDAT OUT OF RANGE'
HU(54)=0
RETURN
END
