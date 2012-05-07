pro kwhere,index,accurate=accurate,wait=wait
common comxy,xcur,ycur,zerr,RESETSCALE,lu3
common icurunits,xunits,yunits,title,c1,c2,c3,ch
if strupcase(!d.name) ne 'X' then return
;
if keyword_set(wait) then wait=2 else wait=0
cr=string("15b)
if n_elements(xunits) eq 1 then sx=xunits+': ' else sx='X: '
if n_elements(yunits) eq 1 then sy=yunits+': ' else sy='Y: '
;
if n_elements(index) eq 0 then index=0
if index ge 100 then begin
   flag=index & index=index-100 & flag=flag-index
   endif else flag=0
case index of
   1: begin     ; only X output
      form="($,A11,F9.3,a)"
      if keyword_set(accurate) then form="($,A11,F12.6,a)"
      end
   2: begin     ; only Y output
      form="($,A19,G11.3,a)"
      if keyword_set(accurate) then form="($,A11,F12.6,a)"
      end
   else: begin
      form="($,A11,F9.3,', ',A9,G11.3,a)"
      if keyword_set(accurate) then form="($,A11,F12.6,', ',A9,G14.6,a)"
      end
   endcase
;
zerr=0
;print,format="($,A)",string("12b)             ;lf
if n_elements(xcur) eq 0 then xcur=mean(!x.crange)
if n_elements(ycur) eq 0 then ycur=mean(!y.crange)
x=xcur & y=ycur
key=get_kbrd(0)
while key eq '' do begin
   cursor,x,y,wait
   case 1 of
      flag eq 100: xx=x/!x.crange(1)
      else: xx=x
      endcase
   if ((x ge !x.crange(0)) and (x le !x.crange(1)) and $
      (y ge !y.crange(0)) and (y le !y.crange(1))) then case index of
      1: print,form=form,sx,xx,cr
      2: print,form=form,sy,y,cr
      else: print,form=form,sx,xx,sy,y,cr
      endcase
   key=get_kbrd(0)
   if key ne '' then goto,out
   endwhile
out:
print,format="($,A)",string("12b)
zerr=FIX(byte(key)) & zerr=zerr(0)
xcur=x
ycur=y
return
end
