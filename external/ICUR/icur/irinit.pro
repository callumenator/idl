;**********************************************************
pro irinit,wave,out
COMMON COMXY,XCUR,YCUR,zerr
out=1
iredo=1
print,' H for help, type 1 when OK'
while iredo eq 1 do begin
   BLOWUP,-1
   iredo=-1
   case 1 of
      ZERR EQ 48: setlam,wave                   ;<0>  set wavelength
      ZERR EQ 49: out=2                         ;<1>  display OK
      ZERR EQ 50: SETXY,!X.range(0),!X.range(1) ;<2>  auto Y scaling
      (ZERR EQ 65) or (zerr eq 97): SETXY       ;<A>  auto scaling
      (ZERR EQ 72) OR (ZERR EQ 104): BEGIN      ;<H>  HELP
         PRINT,' Available Commands:'
         print,' 0: enter central wavelength'
         print,' 1: plot limits OK'
         print,' 2: Autoscale Y axis'
         print,' A: Autoscale both axes'
         print,' H: print this message'
         print,' J: Jump in wavelength'
         print,' Z: stop'
         print,' other: mark new plot corners'
         iredo=1
         end
      (ZERR EQ 74) OR (ZERR EQ 106): JUMP       ;<J>  jump
      (ZERR EQ 90) OR (ZERR EQ 122): STOP       ;<Z>
      (ZERR GT 128) OR (ZERR LT 0): ZRECOVER    ;OUT OF BOUNDS    
      else: begin
         x1=xcur & y1=ycur
         print,' mark other corner'
         blowup,-1                            ;FULL BLOWUP
         !x.range=[x1<xcur,x1>xcur]
         !Y.RANGE=[y1<ycur,y1>ycur]
         end
      endcase
   endwhile
return
end
