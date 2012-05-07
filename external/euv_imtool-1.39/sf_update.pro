
; ======================================================================
; last updated: 21-Jun-2005
; ======================================================================

; ------------------------------------------
; doplot - plot a single index
; ------------------------------------------
pro doplot, x, y, c, xrange, xtickname, yrange, desc, ylog
  @sf_common
  xrange1 = xrange
  if(x eq [-1]) then begin
    xrange1 = [0, 1]
    yrange = [-1, 1]
  endif else if((not keyword_set(yrange)) or sfmode eq 1) then begin
    ymin = min(y)
    ymax = max(y)
    ydiff = ymax - ymin
    ymin = ymin - ydiff * 0.05
    ymax = ymax + ydiff * 0.05  
    yrange = [ymin, ymax]
  endif
  ydiff = yrange[1] - yrange[0]
  xdiff = xrange1[1] - xrange1[0]
    
  if(keyword_set(ylog)) then begin
    plot, [0], [0], xticks = 4, xtickname = xtickname, xstyle = 1, xrange = xrange1, charsize = 2, xminor = 12, xmargin=[6, 6], ystyle = 1, yrange = yrange, /nodata, ymargin=[2.5, 0.5], /ylog
  endif else begin
    plot, [0], [0], xticks = 4, xtickname = xtickname, xstyle = 1, xrange = xrange1, charsize = 2, xminor = 12, xmargin=[6, 6], ystyle = 1, yrange = yrange, /nodata, ymargin=[2.5, 0.5]
  endelse
  
  oplot, mean(xrange1) * [1, 1], yrange, color = '555555'XUL
  oplot, xrange1, [0, 0], color = '999999'XUL 
  if(x ne [-1]) then begin
    oplot, x, y, color = c
  endif
    
  th = 0.015
  
  xyouts, xrange1[0] + xdiff * (0.030 + th), yrange[0] + ydiff * 0.025, desc, /data
  polyfill, xrange1[0] + xdiff * [0.025, 0.025, 0.025 + th, 0.025 + th], yrange[0] + ydiff * [0.025, 0.025 + th * 4, 0.025 + th * 4, 0.025], color = c, /data
end

; ------------------------------------------
; doplot2 - plot 2 indices with same Y scale
; ------------------------------------------
pro doplot2, x, y0, y1, c0, c1, xrange, xtickname, yrange, desc0, desc1
  @sf_common
  xrange1 = xrange
  if x eq [-1] then begin
      xrange1 = [0, 1]
      yrange = [-1, 1]
  endif else if((not keyword_set(yrange)) or sfmode eq 1) then begin
      ymin = min(y0) < min(y1)
      ymax = max(y0) > max(y1)
      ydiff = ymax - ymin
      ymin = ymin - ydiff * 0.05
      ymax = ymax + ydiff * 0.05  
      yrange = [ymin, ymax]
  endif
  xdiff = xrange1[1] - xrange1[0]
  ydiff = yrange[1] - yrange[0]

  th = 0.015
  
  plot, [0], [0], xticks = 4, xtickname = xtickname, xstyle = 1, xrange = xrange1, charsize = 2, xminor = 12, xmargin=[6, 6], ystyle = 1, yrange = yrange, /nodata, ymargin=[2.5, 0.5]
  oplot, mean(xrange1) * [1, 1], yrange, color = '555555'XUL
  oplot, xrange1, [0, 0], color = '999999'XUL 
  if(x ne [-1]) then begin
      oplot, x, y0, color = c0
      oplot, x, y1, color = c1
  endif
  xyouts, xrange1[0] + xdiff * (0.030 + th), yrange[0] + ydiff * (0.025 + 0.10), desc0, /data
  polyfill, xrange1[0] + xdiff * [0.025, 0.025, 0.025 + th, 0.025 + th], yrange[0] + ydiff * ([0.025, 0.025 + th * 4, 0.025 + th * 4, 0.025] + 0.10), color = c0, /data
  xyouts, xrange1[0] + xdiff * (0.030 + th), yrange[0] + ydiff * 0.025, desc1, /data
  polyfill, xrange1[0] + xdiff * [0.025, 0.025, 0.025 + th, 0.025 + th], yrange[0] + ydiff * [0.025, 0.025 + th * 4, 0.025 + th * 4, 0.025], color = c1, /data
end


; --------------------------------------------------
; doplot2m - plot 2 indices with differing Y scales
; --------------------------------------------------
pro doplot2m, x, y0, y1, c0, c1, xrange, xtickname, y0range, y1range, desc0, desc1
  @sf_common
  xrange1 = xrange
  if x eq [-1] then begin
      xrange1 = [0, 1]
      yrange = [-1, 1]
  endif else if((not keyword_set(y0range)) or sfmode eq 1) then begin
      ymin = min(y0)
      ymax = max(y0)
      ydiff = ymax - ymin
      ymin = ymin - ydiff * 0.05
      ymax = ymax + ydiff * 0.05  
      y0range = [ymin, ymax]
      ymin = min(y1)
      ymax = max(y1)
      ydiff = ymax - ymin
      ymin = ymin - ydiff * 0.05
      ymax = ymax + ydiff * 0.05  
      y1range = [ymin, ymax]
  endif
  xdiff = xrange1[1] - xrange1[0]
  y0diff = y0range[1] - y0range[0]
  y1diff = y1range[1] - y1range[0]

  th = 0.015
  
  plot, [0], [0], xticks = 4, xtickname = xtickname, xstyle = 1, xrange = xrange1, charsize = 2, xminor = 12, xmargin=[6, 6], ystyle = 8+1, yrange = y0range, /nodata, ymargin=[2.5, 0.5]
  oplot, mean(xrange1) * [1, 1], y0range, color = '555555'XUL
  oplot, xrange1, [0, 0], color = '999999'XUL 
  if(x ne [-1]) then begin
      oplot, x, y0, color = c0
      xyouts, xrange1[0] + xdiff * (0.030 + th), y0range[0] + y0diff * 0.025, desc0, /data
      polyfill, xrange1[0] + xdiff * [0.025, 0.025, 0.025 + th, 0.025 + th],$
        y0range[0] + y0diff * ([0.025, 0.025 + th * 4, 0.025 + th * 4, 0.025]), color = c0, /data
      axis, xrange1[1], /yaxis,yrange=y1range,/save,color=c1,charsize=2,ystyle=1
      oplot, x, y1, color = c1
      oplot, xrange1, [0, 0], color = c1
  endif

  xback = 0.075
  xyouts, xrange1[1] - xdiff * (xback -0.01), y1range[0] + y1diff * 0.025, desc1, /data, color=c1
  polyfill, xrange1[1] - xdiff * [xback, xback, xback + th, xback + th], y1range[0] + y1diff * [0.025, 0.025 + th * 4, 0.025 + th * 4, 0.025], color = c1, /data
