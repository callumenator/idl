   function getspot, rad, phase, yval, cen
      xrd = rad + yval
      return, cen + xrd*[sin(phase), cos(phase)]
   end

   pro spiroplt, x, y, period, pitch, yscale, phaseref, $
       title = ti, $
       tithick = ttk, $
       ticolor = ticul, $
       tifont = tifon, $
       baseline = bl, $
       major_ticks = majtix, $
       minor_ticks = mintix, $
       ticklab = tlab, $
       data_color = datcul, $
       axis_color = axecul, $
       ylab = ylb, $
       ybar = yb, $
       ygrid = yg, $
       spirogrid = sg, $
       gridcolor = gc, $
       yzero = yz, $
       units = unts, $
       gap_angle = gapang, $
       label_invert = labinv, $
       timestamp = tst, $
       ythick = ytk, $
       period=perlab, $
       cal_bar = cal_bar, $
       tick_lab_step = tick_lab_step, $
       data_ctable = data_ctable, $
       no_bar_outline = no_bar_outline

	if not keyword_set(tick_lab_step) then tick_lab_step = 1

   if n_elements(datcul) eq 0       then datcul = 0.25*!d.n_colors
   if n_elements(datcul) lt 2       then datcul = [datcul,datcul]
   if not(keyword_set(gc))          then gc     = 0.3*!d.n_colors
;  if not(keyword_set(axecul))      then axecul = 0.25*!d.n_colors
   if not(keyword_set(yz))          then yz = 0
   if not(keyword_set(gapang))      then gapang = 5.*!pi/180.
   if not(keyword_set(tst))         then    tst = 1 else tst  = 0
   if not(keyword_set(perlab))      then   perl = 0 else perl = 1
   if not(keyword_set(ytk))         then ytk    = 2
   if not(keyword_set(labinv))      then labinv = 0
   if not(keyword_set(ttk))         then ttk = 1
   if not(keyword_set(ticul))       then ticul = 0
   if not(keyword_set(tifon))       then tifon = 3

;  This routine plots time-series data in a polar spiral.

   box    = convert_coord(.999, .98, /normal, /to_device)
   pix    = min(box(0:1))
   cen    = [pix/1.98, pix/2.05]

   period = float(period)
   tz = min(x)

   if keyword_set(mintix) then tz = min([tz, mintix])
   if keyword_set(majtix) then tz = min([tz, majtix])

   npts  = n_elements(y)
   laps  = (x(npts-1) - tz)/period
   y2pix = pix/2*pitch/yscale

   phaseref = phaseref*!pi/180.
   if phaseref ge 0 then lophase = phaseref else lophase = abs(phaseref) - 2*!pi*laps
   lorad  = (pix/2)*(1 - pitch*(laps + 1))

   tz = min(x)
   if keyword_set(mintix) then tz = min([tz, mintix])
   if keyword_set(majtix) then tz = min([tz, majtix])

   if keyword_set(sg) then begin
   	loadct, 0, /silent
      for k=1,sg do begin
          nbl  = 180.*laps
          spot = getspot(lorad + (float(k)/sg)*yscale*y2pix, lophase, 0., cen)
          plots, spot, /device

          for j=1,nbl-1 do begin
              dx    = (x(npts-1) - tz)*float(j)/float(nbl-1)
              phase = lophase + 2*!pi*dx/period
              rad   = lorad   +  pix/2*pitch*dx/period + (float(k)/sg)*yscale*y2pix
              spot  = getspot(rad, phase, 0., cen)
              plots, spot, /continue, /device, color=gc
          endfor
      endfor
   endif

