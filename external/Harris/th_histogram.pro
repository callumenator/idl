function hist,y,binsize=binsize,miny=miny,maxy=maxy,x=x

;The in-built histogram routine in IDL does not produce consistent binning
;given an arbitrary binsize and/or max/min keywords. In other words, if you
;randomly choose your binsize and try to predict the number of histogram bins
;resulting you'll (or rather, it will!) get it wrong every now and then.
;New histogram routine follows.
;
; B.Vandepeer	24-Feb-1995	Atmos. Physics Group, University of Adelaide
;
;
  if n_elements(binsize) eq 0 $
     then $
       binsize = 1.
  if n_elements(miny) eq 0 $
     then $
       miny = min(y)
  if n_elements(maxy) eq 0 $
     then $
       maxy = max(y)
  n = rnd((maxy-miny)/binsize,1,/up)+1
  h = intarr(n)
  x = findgen(n)/(n-1)*(maxy-miny) + miny
  for i = 0,n-1 do begin
    l = miny + (-.5+i)*binsize
    u = miny + (+.5+i)*binsize
    a = where((y gt l) and (y le u),count)
    h(i) = count > 0
  endfor
  return,h
end

