;  a program for reading vertical wind data files, and plotting
;  the data, and perhaps lombing...
;  M.P.K., 05/00

;  the main program...

common vert_wind_obs, v_times, v_winds, v_wind_err, v_intnst, v_intnst_err

load_mycolor
!p.font=1

!p.multi = [0,0,2,0,0]

date = ''
print,''
print, 'enter the date of the vertical wind file to be opened and read'
print, 'YYMMDD format'
print,''
read, date

month=''
year=''
mnthval=strmid(date,2,2)
pieceofdate=strmid(date,3,3)
yr=strmid(date,0,2)
if yr eq '01' then year='2001'
if yr eq '00' then year='2000'
if yr eq '99' then year='1999'
day=strmid(date,4,2)
;if fix(day) lt 10 then day=strmid(day,1,1)

if fix(mnthval) lt 10 then mnth = strmid(mnthval,1,1)
if mnthval eq '10' then mnth = 'A'
if mnthval eq '11' then mnth = 'B'
if mnthval eq '12' then mnth = 'C'

if (mnthval eq '01') then month='Jan'
if (mnthval eq '02') then month='Feb'
if (mnthval eq '03') then month='Mar'
if (mnthval eq '04') then month='Apr'
if (mnthval eq '05') then month='May'
if (mnthval eq '06') then month='Jun'
if (mnthval eq '07') then month='Jul'
if (mnthval eq '08') then month='Aug'
if (mnthval eq '09') then month='Sep'
if (mnthval eq '10') then month='Oct'
if (mnthval eq '11') then month='Nov'
if (mnthval eq '12') then month='Dec'

dpath = 'f:\users\mpkryn\windows\ivk_wnd_anlys\datafiles\'+year+'\ascfiles\vertdata\'
datfile = dpath+'ikvrt'+mnth+day+'.dbt'


g=0
openr,unit,datfile,/get_lun
while (not eof(unit)) do begin
; if g eq 36 then begin
;  readf,unit,format='(2i6,2i8,2f8.2)',d1,d2,d3,d4,d5,d6
;  goto,skippy
; endif
 readf,unit,format='(2i6,2i8,2f8.2,4f8.1)',d1,d2,d3,d4,d5,d6,d7,d8,d9,d10
; skippy:
 g=g+1
endwhile

close,unit
free_lun,unit

size = g
znthtimes = fltarr(size)
znthwnd = fltarr(size)
znthwnderr = fltarr(size)
znthintnst = fltarr(size)
znthintnsterr = fltarr(size)
elevarr = intarr(size)
azmtharr = intarr(size)

g=0
openr,unit,datfile,/get_lun
while (not eof(unit)) do begin
; if g eq 36 then begin
;  readf,unit,format='(2i6,2i8,2f8.2)',d1,d2,d3,d4,d5,d6
;  goto,slime
; endif
 readf,unit,format='(2i6,2i8,2f8.2,4f8.1)',d1,d2,d3,d4,d5,d6,d7,d8,d9,d10
; slime:
 znthtimes(g) = d2/100.
 znthwnd(g) = d5
 znthwnderr(g) = d6
 znthintnst(g) = d9
 znthintnsterr(g) = d10
 elevarr(g) = d4
 azmtharr(g) = d5
 g=g+1
endwhile

close,unit
free_lun,unit


v_times = znthtimes
v_winds = znthwnd
v_wind_err = znthwnderr
v_intnst = znthintnst
v_intnst_err = znthintnsterr

rel_intnst = v_intnst / 10000.

v_title = 'Inuvik, NWT, Canada, '+month+' '+day+', '+year+'!C!C'+$
          'Vertical Winds in the Upper Thermosphere'
		  
intnst_title = '630 nm Relative Intensity!C'

if max(rel_intnst) le 10. then Maxxiss = 10.
if max(rel_intnst) gt 10. and max(rel_intnst) le 20. then Maxxiss = 20.
if max(rel_intnst) gt 20. and max(rel_intnst) le 30. then Maxxiss = 30.
if max(rel_intnst) gt 30. and max(rel_intnst) le 40. then Maxxiss = 40.

;maxxiss=10.

;v_time_range = [1., 17.]
v_time_range = [2., 16.]
v_time_range = [0., 18.]
;thetickrange = [1,3,5,7,9,11,13,15,17] & tick_amnt = n_elements(thetickrange)-1
;thetickrange = [2,4,6,8,10,12,14,16] & tick_amnt = n_elements(thetickrange)-1
thetickrange = [0,2,4,6,8,10,12,14,16,18] & tick_amnt = n_elements(thetickrange)-1

window,/free,retain=2,xsize=700,ysize=800

device,set_font='Helvetica Bold',/tt_font

