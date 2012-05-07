;************************************************************************
pro wrect,file,r1,r2,dw=dw,mc1=mc1,mc2=mc2,save=save
COMMON COM1,H,IK,IFT,NSM,C,ndat,ifsm,kblo,h2
common comxy,xcur,ycur,zerr,resetscale,lu3
common icurunits,xu,yu,title,c1,c2,c3
;
lu3=-1
gdat,file,h1,w1,f1,e1,r1
gdat,file,h2,w2,f2,e2,r2
setxy
gc,11
;
if keyword_set(save) then begin
   restore,save
   goto, skipfit
   endif
if keyword_set(mc1) and keyword_set(mc2) then begin
   goto, skipfit
   endif
;
wa=w1(0)>w2(0)
wb=max(w1)<max(w2)
;
if not keyword_set(dw) then dw=100
de=dw*0.8
mw1=0. & mw2=0.
wstart=wa-de
;
loop:           ;************************************
ik=0
wstart=wstart+de
setxy,wstart,wstart+dw,0.,0.
if wstart ge wb then goto,done
plot,w1,f1
oplot,w2,f2,color=55
if !d.name eq 'X' then wshow
zerr=0
while zerr ne 48 do begin
   print,'mark edges of line in spectrum 1; 0 to advance'
   blowup,-1
   case 1 of
      zerr eq 48: goto,loop
      (zerr eq 90) or (zerr eq 122): begin
         stop,'WRECT>>>'
         if !d.name eq 'X' then wshow
         print,'mark edges of line in spectrum 1 again'
         blowup,-1
         end
      (zerr eq 81) or (zerr eq 113): goto,done
      else:
      endcase
   ftot,2,w1,f1,xc1
   print,'mark edges of line in spectrum 2'
   blowup,-1
   ftot,2,w2,f2,xc2
   mw1=[mw1,xc1] & mw2=[mw2,xc2]
   endwhile
;
done:
nm=n_elements(mw1)
if nm gt 1 then begin
   mw1=mw1(1:*) & mw2=mw2(1:*)
   endif
;
skipfit:
;
ndeg=2
refit:
setxy
x=mw1-mw1(0)
y=mw1-mw2
coeff=poly_fit(x,y,ndeg)
yf=coeff(0)+x*coeff(1)
if ndeg gt 1 then for i=2,ndeg do yf=yf+coeff(i)*x^i
plot,mw1,y & oplot,mw1,yf
yff=interpol(yf,mw1,w1)
if !d.name eq 'X' then wshow
igo = 0
print,' ndeg = ',ndeg
read,' refit? enter ndeg: ',ndeg
case 1 of
   ndeg eq -1: stop
   ndeg ge 1: goto,refit
   else:
   endcase
ff2=interpol(f2,w2,w2-yff)
ee2=interpol(e2,w2,w2-yff)
setxy
plot,w1,f1
oplot,w2,ff2
if keyword_set(stp) then stop,'WRECT>>>'
igo=0
read,' OK to save? enter 1: ',igo
if igo eq 1 then begin
   title=''
   read,' Enter title: ',title
   title=fix(byte(title))
   h2(100:159)=32
   h2(100)=title
   kdat,file,h2,w2,ff2,ee2,-1
   endif
;
setxy
return
end
