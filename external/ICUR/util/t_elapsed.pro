;**************************************************************************
pro t_elapsed,t1,time,prt=prt,lu=lu,helpme=helpme
if n_elements(t1) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,'*'
   print,'* T_ELAPSED - return elapsed time'
   print,'* calling sequence: T_ELAPSED,T,TIME'
   print,'*   T: start time'
   print,'*   TIME: elapsed time in seconds'
   print,'*'
   print,'*   KEYWORD:'
   print,'*      PRT: set to print elapsed time'
   print,'*'
   print,'* to run: 1 - place T=SYSTIME(0) at start of run '
   print,'*         2 - place T_ELAPSED,T at end of run'
   print,'*'
   return
   end
;
if n_elements(lu) eq 0 then lu=-1
t2=systime(0)
t=t1
st1=float(strmid(t,11,2))*3600.+float(strmid(t,14,2))*60.+float(strmid(t,17,5))
t=t2
st2=float(strmid(t,11,2))*3600.+float(strmid(t,14,2))*60.+float(strmid(t,17,5))
time=st2-st1
if time lt 0. then time=86400.-time
if keyword_set(prt) then begin
   min=fix(time/60.)
   sec=time-min*60.
   printf,lu,' elapsed time=',string(min,'(I3)'),':',string(sec,'(F5.2)')
   endif
return
end
