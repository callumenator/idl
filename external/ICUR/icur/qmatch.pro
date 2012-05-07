;***********************************************************************
pro qmatch,wf
common tvcom,pixf,tvzerr,scale,imin,imax
if n_params(0) eq 0 then wf=-1
if n_elements(wf) lt 2 then begin
   print,' '
   print,'* QMATCH - match intensities in WF/PC quadrants'
   print,'*    calling sequence: QMATCH,IMAGE'
   print,'*       '
   print,'*   enter quadrant number (0-3, ccw from upper left) and increment,'
   print,'*      enter invalid quadrant or 0 increment to quit'
   print,' '
   return
   endif
print,'Current scaling factors:',scale
s=size(wf)
if s(0) lt 2 then return
sx=s(1)
sy=s(2)
x=[0,sx/2,sx/2+1,sx-1]
y=[0,sy/2,sy/2+1,sy-1]
m=intarr(4)
m(0)=mean(wf(x(0):x(1),y(0):y(1)))
m(1)=mean(wf(x(0):x(1),y(2):y(3)))
m(2)=mean(wf(x(2):x(3),y(2):y(3)))
m(3)=mean(wf(x(2):x(3),y(0):y(1)))
print,' mean in quadrants 0,1,2,3:',m
quad=0
fact=1
print,' enter quadrant (-1 to quit), additive factor'
while (quad ge 0) and (fact ne 0) do begin
   read,quad,fact
   case 1 of
      fact eq 0: return
      quad eq 0: i=[0,1,0,1]
      quad eq 1: i=[0,1,2,3]
      quad eq 2: i=[2,3,2,3]
      quad eq 3: i=[2,3,0,1]
      else: return
      endcase
   z=wf(x(i(0)):x(i(1)),y(i(2)):y(i(3)))
   z=(z+fact)>0
   wf(x(i(0)),y(i(2)))=z
   scale(quad)=scale(quad)*10^(fact/m(quad))
   print,'Current scaling factors, new mean in quadrant',scale,mean(z)
   tvs,wf
   endwhile
tvhist,wf
return
end 

