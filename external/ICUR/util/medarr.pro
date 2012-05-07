;*****************************************************************
function medarr,darr,stp=stp,helpme=helpme,fill=fill,low=low,high=high, $
   average=average,var=var,novar=novar
if n_elements(darr) le 1 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* MEDARR - return median of 2- or 3-dimensional array'
   print,'* calling sequence: m=MEDARR(array)'
   print,'* '
   print,'* array is concatenation of n arrays, of dimension (x,y,n)'
   print,'* KEYWORDS: 
   print,'*   NOVAR: if set, do not compute variance'
   print,'*   VAR: variance vector relative to median'
   print,'*    (the following are valid only for an even number of images)'
   print,'*    AVERAGE: (default) if set, use mean of indices n/2-1 and n/2'
   print,'*    HIGH: if set, median index of n files is n/2'
   print,'*    LOW:  if set, median index of n files is n/2-1'
   print,' '
   return,0
   endif
;
if not keyword_set(novar) then novar=0 else novar=1
s=size(darr)
med=0
ndim=s(0)
ylen=s(1)
nfiles=s(ndim)
iodd=nfiles mod 2
if keyword_set(average) then high=0
if iodd then medinx=(nfiles-1)/2 else case 1 of
   keyword_set(high): medinx=nfiles/2
   keyword_set(low): medinx=nfiles/2-1
   else: begin
      average=1
      medinx=nfiles/2-1
      end
   endcase
m1=medinx+1
if n_elements(fill) eq 1 then ifill=1 else ifill=0
case 1 of
   ndim eq 2: begin               ;vector
      med=fltarr(ylen)
      if not novar then var=fltarr(ylen)
      for i=0,ylen-1 do begin
         case 1 of
            iodd and not ifill: med(i)=median(darr(i,*))
            else: begin
               if ifill then begin
                  t=darr(i,*)
                  t=t(where(t ne fill,nt))
                  if nt eq 0 then begin
                     t=darr(i,j,*) & nt=nfiles
                     endif
                  vect=sort(t)
                  endif else vect=sort(darr(i,*))
               if keyword_set(average) then $
                  med(i)=(darr(i,vect(medinx))+darr(i,vect(m1)))/2. else $
                  med(i)=darr(i,vect(medinx))
               end
            endcase
         if not novar then $
            var(i)=sqrt(total((darr(i,*)-med(i))*(darr(i,*)-med(i)))/(nfiles))
         endfor   ;i
      end         ;ndim=2
;
   ndim eq 3: begin           ;array
      nord=s(2)
      med=fltarr(ylen,nord) & var=med
      case 1 of
         iodd and not ifill: for j=0,nord-1 do for i=0,ylen-1 do begin
               med(i,j)=median(darr(i,j,*))
               if not novar then var(i,j)=stddev(darr(i,j,*),/med)
               endfor
         ifill: for j=0,nord-1 do for i=0,ylen-1 do begin
            t=darr(i,j,*)
            k=where(t ne fill,nt)                 ;good points
            if nt eq 0 then begin    ; all fill data if nt=0
               med(i,j)=fill & if not novar then var(i,j)=0.
               endif else begin
               t=t(k) 
               vect=sort(t)    ; reset index in case of many fills
               mdx=(nt-1)/2
               mdx1=(mdx+1)<(nt-1)
               iodd1=nt mod 2
               if iodd1 then med(i,j)=t(vect(mdx)) else begin
                  if keyword_set(average) then $
                     med(i,j)=(t(vect(mdx))+t(vect(mdx1)))/2. else $
                     med(i,j)=t(vect(mdx))
                     endelse
               if not novar then $
                 if nt eq 0 then var(i,j)=0.0 else var(i,j)= $
                 sqrt(total((darr(i,j,k)-med(i,j))*(darr(i,j,k)-med(i,j)))/(nt))
               endelse
            endfor
         else: for j=0,nord-1 do for i=0,ylen-1 do begin    ;evens
            vect=sort(darr(i,j,*))
            if keyword_set(average) then $
               med(i,j)=(darr(i,j,vect(medinx))+darr(i,j,vect(m1)))/2. else $
               med(i,j)=(darr(i,j,vect(medinx)))
               if not novar then var(i,j)=stddev(darr(i,j,*),med(i,j))
            endfor
            endcase
         end
      else: print,' MEDARR: vector DARR must be 2 or 3 dimensions'
   endcase   ;ndim
if keyword_set(stp) then stop,'MEDARR>>>'
return,med
end
