pro cwhere,w,accurate=accurate,pixels=pixels
common comxy,xcur,ycur,zerr
common icurunits,xunits,yunits
if strupcase(!d.name) ne 'X' then return
wshow
ylog=!y.type
xlog=!x.type
yl=!y.crange(0) & yu=!y.crange(1)
if ylog eq 1 then begin
   yl=10^yl & yu=10^yu
   endif
xl=!x.crange(0) & xu=!x.crange(1)
if xlog eq 1 then begin
   xl=10^xl & xu=10^xu
   endif
if n_elements(w) lt 2 then pixels=0
;
print,' Use left mouse button to stop, center to mark, right to mark and print'
cr=string("15b)
if n_elements(xunits) eq 1 then sx=xunits+': ' else sx='X: '
if n_elements(yunits) eq 1 then sy=yunits+': ' else sy='Y: '
form="($,A11,F9.3,', ',A9,G11.3,a)"
if keyword_set(accurate) then form="($,A11,F12.6,', ',A9,G14.6,a)"
zerr=0
print,format="($,A)",string("12b)             ;lf
while zerr lt 1 do begin
   cursor,x,y,2
   zerr=!err
   if keyword_set(pixels) then v=xindex(w,x) else v=x
   if ((x ge xl) and (x le xu) and $
 (y ge yl) and (y le yu)) then print,form=form,sx,v,sy,y,cr
   if zerr eq 4 then begin
      print,format="($,A)",string("12b)
      zerr=0
      tkp,1,x,y
      wait,0.5
      endif
   if zerr eq 2 then begin
      zerr=0
      tkp,1,x,y
      wait,0.5
      endif
   endwhile
print,format="($,A)",string("12b)
xcur=x
ycur=y
zerr=119
return
end
