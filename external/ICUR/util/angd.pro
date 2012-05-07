;**************************************************************************
function angd,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,stp=stp  ;a1,d1a,a2,d2a   ; assume input in degrees
case 1 of
   n_params(0) eq 4: begin
      if (n_elements(i1) eq 3) and (n_elements(i2) eq 3) and $
         (n_elements(i3) eq 3) and (n_elements(i4) eq 3) then begin
         a1=hmstodeg(i1)
         d1a=dmstodeg(i2)
         a2=hmstodeg(i3)
         d2a=dmstodeg(i4)     
         endif else begin
         a1=i1
         d1a=i2
         a2=i3
         d2a=i4
         endelse
      end
   n_params(0) eq 8: begin
      a1=hmstodeg(i1,i2,0.)
      d1a=dmstodeg(i3,i4,0.)
      a2=hmstodeg(i5,i6,0.)
      d2a=dmstodeg(i7,i8,0.)
      end
   n_params(0) eq 10: begin
      a1=hmstodeg(i1,i2,i3)
      d1a=dmstodeg(i4,i5,0.)
      a2=hmstodeg(i6,i7,i8)
      d2a=dmstodeg(i9,i10,0.)
      end
   n_params(0) eq 11: begin
      a1=hmstodeg(i1,i2,i3)
      d1a=dmstodeg(i4,i5,i6)
      a2=hmstodeg(i7,i8,i9)
      d2a=dmstodeg(i10,i11,0.)
      end
   n_params(0) eq 12: begin
      a1=hmstodeg(i1,i2,i3)
      d1a=dmstodeg(i4,i5,i6)
      a2=hmstodeg(i7,i8,i9)
      d2a=dmstodeg(i10,i11,i12)
      end
   else: begin
      print,' '
      print,'* ANGD: return angular distances in degrees'
      print,'*    calling sequence: D=ANDG(a1,d1,a2,d2) - positions in degrees'
      print,'*            -or-     D=ANDG(h,m,s,d,dm,ds,h2,m2,s2,d2,dm2,ds2)
      print,'*            -or-     D=ANDG(h,m,s,d,dm,h2,m2,s2,d2,dm2)
      print,'*            -or-     D=ANDG(h,m,d,dm,h2,m2,d2,dm2)
      print,' '
      return,-1.
      end
   endcase
;
alpha=(double(a1)-double(a2))/!radeg
d1=double(d1a)/!radeg & d2=double(d2a)/!radeg
dist=(sin(d2)*sin(d1)+cos(d1)*cos(d2)*cos(alpha))<1.0
d=sqrt(1.-dist*dist)
dist=atan(d,dist)*!radeg
if keyword_set(stp) then stop,'ANGD>>>'
return,dist
end
