;******************************************************************
PRO LSQREP,X,Y,LU
N=FLOAT(N_ELEMENTS(X))
SLOPE=0.0 & DS=0.0
B=0.0 & DB=0.0
R=0.0
SX=TOTAL(X)
SY=TOTAL(Y)
SX2=TOTAL(X*X)
SY2=TOTAL(Y*Y)
SXY=TOTAL(X*Y)
D=N*SX2-SX*SX
IF D EQ 0.0 THEN begin
   printf,lu,' Singular matrix (infinite slope)'
   RETURN
   endif
B=(SX2*SY-SX*SXY)/D
SLOPE=(SXY*N-SX*SY)/D
V=(SY2+B*B*N+SLOPE*SLOPE*SX2-2.*(B*SY+SLOPE*SXY-SLOPE*B*SX))/(N-2.)
DB=SQRT(V*SX2/D)
DS=SQRT(V*N/D)
R=(N*SXY-SX*SY)/SQRT(D*(SY2*N-SY*SY))
   printf,lu,'slope=',slope,' +/-',ds,'  Yintercept=',b,' +/-',db
   printf,lu,' Correlation coefficient =',r
RETURN
END
