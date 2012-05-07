;**************************************************************
pro figsym,i,fill,scale
if n_params(0) eq 0 then i=-1
if i eq -1 then begin
   print,' '
   print,'* FIGSYM - generate plottimg symbols (!PSYM=8)'
   print,'*    calling sequence: FIGSYM,I,FILL,SCALE
   print,'*       I:     1 generates T'
   print,'*              2 generates circle'
   print,'*              3 generates V'
   print,'*              4 generates <'
   print,'*              5 generates +'
   print,'*              6 generates X'
   print,'*              7 generates ^'
   print,'*              8 generates star'
   print,'*       FILL:  1 to fill in symbol.'
   print,'*       SCALE: size of symbol, default=1.'
   print,' '
   return
   end
if n_params(0) ge 3 then sc=scale else sc=1.
if n_params(0) eq 1 then fill=0
case 1 of
   i eq 1: begin        ;define symbol T for TTS
      xt=[-1,0,1,0,0]
      yt=[1,1,1,1,-1]
      end
   i eq 2: begin         ;draw circle
      x=findgen(31)/30.*2.*!pi
      xt=sin(x)
      yt=cos(x)
      end
   i eq 3: begin         ;V
      xt=[-1,0,1]
      yt=[2,0,2]
      end
   i eq 4: begin         ;sideways V
      xt=[2,0,2]
      yt=[1,0,-1]
      end
   i eq 5: begin        ;define symbol T for TTS
      xt=[-1,1,0,0,0]
      yt=[0,0,0,1,-1]
      end
   i eq 6: begin        ;define symbol T for TTS
      xt=[-1,1,0,-1,1]
      yt=[-1,1,0,1,-1]
      end
   i eq 7: begin         ;^
      xt=[-1,0,1]
      yt=[-2,0,-2]
      end
   i eq 8: begin
      xt=[0.,-0.23,-1.,-0.39,-0.67,0,0.67,0.39,1.,0.23,0.]
      yt=[1.,0.33,0.33,-0.16,-1.,-0.45,-1.,-0.16,0.33,0.33,1.]
      end
   i eq 9: begin
      xt=[0,-2,3.0,-3.0,2,0]/3.
      yt=[3,-3,1,1,-3,3]/3.
      end
   else: return
   endcase
if fill eq 0 then usersym,xt*sc,yt*sc else usersym,xt*sc,yt*sc,/fill
return
end
