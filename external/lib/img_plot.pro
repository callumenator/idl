pro img_plot,img_in,title,xtitle,ytitle,xr,yr,color=color,zrange=zrange, $
             big=big,time_axe=tax, noerase=noerase, data_range=data_range, $
             units=zun, format=fmt, thick=thikk, data_label_range=dlb, $
			 tick_color = tickle
			 

if (NOT(keyword_set(color)))      then color = 0
if (NOT(keyword_set(zrange)))     then zrange = [0,!d.n_colors-1]
if (not(keyword_set(data_range))) then data_range = [min(img_in), max(img_in)]
if (not(keyword_set(zun)))        then zun = ' '
if (not(keyword_set(fmt)))        then fmt = 'g14.4 '

    px = !x.window * !d.x_vsize
    py = !y.window * !d.y_vsize
    sx = px(1) - px(0) + 1
    sy = py(1) - py(0) + 1
    xx = [min(xr),max(xr)]
    yy = [min(yr),max(yr)]
    img = img_in
    x_style = 1
    if keyword_set(tax) then x_style=5
    charsize=1
    charthick=1
    thick=2
    if keyword_set(big) then begin
       charsize = big
       if big gt 1.3 then begin
          charthick=2
          thick=2
       endif
    endif
    if ((keyword_set(thikk)))      then begin
	    thick = thikk
		charthick = thikk
    endif
    plot, xx, yy, /nodata, title=title, noerase=noerase, $
          xtitle=xtitle, xrange=xr, $
          ytitle=ytitle, yrange=yr, $
          xstyle=x_style, /ystyle, $
          color=color, $
          ymargin=[4,4], xmargin=[10,9], $
          thick=thick, xthick=thick, ythick=thick, charsize=charsize, charthick=charthick

    px  = !x.window * !d.x_vsize
    py  = !y.window * !d.y_vsize
    sx  = px(1) - px(0) + 1
    sy  = py(1) - py(0) + 1
    dtx = total(px)/2
    dty = py(0)/3
    rhy = convert_coord(px(1), total(py)/2, /device, /to_normal)
    rh1 = rhy(0) + 0.38*(1 - rhy(0))
    rh2 = rhy(0) + 0.62*(1 - rhy(0))

    img = congrid(img_in, sx, sy, /cubic)
    img = bytscl(img, top=zrange(1)-zrange(0), min=data_range(0), max=data_range(1)) + zrange(0)
    tv,  img, px(0), py(0)

    if not(keyword_set(dlb)) then color_labz = data_range else color_labz = dlb
    mccolbar, [rh1,0.4,rh2,0.7], zrange(0), zrange(1), color_labz(0), color_labz(1), $
               color=color,charsize=big, form=fmt, units=zun, thick=thick
    if not(keyword_set(tickle)) then tickle = color
    plot, xx, yy, /nodata, /noerase, $
          xrange=xr, $
          yrange=yr, $
          xstyle=x_style, /ystyle, $
          color=tickle, $
          ymargin=[4,4], xmargin=[10,9], $
          thick=thick,  xthick=thick, ythick=thick, charsize=charsize, charthick=charthick
    plot, xx, yy, /nodata, title=title, /noerase, $
          xtitle=xtitle, xrange=xr, $
          ytitle=ytitle, yrange=yr, $
          xstyle=x_style, /ystyle, $
          color=color, $
          ymargin=[4,4], xmargin=[10,9], $
          thick=thick,  xthick=thick, ythick=thick, charsize=charsize, charthick=charthick, $
		  xticklen=0.001, yticklen=0.001
          
    if keyword_set(tax) then begin
       timeaxis, jd=js2jd(0l)+1, form='h$:m$', $
                 charsize=charsize, charthick=charthick, color=color, thick=thick
       datestr = 'Start date ' + dt_tm_mk(js2jd(0l)+1, xx(0), format='d$-n$-Y$') 
       xyouts, dtx, dty, datestr, /device, align=0.5, $
               charsize=charsize, charthick=charthick, color=color
     endif
     
end