end


; ----------------------------------------------------------------
; sf_update  - update the solarwind, Kp, Dst, etc. plot
; ----------------------------------------------------------------
pro sf_update, time
  @sf_common

;;  if(not sfloaded) then sf_load
;;  if(sfunavailable) then return
  
; ------------------------
; get sizes of data arrays
; ------------------------
  n = size(solarfluxdata)		
  n = n[2]
  nkp = size(kpdata)		
  nkp = nkp[2]
  ndst = size(dstdata)		
  ndst = ndst[2]
  
; ----------------------
; set up the plot window
; ----------------------
  wset, sf_hdraw
  !p.multi = [0, 1, 6]

  mid_jd = julday(1, strmid(time, 5, 3), strmid(time, 0, 4), $
                  strmid(time, 9, 2), strmid(time, 12, 2))

  xrange = [mid_jd - sftimespan, mid_jd + sftimespan]
  xtickname = strmid([jd2string(mid_jd-1*sftimespan), jd2string(mid_jd-0.5*sftimespan), time, jd2string(mid_jd+0.5*sftimespan), jd2string(mid_jd+1*sftimespan)], 5)

; ----------------------  
; ACE data plots
; ----------------------
  indices = where(solarfluxdata[0, 0:(n-1)] gt mid_jd - sftimespan*1.1 and solarfluxdata[0, 0:(n-1)] lt mid_jd + sftimespan*1.1)

  if(indices eq [-1]) then begin
      x = [-1]
  endif else begin
      usefuldata = solarfluxdata[0:6, [[indices]]]
      nu = size(usefuldata)
      nu = nu[2]

      x = usefuldata[0, 0:(nu - 1)]
      b = usefuldata[1, 0:(nu - 1)]
      bx = usefuldata[2, 0:(nu - 1)]
      by = usefuldata[3, 0:(nu - 1)]
      bz = usefuldata[4, 0:(nu - 1)]
      speed = usefuldata[5, 0:(nu - 1)]
      pressure = usefuldata[6, 0:(nu - 1)]

; filter out bad data (where speed = 9999.99)
      indices2 = where(speed lt 9999.0)
      speed = speed[indices2]
      pressure = pressure[indices2]

      vbz = speed * bz * .001

  endelse

  doplot2, x, bz, b, '0000ff'XUL, 'ffffff'XUL, xrange, xtickname, [-30, 30], 'bz', 'b (nT)'
  doplot2, x, bx, by, 'ff00ff'XUL, '00ff00'XUL, xrange, xtickname, [-30, 30], 'bx', 'by'
  doplot2m, x, pressure, vbz, 'ffffff'XUL, '00ffff'XUL, xrange, xtickname, [-3, 30], [-10,10], 'P (nPa)', 'VBz (mV/m)'
  

; -------------------------------------
; N and V (number density and velocity)
; -------------------------------------
  v = speed
  m = pressure / (speed ^ 2.0D * 1.67D * 10.0D ^ (-6.0D)) ; m is really n (number density)
  doplot2m, x, m, v < 9000.0, 'ffff00'XUL, '00ff00'XUL, xrange, xtickname, [0, 30], [0, 1000], 'n (#/cc)', 'v (km/s)'

; ----------------------
; Kp plot
; ----------------------
  indices = where(kpdata[0, 0:nkp-1] gt mid_jd-sftimespan*1.5 and kpdata[0, 0:nkp-1] lt mid_jd+sftimespan*1.5)
  if(indices eq [-1]) then begin
      x = [-1]
  endif else begin   
      usefuldata = kpdata[0:1, [[indices]]]
      nu = size(usefuldata)
      nu = nu[2]
      x = usefuldata[0, 0:(nu - 1)]
      kp = usefuldata[1, 0:(nu - 1)]
  endelse

  doplot, x, kp, 'ffccff'XUL, xrange, xtickname, [0, 10], 'KP'
  
; ----------------------
; Dst plot
; ----------------------
  indices = where(dstdata[0, 0:ndst-1] gt mid_jd-sftimespan*1.5 and dstdata[0, 0:ndst-1] lt mid_jd+sftimespan*1.5)
  if(indices eq [-1]) then begin
      x = [-1]
  endif else begin   
      usefuldata = dstdata[0:1, [[indices]]]
      nu = size(usefuldata)
      nu = nu[2]
      x = usefuldata[0, 0:(nu - 1)]
      dst = usefuldata[1, 0:(nu - 1)]
  endelse
  doplot, x, dst, 'ffffcc'XUL, xrange, xtickname, [-200, 100], 'DST'

  sflasttime = time
end
