function monvect,vect
case 1 of
   n_elements(vect) lt 2: begin
      print,' '
      print,'* Function MONVECT - test whether or not vector is monotonic'
      print,'*    Calling sequence: x=monvect(vector)'
      print,'*    x=1 (true) if vector is monotonic, false otherwise'
      print,'*       VECT: vector to be tested'
      print,' '
      return,0
      end
   n_elements(vect) eq 2: return,1   ;must be monotonic
   else: begin
      dv=vect(1:*)-vect
      kp=where(dv ge 0,np)
      km=where(dv le 0,nm)
      if (nm eq 0) or (np eq 0) then return,1 else return,0
      end
   endcase
return,0
end
