xx = dialog_pickfile(path='d:\users\conde\main\idl\lib', filter='*.dat', title='Select a MAPGEN data file:')

openr, mapun, xx, /get_lun
oneline  = 'dummy'
newcurve = 1
void     = 1
while not(eof(mapun)) do begin
      readf, mapun, oneline
      if strpos(oneline, '#') ge 0 then newcurve = 1 else begin
         oneline  = strcompress(oneline)
         vals     = str_sep(oneline, ' ')
         lon      = float(vals(0))
         lat      = float(vals(1))
         newf     = newcurve
         newcurve = 0
         if void then begin
            coastcurves = [lon, lat]
            newflags    = byte(newf)
         endif else begin
            coastcurves = [[[coastcurves]], [[lon, lat]]]
            newflags    = [newflags, newf]
         endelse
         void = 0
      endelse
endwhile
close, mapun
free_lun, mapun
end
         