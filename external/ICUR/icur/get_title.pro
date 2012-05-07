;**************************************************************************
function get_title,h,inm
if n_elements(h) lt 3 then return,''
NCAM=H(3)
ZCAM='     LWP LWR SWP SWR '
case 1 of
   NCAM LE 4: begin
      if h(4) lt 0 then inm=h(4)+65536L else inm=h(4)
      TITLE=STRTRIM(STRMID(ZCAM,NCAM*4,4),2)+' '+ STRTRIM(inm,2)+' '
      end
   ncam/10 eq 10: BEGIN    ;GHRS
      if h(4) ne 0 then title='H'+strtrim(h(4),2)+' ' else title=''
      END
   ELSE: TITLE=''
   endcase
title=title+STRTRIM(BYTE(H(100:139)>32b),2)
return,title
end
