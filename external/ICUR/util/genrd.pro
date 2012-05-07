;*******************************************************************
pro genrd,lu,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15,i16,i17, $
    i18,i19,i20,noclose=noclose,skiplines=skiplines,silent=silent,ncol=ncol, $
    stp=stp
;
ninp=n_params(0)-1
if (ninp eq 1) and (n_elements(i1) gt 1) then begin
   doarr=1 & nn=n_elements(i1)
   endif else doarr=0
on_ioerror,misread
if ifstring(lu) then begin
   file=lu
   if not ffile(file) then begin
      print,' File ',file,' not found - returning'
      if keyword_set(stp) then stop,'GENRD>>>'
      return
      end
   openr,lu,file,/get_lun
   endif else file=0
z=''
if n_elements(skiplines) eq 1 then for i=0,skiplines do readf,lu,z
case 1 of
   keyword_set(ncol): begin
      a1=dblarr(ncol>1)
      i1=a1
      readf,lu,i1
      while not eof(lu) do begin
         readf,lu,a1
         i1=[[i1],[a1]]
         endwhile
      end
   ninp eq 1: begin
      a1=i1 
      readf,lu,i1
      while not eof(lu) do begin
         readf,lu,a1
         i1=[i1,a1]
         endwhile
      end
   ninp eq 2: begin
      a1=i1 & a2=i2
      readf,lu,i1,i2
      while not eof(lu) do begin
         readf,lu,a1,a2
         i1=[i1,a1]
         i2=[i2,a2]
         endwhile
      end
   ninp eq 3: begin
      a1=i1 & a2=i2 & a3=i3
      readf,lu,i1,i2,i3
      while not eof(lu) do begin
         readf,lu,a1,a2,a3
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         endwhile
      end
   ninp eq 4: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4
      readf,lu,i1,i2,i3,i4
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         endwhile
      end
   ninp eq 5: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5
      readf,lu,i1,i2,i3,i4,i5
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         endwhile
      end
   ninp eq 6: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6
      readf,lu,i1,i2,i3,i4,i5,i6
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5,a6
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         endwhile
      end
   ninp eq 7: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7
      readf,lu,i1,i2,i3,i4,i5,i6,i7
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5,a6,a7
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         endwhile
      end
   ninp eq 8: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7
      a8=i8 
      readf,lu,i1,i2,i3,i4,i5,i6,i7,i8
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5,a6,a7,a8
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         i8=[i8,a8]
         endwhile
      end
   ninp eq 9: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7
      a8=i8 & a9=i9
      readf,lu,i1,i2,i3,i4,i5,i6,i7,i8,i9
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5,a6,a7,a8,a9
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         i8=[i8,a8]
         i9=[i9,a9]
         endwhile
      end
   ninp eq 10: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7
      a10=i10 & a8=i8 & a9=i9
      readf,lu,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         i8=[i8,a8]
         i9=[i9,a9]
         i10=[i10,a10]
         endwhile
      end
   ninp eq 11: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7
      a10=i10 & a11=i11 & a8=i8 & a9=i9
      readf,lu,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         i8=[i8,a8]
         i9=[i9,a9]
         i10=[i10,a10]
         i11=[i11,a11]
         endwhile
      end
   ninp eq 12: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7
      a10=i10 & a12=i12 & a11=i11 & a8=i8 & a9=i9
      readf,lu,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         i8=[i8,a8]
         i9=[i9,a9]
         i10=[i10,a10]
         i11=[i11,a11]
         i12=[i12,a12]
         endwhile
      end
   ninp eq 13: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7
      a10=i10 & a12=i12 & a11=i11 & a8=i8 & a9=i9 & a13=i13
      readf,lu,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         i8=[i8,a8]
         i9=[i9,a9]
         i10=[i10,a10]
         i11=[i11,a11]
         i12=[i12,a12]
         i13=[i13,a13]
         endwhile
      end
   ninp eq 14: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7
      a10=i10 & a12=i12 & a11=i11 & a8=i8 & a9=i9 & a13=i13 & a14=i14
      readf,lu,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         i8=[i8,a8]
         i9=[i9,a9]
         i10=[i10,a10]
         i11=[i11,a11]
         i12=[i12,a12]
         i13=[i13,a13]
         i14=[i14,a14]
         endwhile
      end
   ninp eq 15: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7 & a15=i15
      a10=i10 & a12=i12 & a11=i11 & a8=i8 & a9=i9 & a13=i13 & a14=i14
      readf,lu,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         i8=[i8,a8]
         i9=[i9,a9]
         i10=[i10,a10]
         i11=[i11,a11]
         i12=[i12,a12]
         i13=[i13,a13]
         i14=[i14,a14]
         i15=[i15,a15]
         endwhile
      end
   ninp eq 16: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7 & a15=i15
      a10=i10 & a12=i12 & a11=i11 & a8=i8 & a9=i9 & a13=i13 & a14=i14
      a16=i16
      readf,lu,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15,i16
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         i8=[i8,a8]
         i9=[i9,a9]
         i10=[i10,a10]
         i11=[i11,a11]
         i12=[i12,a12]
         i13=[i13,a13]
         i14=[i14,a14]
         i15=[i15,a15]
         i16=[i16,a16]
         endwhile
      end
   ninp eq 17: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7 & a15=i15
      a10=i10 & a12=i12 & a11=i11 & a8=i8 & a9=i9 & a13=i13 & a14=i14
      a16=i16 & a17=i17 
      readf,lu,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15,i16,i17
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         i8=[i8,a8]
         i9=[i9,a9]
         i10=[i10,a10]
         i11=[i11,a11]
         i12=[i12,a12]
         i13=[i13,a13]
         i14=[i14,a14]
         i15=[i15,a15]
         i16=[i16,a16]
         i17=[i17,a17]
         endwhile
      end
   ninp eq 18: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7 & a15=i15
      a10=i10 & a12=i12 & a11=i11 & a8=i8 & a9=i9 & a13=i13 & a14=i14
      a16=i16 & a17=i17 & a18=i18
      readf,lu,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15,i16,i17,i18
      while not eof(lu) do begin
         readf,lu,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         i8=[i8,a8]
         i9=[i9,a9]
         i10=[i10,a10]
         i11=[i11,a11]
         i12=[i12,a12]
         i13=[i13,a13]
         i14=[i14,a14]
         i15=[i15,a15]
         i16=[i16,a16]
         i17=[i17,a17]
         i18=[i18,a18]
         endwhile
      end
   ninp eq 19: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7 & a15=i15
      a10=i10 & a12=i12 & a11=i11 & a8=i8 & a9=i9 & a13=i13 & a14=i14
      a16=i16 & a17=i17 & a18=i18 & a19=i19
     readf,lu,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15,i16,i17,i18,i19
      while not eof(lu) do begin
     readf,lu,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         i8=[i8,a8]
         i9=[i9,a9]
         i10=[i10,a10]
         i11=[i11,a11]
         i12=[i12,a12]
         i13=[i13,a13]
         i14=[i14,a14]
         i15=[i15,a15]
         i16=[i16,a16]
         i17=[i17,a17]
         i18=[i18,a18]
         i19=[i19,a19]
         endwhile
      end
   ninp eq 20: begin
      a1=i1 & a2=i2 & a3=i3 & a4=i4 & a5=i5 & a6=i6 & a7=i7 & a15=i15
      a10=i10 & a12=i12 & a11=i11 & a8=i8 & a9=i9 & a13=i13 & a14=i14
      a16=i16 & a17=i17 & a18=i18 & a19=i19 & a20=i20
 readf,lu,i1,i2,i3,i4,i5,i6,i7,i8,i9,i10,i11,i12,i13,i14,i15,i16,i17,i18,i19,i20
      while not eof(lu) do begin
 readf,lu,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20
         i1=[i1,a1]
         i2=[i2,a2]
         i3=[i3,a3]
         i4=[i4,a4]
         i5=[i5,a5]
         i6=[i6,a6]
         i7=[i7,a7]
         i8=[i8,a8]
         i9=[i9,a9]
         i10=[i10,a10]
         i11=[i11,a11]
         i12=[i12,a12]
         i13=[i13,a13]
         i14=[i14,a14]
         i15=[i15,a15]
         i16=[i16,a16]
         i17=[i17,a17]
         i18=[i18,a18]
         i19=[i19,a19]
         i20=[i20,a20]
         endwhile
      end
   else: print,'ERROR in genrd: ',ninp,' inputs. 1-20 allowed'
   endcase
;
goto,done
;
misread: 
s=n_elements(i1)
if not keyword_Set(silent) then $
   print,' GENRD returning after reading',s,' records.'
;
done:
if doarr then begin
   np=n_elements(i1)/nn
   i1=reform(i1,nn,np)
   endif
if not keyword_set(noclose) then close,lu
if ifstring(file) then free_lun,lu
if keyword_set(stp) then stop,'GENRD>>>'
return
end
