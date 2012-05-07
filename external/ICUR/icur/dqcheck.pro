;************************************************************************
function dqcheck,fin,eps,q        ;check data quality and censor at level q
if n_params(0) lt 2 then fin=-1
if n_elements(fin) le 1 then begin
   print,' '
   print,'DQcheck - check data quality vector and interpolate over bad points'
   print,'    calling sequence: FOUT=dqcheck(fin,eps,q)'
   print,'        FOUT: Output vector, interpolated over flagged points'
   print,'         FIN: Input vector'
   print,'         EPS: Data quality vector'
   print,'           Q: threshold. Points with EPS>Q are interpolated, def=0'
   print,' '
   return,fin
   endif
if n_params(0) lt 3 then q=0
k=where(eps ge q,nk)
if nk eq 0 then begin
   print,'DQCHECK: warning - no points with acceptable data quality'
   print,'         returning input vector'
   return,fin     ;no bad data
   endif
np=n_elements(fin)
k=where(eps le q,nk)
if nk eq -1 then return,fin
x=findgen(np)
xx=x(k)
ff=fin(k)
fout=interpol(ff,xx,x)
return,fout
end