plot, v_times,v_winds,psym=4, title = v_title,$
	ytitle='Vertical wind speed (m/s)',xtitle='Time, UT',$
	charsize=1.5, yrange=[-100,100],/ystyle,xrange = v_time_range,/xstyle,$
	pos=[0.15,0.57,0.9,0.85],xthick=2.,ythick=2.,xtickv = thetickrange,$
	xminor=4,symsize=0.9,xticks = tick_amnt,xgridstyle=1,ygridstyle=1,$
	xticklen=1.0,yticklen=1.0,yminor=5
oplot, v_times,v_winds
errplot, v_times,v_winds-v_wind_err, v_winds+v_wind_err

plot, v_times,rel_intnst,psym=4, title = intnst_title,$
	ytitle='Normalized Intensity',xtitle='Time, UT',$
	charsize=1.5, yrange=[0.,Maxxiss],/ystyle,xrange = v_time_range,/xstyle,$
	pos=[0.15,0.15,0.9,0.43],xthick=2.,ythick=2.,xtickv = thetickrange,$
	xminor=4,symsize=0.9,xticks = tick_amnt,xgridstyle=1,ygridstyle=1,$
	xticklen=1.0,yticklen=1.0,yminor=2
oplot, v_times,rel_intnst


decision=''
print,''
print, "save as postscript?  y/n"
print,''
read,decision
if (decision ne 'y') then goto, dummy4
print,''
 !p.font=0
 set_plot,'ps'
 load_mycolor
 psfilename = 'f:\users\mpkryn\windows\ivk_wnd_anlys\datafiles\'+year+'\v_wind_intnst'+date+'.ps'
 
 device,filename=psfilename,/helvetica,/bold,/inches,$
   font_size=10,bits=8,xoffset=0.75,xsize=7.,yoffset=1.5,ysize=8.,$
   /color
   
 plot, v_times,v_winds,psym=4, title = v_title,$
	ytitle='Vertical wind speed (m/s)',xtitle='Time, UT',$
	charsize=1.5, yrange=[-100,100],/ystyle,xrange = v_time_range,/xstyle,$
	pos=[0.1,0.58,0.9,0.97],xthick=2.,ythick=2.,xtickv = thetickrange,$
	xminor=4,symsize=1.,xticks = tick_amnt, xgridstyle=1,ygridstyle=1,$
	xticklen=1.0,yticklen=1.0,yminor=5
 oplot, v_times,v_winds
 errplot, v_times,v_winds-v_wind_err, v_winds+v_wind_err
 plot, v_times,rel_intnst,psym=4, title = intnst_title,$
 	ytitle='Normalized Intensity',xtitle='Time, UT',$
 	charsize=1.5, yrange=[0.,Maxxiss],/ystyle,xrange = v_time_range,/xstyle,$
 	pos=[0.1,0.,0.9,0.39],xthick=2.,ythick=2.,xtickv = thetickrange,$
 	xminor=4,symsize=0.9,xticks = tick_amnt,xgridstyle=1,ygridstyle=1,$
 	xticklen=1.0,yticklen=1.0,yminor=2
 oplot, v_times,rel_intnst

device,/close
set_plot,'win'
!p.font=1

dummy4:

;window,/free,retain=2,xsize=900,ysize=700

;device,set_font='Helvetica Bold',/tt_font
;plot, v_times,rel_intnst,psym=4, title = intnst_title,$
;	ytitle='Normalized Intensity',xtitle='Time, UT',$
;	charsize=1.5, yrange=[0.,1.2],/ystyle,xrange = v_time_range,/xstyle,$
;	pos=[0.15,0.15,0.85,0.85],xthick=2.,ythick=2.,xtickv = thetickrange,$
;	xminor=4,symsize=0.9,xticks = tick_amnt,xgridstyle=1,ygridstyle=1,$
;	xticklen=1.0,yticklen=1.0
;oplot, v_times,rel_intnst
;
;decision=''
;print,''
;print, "save as postscript?  y/n"
;print,''
;read,decision
;if (decision ne 'y') then goto, dummy5
;print,''
; !p.font=0
; set_plot,'ps'
; load_mycolor
; psfilename = 'c:\wtsrv\profiles\mpkryn\UVIplots\v_intnst'+date+'.ps'
; 
; device,filename=psfilename,/helvetica,/bold,/inches,$
;   font_size=10,bits=8,/landscape,$
;   /color
;   
; plot, v_times,rel_intnst,psym=4, title = intnst_title,$
;	ytitle='Intensity, normalized units',xtitle='Time, UT',$
;	charsize=1.5, yrange=[0.,1.2],/ystyle,xrange = v_time_range,/xstyle,$
;	pos=[0.15,0.15,0.85,0.85],xthick=2.,ythick=2.,xtickv = thetickrange,$
;	xminor=4,symsize=1.,xticks = tick_amnt, xgridstyle=1,ygridstyle=1,$
;	xticklen=1.0,yticklen=1.0
;	
; oplot, v_times,rel_intnst
;
;device,/close
;set_plot,'win'
;!p.font=1

dummy5:

end