;  This loop plots the data:
	if size(data_ctable, /type) ne 0 then loadct, data_ctable, /silent
   phase = lophase + 2*!pi*(x(0) - tz)/period
   rad   = lorad   +  pix/2*pitch*(x(0) - tz)/period
   spot  = getspot(rad, phase, (y(0)-yz)*y2pix, cen)
   plots, spot, /device
   oldphase = lophase
   for j=1l,npts-1 do begin
       phase = lophase + 2*!pi*(x(j) - tz)/period
       pointcul = datcul(0) + (datcul(1) - datcul(0))*(x(j) - tz)/(period*laps)
       ctx   = 1
       if phase - oldphase gt gapang then ctx = 0
       rad   = lorad   +  pix/2*pitch*(x(j) - tz)/period
       spot  = getspot(rad, phase, (y(j)-yz)*y2pix, cen)

       	if keyword_set(cal_bar) then begin
			pre_lo = getspot(rad, oldphase, (0-yz)*y2pix, cen)
			pre_hi = getspot(rad, oldphase, (y[j]-yz)*y2pix, cen)
			new_lo = getspot(rad, phase, (0-yz)*y2pix, cen)
			new_hi = getspot(rad, phase, (y[j]-yz)*y2pix, cen)

       		polyfill, /device, [pre_lo[0],pre_hi[0],new_hi[0],new_lo[0]], $
       						   [pre_lo[1],pre_hi[1],new_hi[1],new_lo[1]], $
								color=pointcul

			if not keyword_set(no_bar_outline) then $
				plots, /device, [pre_lo[0],pre_hi[0],new_hi[0],new_lo[0]], $
       						   [pre_lo[1],pre_hi[1],new_hi[1],new_lo[1]], color=0

		endif else begin
			plots, spot, continue=ctx, /device, color=pointcul, thick=ytk
		endelse

       oldphase = phase
   endfor

	loadct, 0, /silent
   if keyword_set(mintix) then begin
      for j=0, n_elements(mintix)-1 do begin
          phase = lophase + 2*!pi*(mintix(j) - tz)/period
          rad   = lorad   + pix/2*pitch*(mintix(j) - tz)/period
          spot  = getspot(rad, phase, -pitch*pix/25., cen)
          plots, spot, /device, color=axecul
          spot  = getspot(rad, phase, pitch*pix/25., cen)
          plots, spot, /device, color=axecul, /continue
      endfor
   endif

   if keyword_set(majtix) then begin
      for j=0, n_elements(majtix)-1 do begin
          phase = lophase + 2*!pi*(majtix(j) - tz)/period
          rad   = lorad   + pix/2*pitch*(majtix(j) - tz)/period
          spot  = getspot(rad, phase, 0., cen)
          if  keyword_set(yg) and (yg gt 0 or j eq n_elements(majtix)-1) then begin
              ygg  = abs(yg)
              spt2 = getspot(rad + yscale*y2pix, phase, 0., cen)
              plots, [spot(0), spot(1)], /device, color=gc
              plots, [spt2(0), spt2(1)], /device, color=gc, /continue, thick=1
              for k=1,ygg do begin
                  spt3 = getspot(rad + (float(k)/ygg)*yscale*y2pix, phase - .5*!pi/180, 0., cen)
                  spt4 = getspot(rad + (float(k)/ygg)*yscale*y2pix, phase + .5*!pi/180, 0., cen)
                  plots, [spt3(0), spt3(1)], /device, color=gc
                  plots, [spt4(0), spt4(1)], /device, color=gc, /continue, thick=1
              endfor
              spt3 = getspot(rad + yscale*y2pix, phase - 1.*!pi/180, 0., cen)
              spt4 = getspot(rad + yscale*y2pix, phase + 1.*!pi/180, 0., cen)
              plots, [spt3(0), spt3(1)], /device, color=gc
              plots, [spt4(0), spt4(1)], /device, color=gc, /continue, thick=1
          endif
          spot  = getspot(rad, phase, -pitch*pix/15., cen)
          plots, spot, /device, color=axecul
          spot  = getspot(rad, phase, pitch*pix/15., cen)
          plots, spot, /device, color=axecul, /continue
      endfor
   endif

   if keyword_set(tlab) then begin
      for j=0, n_elements(majtix)-1, tick_lab_step do begin
          yoff  = -pitch*pix/4
          phase = lophase + 2*!pi*(majtix(j) - tz)/period
          pang  = atan(sin(phase), cos(phase))
          pang  = -180.*pang/!pi
          if (pang lt -90 or pang gt 90) and labinv then begin
             pang = pang + 180
             yoff = yoff/2
          endif
          rad   = lorad   + pix/2*pitch*(majtix(j) - tz)/period
          spot  = getspot(rad, phase, yoff, cen)
          xyouts, spot(0), spot(1), tlab(j), align=0.5, color=axecul, orientation=pang, /device
      endfor
   endif

   if keyword_set(bl) then begin
      nbl  = 180.*laps
      spot = getspot(lorad, lophase, 0., cen)
      plots, spot, /device

      for j=1,nbl-1 do begin
          dx    = (x(npts-1) - tz)*float(j)/float(nbl-1)
          phase = lophase + 2*!pi*dx/period
          rad   = lorad   +  pix/2*pitch*dx/period
          spot  = getspot(rad, phase, 0., cen)
          plots, spot, /continue, /device, color=axecul
      endfor
   endif

   if keyword_set(ti) then begin
          fnt = '!' + strcompress(string(tifon), /remove_all)
          xyouts, cen(0), cen(1) + (pix/2)*1.0*pitch, fnt + ti + '!3', $
                  align=0.5, color=ticul, /device, charsize=2.0, charthick=ttk
   endif

   if keyword_set(yb) then begin
          plots, [cen(0)-pix/30, cen(1) - pix/2*0.5*pitch], /device, color=axecul
          plots, [cen(0)-pix/30, cen(1) - pix/2*0.5*pitch - yscale*y2pix], /device, color=axecul, /continue, thick=2
          plots, [cen(0)-pix/30 - pix/80, cen(1) - pix/2*0.5*pitch], /device, color=axecul
          plots, [cen(0)-pix/30 + pix/80, cen(1) - pix/2*0.5*pitch], /device, color=axecul, /continue, thick=2
          plots, [cen(0)-pix/30 - pix/80, cen(1) - pix/2*0.5*pitch - yscale*y2pix], /device, color=axecul
          plots, [cen(0)-pix/30 + pix/80, cen(1) - pix/2*0.5*pitch - yscale*y2pix], /device, color=axecul, /continue, thick=2
          legend = string(fix(yz)) + " "
          if keyword_set(unts) then legend = legend + unts
          legend = strtrim(legend, 2)
          xyouts, cen(0), cen(1) - pix/2*0.5*pitch - yscale*y2pix, legend, align=0, color=axecul, /device, charsize=1
          legend = string(fix(yz+yscale)) + " "
          if keyword_set(unts) then legend = legend + unts
          legend = strtrim(legend, 2)
          xyouts, cen(0), cen(1) - pix/2*0.5*pitch, legend, align=0, color=axecul, /device, charsize=1
   endif

   if tst gt 0 then begin
      stm = systime()
      cln = strpos(stm, ':')
      lbl = 'Condegram plotted ' + strmid(stm, 4, 6) + ' at ' + strmid(stm, cln-2, 5) + ' UT'
      ;xyouts, box(0)-5, 5, lbl, align=1, color=axecul, /device, charsize=0.8
      lbl = 'GI-UAF ' + strmid(stm, cln+7, 4)
      ;xyouts, 5, 5, lbl, align=0, color=axecul, /device, charsize=0.8
   endif

   if perl gt 0 then begin
      xyouts, box(0)-5, box(1) - 10, perlab, align=1, color=axecul, /device, charsize=0.8
   endif

  end
