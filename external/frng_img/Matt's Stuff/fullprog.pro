;  04-08-99, Matt Krynicki.  This program is for creating
;  time series of Inuvik, Eagle, and Poker Flat (and any
;  other site) wind data.  it will also make histograms
;  and anything else i think of as i go along.  filename
;  format is "*****###.dbt" ### is the month and day, *****
;  is the site qualifier, e.g. "ikvrt" for inuvik vertical wind
;  files, etc.
;  adding temperature and intensity plots as well.


;  the subroutines!

;  the range of days request subroutine.

pro rangeofdays,date1,date2,yr,steppinstone

yr=''
date1=''
date2=''

;  steppinstone is used strictly in histogram analysis
;  it does not affect anything else.
;  "not yer steppinstone...not yer steppinstone!"

if (steppinstone eq 1) then begin
 print,''
 print,''
 print,''
 print, "adding data to the current histogram"
 print,''
 print,''
 print,''
endif

;  request the range of days.

print,''
print,''
print, "please enter the year that the data was gathered"
print,''
read,yr
print,''
print,''
print, "enter the dates of the file range to be included in this analysis "
; print, "in this plot, format 'mdd' m is 1 to C (hexadecimal)"
; print, "dd is 1 to 31"
print,''
; print, "PLEASE do NOT start with a day that contains no data"
print,''
; print, "if you wish to only have one day's worth of data,"
; print, "then please enter the date for both date 1 and date 2"
print,''
print,''
print, "date 1 ?"
print,''
read, date1
print,''
print, "date 2 ?"
print,''
read, date2
print,''
print,''

return

end

;  important info subroutine.

pro defineimportant,date,dat1,dat2,date1,date2,month1,$
     month2,day1,day2,mnthval1,mnthval2

date=''
month1=''
month2=''

date=date1
dat1=fix(date1)
dat2=fix(date2)
;  these values are used for creating plot titles.

mnthval1=strmid(date1,0,1)
mnthval2=strmid(date2,0,1)
day1=strmid(date1,1,2)
day2=strmid(date2,1,2)
if (mnthval1 eq '1') then month1='January'
if (mnthval2 eq '1') then month2='January'
if (mnthval1 eq '2') then month1='February'
if (mnthval2 eq '2') then month2='February'
if (mnthval1 eq '3') then month1='March'
if (mnthval2 eq '3') then month2='March'
if (mnthval1 eq '4') then month1='April'
if (mnthval2 eq '4') then month2='April'
if (mnthval1 eq '5') then month1='May'
if (mnthval2 eq '5') then month2='May'
if (mnthval1 eq '6') then month1='June'
if (mnthval2 eq '6') then month2='June'
if (mnthval1 eq '7') then month1='July'
if (mnthval2 eq '7') then month2='July'
if (mnthval1 eq '8') then month1='August'
if (mnthval2 eq '8') then month2='August'
if (mnthval1 eq '9') then month1='September'
if (mnthval2 eq '9') then month2='September'
if (mnthval1 eq 'A') then month1='October'
if (mnthval2 eq 'A') then month2='October'
if (mnthval1 eq 'B') then month1='November'
if (mnthval2 eq 'B') then month2='November'
if (mnthval1 eq 'C') then month1='December'
if (mnthval2 eq 'C') then month2='December'

return

end

; the following call changes the date string and the switch string
; if it is necessary.  that is, if the data range covers
; different months, we need to properly change the date string
; so that the computer knows what to look for.

pro chngmnthdate,mnthval,day,date,switch

if (mnthval eq '1') and (day eq '31') then begin
  mnthval='2' & day='01' & date=mnthval+day & switch='y'
endif
if (mnthval eq '2') and (day eq '28') then begin
  mnthval='3' & day='01' & date=mnthval+day & switch='y'
endif
if (mnthval eq '3') and (day eq '31') then begin
  mnthval='4' & day='01' & date=mnthval+day & switch='y'
endif
if (mnthval eq '4') and (day eq '30') then begin
  mnthval='5' & day='01' & date=mnthval+day & switch='y'
endif
if (mnthval eq '5') and (day eq '31') then begin
  mnthval='6' & day='01' & date=mnthval+day & switch='y'
endif
if (mnthval eq '6') and (day eq '30') then begin
  mnthval='7' & day='01' & date=mnthval+day & switch='y'
endif
if (mnthval eq '7') and (day eq '31') then begin
  mnthval='8' & day='01' & date=mnthval+day & switch='y'
endif
if (mnthval eq '8') and (day eq '31') then begin
  mnthval='9' & day='01' & date=mnthval+day & switch='y'
endif
if (mnthval eq '9') and (day eq '30') then begin
  mnthval='A' & day='01' & date=mnthval+day & switch='y'
endif
if (mnthval eq 'A') and (day eq '31') then begin
  mnthval='B' & day='01' & date=mnthval+day & switch='y'
endif
if (mnthval eq 'B') and (day eq '30') then begin
  mnthval='C' & day='01' & date=mnthval+day & switch='y'
endif
if (mnthval eq 'C') and (day eq '31') then begin
  mnthval='1' & day='01' & date=mnthval+day & switch='y'
endif

return

end

;  this sub is for correcting the last value of the dates array

pro crrctlastday,lastmnthval,lastday

if (lastmnthval eq '1') and (lastday eq '32') then lastday='01'
if (lastmnthval eq '2') and (lastday eq '29') then lastday='01'
if (lastmnthval eq '3') and (lastday eq '32') then lastday='01'
if (lastmnthval eq '4') and (lastday eq '31') then lastday='01'
if (lastmnthval eq '5') and (lastday eq '32') then lastday='01'
if (lastmnthval eq '6') and (lastday eq '31') then lastday='01'
if (lastmnthval eq '7') and (lastday eq '32') then lastday='01'
if (lastmnthval eq '8') and (lastday eq '32') then lastday='01'
if (lastmnthval eq '9') and (lastday eq '31') then lastday='01'
if (lastmnthval eq 'A') and (lastday eq '32') then lastday='01'
if (lastmnthval eq 'B') and (lastday eq '31') then lastday='01'
if (lastmnthval eq 'C') and (lastday eq '32') then lastday='01'

return

end

;  this sub is for defining the limits of the time series
;  graphs for the y-axis, velocity.

pro defineylimits,micky,minny,yranmaxval,yranminval

if (micky gt yranmaxval) then begin
 if (micky le 50) then yranmaxval=50
 if (micky gt 50) and (micky le 100) then yranmaxval=100
 if (micky gt 100) and (micky le 150) then yranmaxval=150
 if (micky gt 150) and (micky le 200) then yranmaxval=200
 if (micky gt 200) and (micky le 250) then yranmaxval=250
 if (micky gt 250) and (micky le 300) then yranmaxval=300
 if (micky gt 300) and (micky le 350) then yranmaxval=350
 if (micky gt 350) and (micky le 400) then yranmaxval=400
 if (micky gt 400) and (micky le 450) then yranmaxval=450
 if (micky gt 450) and (micky le 500) then yranmaxval=500
 if (micky gt 500) and (micky le 550) then yranmaxval=550
 if (micky gt 550) and (micky le 600) then yranmaxval=600
 if (micky gt 600) and (micky le 650) then yranmaxval=650
 if (micky gt 650) and (micky le 700) then yranmaxval=700
 if (micky gt 700) and (micky le 750) then yranmaxval=750
 if (micky gt 750) and (micky le 800) then yranmaxval=800
 if (micky gt 800) and (micky le 850) then yranmaxval=850
endif
if (minny lt yranminval) then begin
 if (minny ge -50) then yranminval=-50
 if (minny lt -50) and (minny ge -100) then yranminval=-100
 if (minny lt -100) and (minny ge -150) then yranminval=-150
 if (minny lt -150) and (minny ge -200) then yranminval=-200
 if (minny lt -200) and (minny ge -250) then yranminval=-250
 if (minny lt -250) and (minny ge -300) then yranminval=-300
 if (minny lt -300) and (minny ge -350) then yranminval=-350
 if (minny lt -350) and (minny ge -400) then yranminval=-400
 if (minny lt -400) and (minny ge -450) then yranminval=-450
 if (minny lt -450) and (minny ge -500) then yranminval=-500
 if (minny lt -500) and (minny ge -550) then yranminval=-550
 if (minny lt -550) and (minny ge -600) then yranminval=-600
 if (minny lt -600) and (minny ge -650) then yranminval=-650
 if (minny lt -650) and (minny ge -700) then yranminval=-700
 if (minny lt -700) and (minny ge -750) then yranminval=-750
 if (minny lt -750) and (minny ge -800) then yranminval=-800
 if (minny lt -800) and (minny ge -850) then yranminval=-850
endif

return

end

;  this sub is for correcting the time from decimal back to
;  normal in order to plot time series of only one day's data with
;  "Time in UT" on the x-axis

pro crrctthetime,soup,souper,soupest,insouper,outsouper,stup,$
  stuper,stupest,instuper,outstuper

if (soup lt 0) then begin
 prevtme=2400+soup
 inbtw=float(prevtme)
 hr=strmid(strcompress(prevtme,/remove_all),0,2)
 hrtme=float(fix(hr)*100)
 tmeindec=(inbtw-hrtme)/100.
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 stup=hr+fixtm
endif
if (soup ge 0) and (soup lt 100) then begin
 tmeindec=float(soup)
 tmeinmin=60*(tmeindec/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 stup='00'+fixtm
endif
if (soup ge 100) and (soup lt 1000) then begin
 inbtw=float(soup)
 hr=strmid(strcompress(soup,/remove_all),0,1)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse 
 stup='0'+hr+fixtm
endif
if (soup ge 1000) then begin
 inbtw=float(soup)
 hr=strmid(strcompress(soup,/remove_all),0,2)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 stup=hr+fixtm
endif
if (souper lt 100) then begin
 tmeindec=float(souper)
 tmeinmin=60*(tmeindec/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 stuper='00'+fixtm
endif
if (souper ge 100) and (souper lt 1000) then begin
 inbtw=float(souper)
 hr=strmid(strcompress(souper,/remove_all),0,1)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 stuper='0'+hr+fixtm
endif
if (souper ge 1000) and (souper lt 10000) then begin
 inbtw=float(souper)
 hr=strmid(strcompress(souper,/remove_all),0,2)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin 
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 stuper=hr+fixtm
endif
if (souper ge 10000) then begin
 inbtw=float(souper)
 hr=strmid(strcompress(souper,/remove_all),0,3)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 stuper=hr+fixtm
endif
if (soupest lt 100) then begin
 tmeindec=float(soupest)
 tmeinmin=60*(tmeindec/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 stupest='00'+fixtm
endif
if (soupest ge 100) and (soupest lt 1000) then begin
 inbtw=float(soupest)
 hr=strmid(strcompress(soupest,/remove_all),0,1)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 stupest='0'+hr+fixtm
endif
if (soupest ge 1000) and (soupest lt 10000) then begin
 inbtw=float(soupest)
 hr=strmid(strcompress(soupest,/remove_all),0,2)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 stupest=hr+fixtm
endif 
if (soupest ge 10000) then begin
 inbtw=float(soupest)
 hr=strmid(strcompress(soupest,/remove_all),0,3)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 stupest=hr+fixtm
endif
if (insouper lt 100) then begin
 tmeindec=float(insouper)
 tmeinmin=60*(tmeindec/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 instuper='00'+fixtm
endif
if (insouper ge 100) and (insouper lt 1000) then begin
 inbtw=float(insouper)
 hr=strmid(strcompress(insouper,/remove_all),0,1)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 instuper='0'+hr+fixtm
endif
if (insouper ge 1000) and (insouper lt 10000) then begin
 inbtw=float(insouper)
 hr=strmid(strcompress(insouper,/remove_all),0,2)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 instuper=hr+fixtm
endif
if (insouper ge 10000) then begin
 inbtw=float(insouper)
 hr=strmid(strcompress(insouper,/remove_all),0,3)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 instuper=hr+fixtm
endif
if (outsouper lt 100) then begin
 tmeindec=float(outsouper)
 tmeinmin=60*(tmeindec/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 outstuper='00'+fixtm
endif
if (outsouper ge 100) and (outsouper lt 1000) then begin
 inbtw=float(outsouper)
 hr=strmid(strcompress(outsouper,/remove_all),0,1)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 outstuper='0'+hr+fixtm
endif
if (outsouper ge 1000) and (outsouper lt 10000) then begin
 inbtw=float(outsouper)
 hr=strmid(strcompress(outsouper,/remove_all),0,2)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 outstuper=hr+fixtm
endif
if (outsouper ge 10000) then begin
 inbtw=float(outsouper)
 hr=strmid(strcompress(outsouper,/remove_all),0,3)
 hrtme=float(fix(hr)*100)
 tmeinmin=60*((inbtw-hrtme)/100.)
 if (tmeinmin lt 10.) then begin
  fixtm='0'+strcompress(fix(tmeinmin),/remove_all)
 endif else begin
  fixtm=strcompress(fix(tmeinmin),/remove_all)
 endelse
 outstuper=hr+fixtm
endif

return

end

;  this sub asks for all relevant site information and what types
;  of winds are being analyzed.

pro getsiteinfo,location,site,datatype,plottype,fileext

fileext=''
request=''
whichwind=''
datatype=''
plottype=''
location=''
site=''

get:
print,''
print, "select the site of the data you will be analyzing"
print,''
print, "a.  Inuvik"
print, "b.  Eagle"
print, "c.  Poker Flat"
print, "d.  South Pole"
print,''
read, request
print,''
if (request ne 'a') and (request ne 'b') and (request ne 'c') $
  and (request ne 'd') then print, "dummy"
if (request ne 'a') and (request ne 'b') and (request ne 'c') $
  and (request ne 'd') then goto,get
if (request eq 'a') then begin
 location='inuvik'
 site='Inuvik, NWT'
endif
if (request eq 'b') then begin
 location='eagle'
 site='Eagle, AK'
endif
if (request eq 'c') then begin
 location='poker'
 site='Poker Flat, AK'
endif
if (request eq 'd') then begin
 location='southpole'
 site='South Pole'
endif

moreget:
print,''
print,''
print, "Which wind data will you be analyzing?"
print,''
print, "a.  Vertical wind measurements"
print, "b.  Meridional winds"
print, "c.  Zonal winds"
print, "d.  All winds (for example, if you want temperature or"
print, "    intensity plots from all directions of measurement"
print, "    or if you want all wind measurements on one graph"
print,''
read, whichwind
print,''
if (whichwind ne 'a') and (whichwind ne 'b') and $
   (whichwind ne 'c') then print, "dummy"
if (whichwind ne 'a') and (whichwind ne 'b') and $
   (whichwind ne 'c') then goto,moreget
if (whichwind eq 'a') then begin
 datatype='vertdata'
 plottype='Vertical'
endif
if (whichwind eq 'b') then begin
 datatype='merddata'
 plottype='Meridional'
endif
if (whichwind eq 'c') then begin
 datatype='zonedata'
 plottype='Zonal'
endif
if (whichwind eq 'd') then begin
 datatype=''
 plottype='All'
endif
if (whichwind eq 'a') and (request eq 'a') then fileext='ikvrt'
if (whichwind eq 'b') and (request eq 'a') then fileext='ikmrd'
if (whichwind eq 'c') and (request eq 'a') then fileext='ikzon'
if (whichwind eq 'd') and (request eq 'a') then fileext='ivkrd'
if (whichwind eq 'a') and (request eq 'b') then fileext='eavrt'
if (whichwind eq 'b') and (request eq 'b') then fileext='eamrd'
if (whichwind eq 'c') and (request eq 'b') then fileext='eazon'
if (whichwind eq 'd') and (request eq 'b') then fileext='eagrd'
if (whichwind eq 'a') and (request eq 'c') then fileext='pkvrt'
if (whichwind eq 'b') and (request eq 'c') then fileext='pkmrd'
if (whichwind eq 'c') and (request eq 'c') then fileext='pkzon'
if (whichwind eq 'd') and (request eq 'c') then fileext='pkfrd'
if (whichwind eq 'a') and (request eq 'd') then fileext='spvrt'
if (whichwind eq 'b') and (request eq 'd') then fileext='spmrd'
if (whichwind eq 'c') and (request eq 'd') then fileext='spzon'
if (whichwind eq 'd') and (request eq 'd') then fileext='spord'

return

end

;  this sub begins the process of time series analysis

pro starttimeseries,trig1,trig2,trig3

common fourplotinfo,xplottitle2,plottitle2,datadates2,p2,lent2,silly2,$
  xranminval2,xranmaxval2,timetot3,windtot3,xplottitle3,plottitle3,$
  datadates3,p3,lent3,silly3,xranminval3,xranmaxval3,timetot4,$
  windtot4,xplottitle4,plottitle4,datadates4,p4,lent4,silly4,$
  xranminval4,xranmaxval4,plottype,site,line1,line2,line3,line4,$
  wnderr1,othwnderr1,wnderr2,othwnderr2,wnderr3,othwnderr3,wnderr4,$
  othwnderr4

print,''
print,''
print, "you can have up to 4 separate time series plots"
print, "on a single sheet of paper"
print, "how many do you want for this particular set of data? "
print,''
read, plotnumber
plotnumber=fix(plotnumber)
print,''

if (plotnumber eq 1) then windtot1=fltarr(1) & timetot1=lonarr(1) & $
  datadates1=strarr(1) & p1=0 & t1=0 & othwind1=fltarr(1) & $
  othtime1=fltarr(1) & wnderr1=fltarr(1) & othwnderr1=fltarr(1)
if (plotnumber eq 2) then windtot1=fltarr(1) & windtot2=fltarr(1) & $
  timetot1=lonarr(1) & timetot2=lonarr(1) & datadates1=strarr(1) & $
  datadates2=strarr(1) & p1=0 & p2=0 & t1=0 & t2=0 & $
  othwind1=fltarr(1) & othwind2=fltarr(1) & othtime1=fltarr(1) & $
  othtime2=fltarr(1) & wnderr1=fltarr(1) & othwnderr1=fltarr(1) & $
  wnderr2=fltarr(1) & othwnderr2=fltarr(1)
if (plotnumber eq 3) then windtot1=fltarr(1) & windtot2=fltarr(1) & $
  windtot3=lonarr(1) & timetot1=lonarr(1) & timetot2=lonarr(1) & $
  timetot3=lonarr(1) & datadates1=strarr(1) & datadates2=strarr(1) & $
  datadates3=strarr(1) & p1=0 & p2=0 & p3=0 & t1=0 & t2=0 & t3=0 & $
  othwind1=fltarr(1) & othwind2=fltarr(1) & othwind3=fltarr(1) & $
  othtime1=fltarr(1) & othtime2=fltarr(1) & othtime3=fltarr(1) & $
  wnderr1=fltarr(1) & wnderr2=fltarr(1) & wnderr3=fltarr(1) & $
  othwnderr1=fltarr(1) & othwnderr2=fltarr(1) & othwnderr3=fltarr(1)
if (plotnumber eq 4) then windtot1=fltarr(1) & windtot2=fltarr(1) & $
  windtot3=fltarr(1) & windtot4=fltarr(1) & timetot1=lonarr(1) & $
  timetot2=lonarr(1) & timetot3=lonarr(1) & timetot4=lonarr(1) & $
  datadates1=strarr(1) & datadates2=strarr(1) & datadates3=strarr(1) & $
  datadates4=strarr(1) & p1=0 & p2=0 & p3=0 & p4=0 & t1=0 & t2=0 & $
  t3=0 & t4=0 & othwind1=fltarr(1) & othwind2=fltarr(1) & $
  othwind3=fltarr(1) & othwind4=fltarr(1) & othtime1=fltarr(1) & $
  othtime2=fltarr(1) & othtime3=fltarr(1) & othtime4=fltarr(1) & $
  wnderr1=fltarr(1) & wnderr2=fltarr(1) & wnderr3=fltarr(1) & $
  wnderr4=fltarr(1) & othwnderr1=fltarr(1) & othwnderr2=fltarr(1) & $
  othwnderr3=fltarr(1) & othwnderr4=fltarr(1)

; m and k are the key!  my initials...
; mm and kk are used when plotting meridional or zonal data
; they remain unused when plotting vertical data
m=0 & k=0 & steppinstone=0 & mm=0 & kk=0

if (plotnumber eq 1) then begin
  print,''
  print, "plot 1"
  print,''
  call_procedure,'getsiteinfo',location,site,datatype,plottype,$
    fileext
  call_procedure,'rangeofdays',date1,date2,yr,steppinstone
  call_procedure,'defineimportant',date,dat1,dat2,date1,date2,month1,$
    month2,day1,day2,mnthval1,mnthval2
  call_procedure,'oneplot',windtot1,othwind1,othtime1,$
    mnthval1,mnthval2,plotnumber,fileext,datatype,location,site,$
    plottype,lent1,silly1,line1,$
    timetot1,datadates1,yranmaxval,yranminval,xranmaxval1,$
    xranminval1,plottitle1,xplottitle1,yr,date,month1,day1,month2,$
    day2,date1,dat1,dat2,date2,m,k,mm,kk,p1,t1,psfilenametmp1,$
    wnderr1,othwnderr1
endif
if (plotnumber eq 2) then begin
  print,''
  print, "plot 1"
  print,''
  call_procedure,'getsiteinfo',location,site,datatype,plottype,$
    fileext
  call_procedure,'rangeofdays',date1,date2,yr,steppinstone
  call_procedure,'defineimportant',date,dat1,dat2,date1,date2,month1,$
    month2,day1,day2,mnthval1,mnthval2
  call_procedure,'oneplot',windtot1,othwind1,othtime1,$
    mnthval1,mnthval2,plotnumber,fileext,datatype,location,site,$
    plottype,lent1,silly1,line1,$
    timetot1,datadates1,yranmaxval,yranminval,xranmaxval1,$
    xranminval1,plottitle1,xplottitle1,yr,date,month1,day1,month2,$
    day2,date1,dat1,dat2,date2,m,k,mm,kk,p1,t1,psfilenametmp1,$
    wnderr1,othwnderr1
  m=0 & k=0 & mm=0 & kk=0
  print,''
  print, "plot 2"
  print,''
  call_procedure,'getsiteinfo',location,site,datatype,plottype,$
    fileext
  call_procedure,'rangeofdays',date1,date2,yr,steppinstone
  call_procedure,'defineimportant',date,dat1,dat2,date1,date2,month1,$
    month2,day1,day2,mnthval1,mnthval2
  call_procedure,'twoplot',windtot2,othwind2,othtime2,$
    mnthval1,mnthval2,plotnumber,fileext,datatype,location,site,$
    plottype,lent2,silly2,line2,timetot2,datadates2,yranmaxval,$
    yranminval,xranmaxval2,xranminval2,plottitle2,xplottitle2,yr,$
    date,month1,day1,month2,day2,date1,dat1,dat2,date2,m,k,mm,kk,$
    p2,t2,psfilenametmp1,psfilenametmp2,wnderr2,othwnderr2
endif
if (plotnumber eq 3) then begin
  print,''
  print, "plot 1"
  print,''
  call_procedure,'getsiteinfo',location,site,datatype,plottype,$
    fileext
  call_procedure,'rangeofdays',date1,date2,yr,steppinstone
  call_procedure,'defineimportant',date,dat1,dat2,date1,date2,month1,$
    month2,day1,day2,mnthval1,mnthval2
  call_procedure,'oneplot',windtot1,othwind1,othtime1,$
    mnthval1,mnthval2,plotnumber,fileext,datatype,location,site,$
    plottype,lent1,silly1,line1,$
    timetot1,datadates1,yranmaxval,yranminval,xranmaxval1,$
    xranminval1,plottitle1,xplottitle1,yr,date,month1,day1,month2,$
    day2,date1,dat1,dat2,date2,m,k,mm,kk,p1,t1,psfilenametmp1,$
    wnderr1,othwnderr1
  m=0 & k=0 & mm=0 & kk=0
  print,''
  print, "plot 2"
  print,''
  call_procedure,'getsiteinfo',location,site,datatype,plottype,$
    fileext
  call_procedure,'rangeofdays',date1,date2,yr,steppinstone
  call_procedure,'defineimportant',date,dat1,dat2,date1,date2,month1,$
    month2,day1,day2,mnthval1,mnthval2
  call_procedure,'twoplot',windtot2,othwind2,othtime2,$
    mnthval1,mnthval2,plotnumber,fileext,datatype,location,site,$
    plottype,lent2,silly2,line2,$
    timetot2,datadates2,yranmaxval,yranminval,xranmaxval2,$
    xranminval2,plottitle2,xplottitle2,yr,date,month1,day1,month2,$
    day2,date1,dat1,dat2,date2,m,k,mm,kk,p2,t2,psfilenametmp1,$
    psfilenametmp2,wnderr2,othwnderr2
  m=0 & k=0 & mm=0 & kk=0
  print,''
  print, "plot 3"
  print,''
  call_procedure,'getsiteinfo',location,site,datatype,plottype,$
    fileext
  call_procedure,'rangeofdays',date1,date2,yr,steppinstone
  call_procedure,'defineimportant',date,dat1,dat2,date1,date2,month1,$
     month2,day1,day2,mnthval1,mnthval2
  call_procedure,'threeplot',windtot3,othwind3,othtime3,$
    mnthval1,mnthval2,plotnumber,fileext,datatype,location,site,$
    plottype,lent3,silly3,line3,$
    timetot3,datadates3,yranmaxval,yranminval,xranmaxval3,$
    xranminval3,plottitle3,xplottitle3,yr,date,month1,day1,month2,$
    day2,date1,dat1,dat2,date2,m,k,mm,kk,p3,t3,psfilenametmp2,$
    psfilenametmp3,wnderr3,othwnderr3
endif
if (plotnumber eq 4) then begin
  print,''
  print, "plot 1"
  print,''
  call_procedure,'getsiteinfo',location,site,datatype,plottype,$
    fileext
  call_procedure,'rangeofdays',date1,date2,yr,steppinstone
  call_procedure,'defineimportant',date,dat1,dat2,date1,date2,month1,$
     month2,day1,day2,mnthval1,mnthval2
  call_procedure,'oneplot',windtot1,othwind1,othtime1,$
    mnthval1,mnthval2,plotnumber,fileext,datatype,location,site,$
    plottype,lent1,silly1,line1,$
    timetot1,datadates1,yranmaxval,yranminval,xranmaxval1,$
    xranminval1,plottitle1,xplottitle1,yr,date,month1,day1,month2,$
    day2,date1,dat1,dat2,date2,m,k,mm,kk,p1,t1,psfilenametmp1,$
    wnderr1,othwnderr1
  m=0 & k=0 & mm=0 & kk=0
  print,''
  print, "plot 2"
  print,''
  call_procedure,'getsiteinfo',location,site,datatype,plottype,$
    fileext
  call_procedure,'rangeofdays',date1,date2,yr,steppinstone
  call_procedure,'defineimportant',date,dat1,dat2,date1,date2,month1,$
     month2,day1,day2,mnthval1,mnthval2
  call_procedure,'twoplot',windtot2,othwind2,othtime2,$
    mnthval1,mnthval2,plotnumber,fileext,datatype,location,site,$
    plottype,lent2,silly2,line2,$
    timetot2,datadates2,yranmaxval,yranminval,xranmaxval2,$
    xranminval2,plottitle2,xplottitle2,yr,date,month1,day1,month2,$
    day2,date1,dat1,dat2,date2,m,k,mm,kk,p2,t2,psfilenametmp1,$
    psfilenametmp2,wnderr2,othwnderr2
  m=0 & k=0 & mm=0 & kk=0
  print,''
  print, "plot 3"
  print,''
  call_procedure,'getsiteinfo',location,site,datatype,plottype,$
    fileext
  call_procedure,'rangeofdays',date1,date2,yr,steppinstone
  call_procedure,'defineimportant',date,dat1,dat2,date1,date2,month1,$
     month2,day1,day2,mnthval1,mnthval2
  call_procedure,'threeplot',windtot3,othwind3,othtime3,$
    mnthval1,mnthval2,plotnumber,fileext,datatype,location,site,$
    plottype,lent3,silly3,line3,$
    timetot3,datadates3,yranmaxval,yranminval,xranmaxval3,$
    xranminval3,plottitle3,xplottitle3,yr,date,month1,day1,month2,$
    day2,date1,dat1,dat2,date2,m,k,mm,kk,p3,t3,psfilenametmp2,$
    psfilenametmp3,wnderr3,othwnderr3
  m=0 & k=0 & mm=0 & kk=0
  print,''
  print, "plot 4"
  print,''
  call_procedure,'getsiteinfo',location,site,datatype,plottype,$
    fileext
  call_procedure,'rangeofdays',date1,date2,yr,steppinstone
  call_procedure,'defineimportant',date,dat1,dat2,date1,date2,month1,$
     month2,day1,day2,mnthval1,mnthval2
  call_procedure,'fourplot',windtot4,othwind4,othtime4,$
    mnthval1,mnthval2,plotnumber,fileext,datatype,location,site,$
    plottype,lent4,silly4,line4,$
    timetot4,datadates4,yranmaxval,yranminval,xranmaxval4,$
    xranminval4,plottitle4,xplottitle4,yr,date,month1,day1,month2,$
    day2,date1,dat1,dat2,date2,m,k,mm,kk,p4,t4,psfilenametmp3,$
    psfilenametmp4,wnderr4,othwnderr4
endif

plotting:

yplottitle='Velocity  m/s.'

;  this section plots the total wind data for all the days
;  requested at the beginning

if (plotnumber eq 1) then begin
  call_procedure,'plotoneseries',timetot1,windtot1,xplottitle1,$
    plotnumber,othwind1,othtime1,yr,location,datatype,$
    plottitle1,datadates1,p1,lent1,silly1,xranminval1,xranmaxval1,$
    yranminval,yranmaxval,yplottitle,psfilenametmp1,plottype,site,$
    line1,trig1,trig2,trig3,wnderr1,othwnderr1
endif
if (plotnumber eq 2) then begin
  call_procedure,'plottwoseries',timetot1,windtot1,xplottitle1,$
    plotnumber,othwind1,othwind2,othtime1,othtime2,datatype,$
    plottitle1,datadates1,p1,lent1,silly1,xranminval1,xranmaxval1,$
    yranminval,yranmaxval,yplottitle,psfilenametmp2,timetot2,windtot2,$
    xplottitle2,plottitle2,datadates2,p2,lent2,silly2,xranminval2,$
    xranmaxval2,plottype,site,line1,line2,wnderr1,othwnderr1,wnderr2,$
    othwnderr2
endif
if (plotnumber eq 3) then begin
  call_procedure,'plotthreeseries',timetot1,windtot1,xplottitle1,$
    plotnumber,othwind1,othwind2,othwind3,othtime1,othtime2,$
    othtime3,datatype,$
    plottitle1,datadates1,p1,lent1,silly1,xranminval1,xranmaxval1,$
    yranminval,yranmaxval,yplottitle,psfilenametmp3,timetot2,windtot2,$
    xplottitle2,plottitle2,datadates2,p2,lent2,silly2,xranminval2,$
    xranmaxval2,timetot3,windtot3,xplottitle3,plottitle3,datadates3,p3,$
    lent3,silly3,xranminval3,xranmaxval3,plottype,site,line1,line2,$
    line3,wnderr1,othwnderr1,wnderr2,othwnderr2,wnderr3,othwnderr3
endif
if (plotnumber eq 4) then begin
  call_procedure,'plotfourseries',timetot1,windtot1,xplottitle1,$
    plotnumber,othwind1,othwind2,othwind3,othwind4,othtime1,$
    othtime2,othtime3,othtime4,datatype,$
    plottitle1,datadates1,p1,lent1,silly1,xranminval1,xranmaxval1,$
    yranminval,yranmaxval,yplottitle,psfilenametmp4,timetot2,windtot2
endif

return

end

;  the sub is for storing all of plot 1's info.

pro oneplot,windtot1,othwind1,othtime1,mnthval1,mnthval2,plotnumber,$
    fileext,datatype,location,site,plottype,lent1,silly1,line1,$
    timetot1,datadates1,yranmaxval,yranminval,xranmaxval1,$
    xranminval1,plottitle1,xplottitle1,yr,date,month1,day1,month2,$
    day2,date1,dat1,dat2,date2,m,k,mm,kk,p1,t1,psfilenametmp1,$
    wnderr1,othwnderr1

switch=''
thefile=''
fulldate=''
tmdate=''
psfilenametmp1=''
plotques=''

;  these values need to be in the looping so that they
;  can change for each opened data file.

continuebuild:

dat=fix(date)
mnthval=strmid(date,0,1)
day=strmid(date,1,2)

;  defining the data filename

thefile='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+'/'+ $
    datatype+'/'+fileext+date+'.dbt'

;  open and read the file to determine the size.
;  and go to the relevant section to add null data,
;  see below for details.

openr,3,thefile,error=bad
if (bad ne 0) then print, "there is no data for "+date
if (bad ne 0) then print,''
if (bad ne 0) then begin

;  if there is no data for a given day, then add bad data to the
;  all days arrays, which will consequently be ignored by the
;  plotting routines.  this section must be skipped the first time
;  around.
;  bad is the open file error variable.
;  storing the all days arrays first.

  storetime1=lonarr(m)
  storewind1=fltarr(m)
  storewinderr1=fltarr(m)
  storetime1(*)=timetot1(*)
  storewind1(*)=windtot1(*)
  storewinderr1(*)=wnderr1(*)
  g=m
  m=m+n
  timetot1=lonarr(m)
  windtot1=fltarr(m)
  wnderr1=fltarr(m)
  for l=0,g-1 do begin
   timetot1(l)=storetime1(l)
   windtot1(l)=storewind1(l)
   wnderr1(l)=storewinderr1(l)
  endfor
  h=0
 addnulldata:
  timetot1(k)=(p1*2400)+ttime1(h)
  windtot1(k)=10000
  wnderr1(k)=10000
  k=k+1 & h=h+1
  if (h lt n) then goto, addnulldata

 if (datatype eq 'vertdata') then goto,smelly
  storetime2=lonarr(mm)
  storewind2=fltarr(mm)
  storewinderr2=fltarr(mm)
  storetime2(*)=othtime1(*)
  storewind2(*)=othwind1(*)
  storewinderr2=othwnderr1(*)
  gg=mm
  mm=mm+nn
  othtime1=lonarr(mm)
  othwind1=fltarr(mm)
  othwnderr1=fltarr(mm)
  for ll=0,gg-1 do begin
   othtime1(ll)=storetime2(ll)
   othwind1(ll)=storewind2(ll)
   othwnderr1(ll)=storewinderr2(ll)
  endfor
  hh=0
 adothnlldt:
  othtime1(kk)=(p1*2400)+ttime2(hh)
  othwind1(kk)=10000
  othwnderr(kk)=10000
  kk=kk+1 & hh=hh+1
  if (hh lt nn) then goto,adothnlldt
 smelly:
endif
if (bad ne 0) then goto, skipreldata

;  ok, here we go.
;  n and nn define the size of each datafile after it is read.
;  define the array sizes and types for the day's data

if (datatype eq 'vertdata') then begin
 j=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
    if (dum5 gt 250) or (dum5 lt -250) then goto, dontincre
 j=j+1
 dontincre:
 endwhile
 n=j
 ttime1=lonarr(n)
 twind1=fltarr(n)
 twinderr1=fltarr(n)
endif
if (datatype eq 'merddata') or (datatype eq 'zonedata') then begin
 j=0 & d=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
    if (dum4 eq 30) and (dum3 eq 0) then begin
     j=j+1
    endif
    if (dum4 eq 30) and (dum3 eq 180) then begin
     d=d+1
    endif
    if (dum4 eq 30) and (dum3 eq 90) then begin
     j=j+1
    endif
    if (dum4 eq 30) and (dum3 eq 270) then begin
     d=d+1
    endif
 endwhile
 n=j
 nn=d
 ttime1=lonarr(n)
 ttime2=lonarr(nn)
 twind1=fltarr(n)
 twind2=fltarr(nn)
 twinderr1=fltarr(n)
 twinderr2=fltarr(nn)
endif
close,3

;  open it now to read it and store the data

openr,3,thefile
if (datatype eq 'vertdata') then begin
 i=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
   if (dum5 gt 250) or (dum5 lt -250) then goto, dontdoit
   tmdate=strmid(fulldate,3,3)
   if (tmdate ne date) then begin
     if (location eq 'southpole') and (yr eq '91') then begin
;or $
;      (location eq 'inuvik') then begin
       ttime1(i)=dum2-2360
     endif else begin
       ttime1(i)=dum2-2400
     endelse
   endif else begin
     ttime1(i)=dum2
   endelse
   twind1(i)=dum5
   twinderr1(i)=dum6
 i=i+1
 dontdoit:
 endwhile
endif
if (datatype eq 'merddata') or (datatype eq 'zonedata') then begin
 i=0 & dd=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
   tmdate=strmid(fulldate,3,3) 
   if (dum4 eq 30) and (dum3 eq 0) then begin
    twind1(i)=dum5
    twinderr1(i)=dum6
    if (tmdate ne date) then begin
     if (location eq 'southpole') and (yr eq '91') then begin
;or $
;      (location eq 'inuvik') then begin
       ttime1(i)=dum2-2360
     endif else begin
       ttime1(i)=dum2-2400
     endelse
    endif else begin
      ttime1(i)=dum2
    endelse
    i=i+1
   endif
    if (dum4 eq 30) and (dum3 eq 180) then begin
     twind2(dd)=dum5
     twinderr2(dd)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime2(dd)=dum2
     endelse
     dd=dd+1
    endif
    if (dum4 eq 30) and (dum3 eq 90) then begin
     twind1(i)=dum5
     twinderr1(i)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime1(i)=dum2
     endelse
     i=i+1
    endif
    if (dum4 eq 30) and (dum3 eq 270) then begin
     twind2(dd)=dum5
     twinderr2(dd)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime2(dd)=dum2
     endelse
     dd=dd+1
    endif
 endwhile
endif
close,3

;  start building the all days arrays, skipping the storage phase
;  on the first go around.

;  m defines the size of the all days arrays
;  g is used as a go-between for the storage arrays,
;  when we need to redefine the size of the all days arrays.

g=m
m=m+n
if (g eq 0) then goto, dontstore
  storetime1=lonarr(g)
  storewind1=fltarr(g)
  storewinderr1=fltarr(g)
  storetime1(*)=timetot1(*)
  storewind1(*)=windtot1(*)
  storewinderr1(*)=wnderr1(*)
dontstore:
timetot1=lonarr(m)
windtot1=fltarr(m)
wnderr1=fltarr(m)
if (g eq 0) then goto, skippedpart
 for l=0,g-1 do begin
  timetot1(l)=storetime1(l)
  windtot1(l)=storewind1(l)
  wnderr1(l)=storewinderr1(l)
 endfor
skippedpart:

;  build the all days arrays
h=0
daysarray:
 timetot1(k)=(p1*2400)+ttime1(h)
 windtot1(k)=twind1(h)
 wnderr1(k)=twinderr1(h)
k=k+1 & h=h+1
if (h lt n) then goto, daysarray

if (datatype eq 'vertdata') then goto,smelly1
gg=mm
mm=mm+nn
if (gg eq 0) then goto,donotstor
  storetime2=lonarr(gg)
  storewind2=fltarr(gg)
  storewinderr2=fltarr(gg)
  storetime2(*)=othtime1(*)
  storewind2(*)=othwind1(*)
  storewinderr2(*)=othwnderr1(*)
donotstor:
othtime1=lonarr(mm)
othwind1=fltarr(mm)
othwnderr1=fltarr(mm)
if (gg eq 0) then goto,skippypart
 for ll=0,gg-1 do begin
  othtime1(ll)=storetime2(ll)
  othwind1(ll)=storewind2(ll)
  othwnderr1(ll)=storewinderr2(ll)
 endfor
skippypart:
hh=0
othdayarr:
 othtime1(kk)=(p1*2400)+ttime2(hh)
 othwind1(kk)=twind2(hh)
 othwnderr1(kk)=twinderr2(hh)
kk=kk+1 & hh=hh+1
if (hh lt nn) then goto,othdayarr
smelly1:

;  this is the line that is jumped to if there was no data for
;  a given day.  null data would have been stored instead, then
;  the program would come here

skipreldata:

;  now, creating the data dates array, which is used in
;  the plotting procedures as the xaxis of time.

;  p+(pltnum) is the tick number for the all days plots
;  it acts as the datadates array size until the end where
;  then a last day is added to the datadates array to finish
;  off the relevant xtick_name file information.  t then becomes
;  the datadates array size at that point.  p is important though
;  as it defines the tick number.  q acts as the go-between when
;  storing the date info.

q1=p1
p1=p1+1

if (q1 eq 0) then goto, notstoredate
  storedateinfo=strarr(q1)
  storedateinfo(*)=datadates1(*)
notstoredate:

datadates1=strarr(p1)

if (q1 eq 0) then goto, datearray
 for r=0,q1-1 do begin
  datadates1(r)=storedateinfo(r)
 endfor
datearray:

datadates1(t1)=day
t1=t1+1

; the following call changes the date string and the switch string
; if it is necessary.  that is, if the data range covers
; different months, we need to properly change the date string
; so that the computer knows what to look for.

call_procedure,'chngmnthdate',mnthval,day,date,switch

;  the dat and dat2 variables are used to determine if we are
;  done reading data, then go to the plotting section.

if (dat eq dat2) then goto, finalizearray

;  didn't go to next range of data so now check for a switch,
;  that is, did month change.

if (switch ne 'y') then begin
 dat=dat+1
 date=strcompress(dat,/remove_all)
endif
;  set switch back
switch=''

;  return to top to continue looping thru requested data range

goto, continuebuild

;  this section is for adding the last element to the
;  datadates array, used for the x-axis plotting

finalizearray:
storedateinfo=strarr(p1)
storedateinfo(*)=datadates1(*)
q1=p1
t1=t1+1
datadates1=strarr(t1)
for r=0,q1-1 do begin
 datadates1(r)=storedateinfo(r)
endfor
dat=dat+1
lastdate=strcompress(dat,/remove_all)
lastday=strmid(lastdate,1,2)
lastmnthval=strmid(lastdate,0,1)

call_procedure,'crrctlastday',lastmnthval,lastday

datadates1(t1-1)=lastday

if (location eq 'southpole') and (yr eq '91') then begin
; or $
; (location eq 'inuvik') then begin
 flttime=fltarr(m)
 for j=0,m-1 do begin
  thtime=timetot1(j)
  call_procedure,'cortodectime',thtime
  flttime(j)=thtime
 endfor
 timetot1=fix(flttime*100)
 if (datatype eq 'merddata') or (datatype eq 'zonedata') then begin
  othflttime=fltarr(mm)
  for j=0,mm-1 do begin
   thtime=othtime1(j)
   call_procedure,'cortodectime',thtime
   othflttime(j)=thtime
  endfor
  othtime1=fix(othflttime*100)
 endif
endif

;  this section makes the plot titles for the wind plot of
;  all the days

if (mnthval1 eq mnthval2) then begin
 if (day1 eq day2) then begin
  plottitle1=plottype+' Winds in the Upper Thermosphere!C'+ $
   site+', '+month1+' '+day1+', 19'+yr+'.'
  xplottitle1='Time in UT.'
  psfilenametmp1='/usr/users/mpkryn/windanalysis/test/psfilestest/'+$
     'wnd'+fileext+date1+yr
;  psfilenametmp1='/usr/users/mpkryn/windanalysis/'+location+'/'+ $
;     yr+'/'+datatype+'/psfiles/'+'wnd'+fileext+date1+yr
 endif else begin
  plottitle1=plottype+' Winds in the Upper Thermosphere!C'+ $
   site+', '+month1+' '+day1+' to '+day2+', 19'+yr+'.'
  xplottitle1='Dates in '+month1+'.'
  psfilenametmp1='/usr/users/mpkryn/windanalysis/test/psfilestest/'+$
     'wnd'+fileext+date1+date2+yr
;  psfilenametmp1='/usr/users/mpkryn/windanalysis/'+location+'/'+ $
;     yr+'/'+datatype+'/psfiles/'+'wnd'+fileext+date1+date2+yr
 endelse
endif else begin
  plottitle1=plottype+' Winds in the Upper Thermosphere!C'+ $
   site+', '+month1+' '+day1+' to '+month2+' '+day2+', 19'+yr+'.'
  xplottitle1='Dates in '+month1+' and '+month2+'.'
  psfilenametmp1='/usr/users/mpkryn/windanalysis/test/psfilestest/'+$
     'wnd'+fileext+date1+date2+yr
;  psfilenametmp1='/usr/users/mpkryn/windanalysis/'+location+'/'+ $
;     yr+'/'+datatype+'/psfiles/'+'wnd'+fileext+date1+date2+yr
endelse

if (max(windtot1) eq 10000) or (max(othwind1) eq 10000) then begin
  for s=0,m-1 do begin
   if (windtot1(s) eq 10000) then windtot1(s)=0.00001
  endfor
  for ss=0,mm-1 do begin
   if (othwind1(ss) eq 10000) then othwind1(ss)=0.00001
  endfor
  micky=max(windtot1) & minny=min(windtot1)
  if (max(othwind1) gt micky) then micky=max(othwind1)
  if (min(othwind1) lt minny) then minny=min(othwind1) 
  for s=0,m-1 do begin
   if (windtot1(s) eq 0.00001) then windtot1(s)=10000
  endfor
  for ss=0,mm-1 do begin
   if (othwind1(ss) eq 0.00001) then othwind1(ss)=10000
  endfor
endif else begin
  micky=max(windtot1) & minny=min(windtot1)
  if (max(othwind1) gt micky) then micky=max(othwind1)
  if (min(othwind1) lt minny) then minny=min(othwind1)
endelse

yranmaxval=0. & yranminval=0.
call_procedure,'defineylimits',micky,minny,yranmaxval,yranminval

if (min(timetot1) lt 0) then begin
 xranminval1=min(timetot1)
  if (datatype eq 'vertdata') then goto,smelly2
  if (min(othtime1) lt xranminval1) then xranminval1=min(othtime1)
 smelly2:
endif else begin
 xranminval1=0
  if (datatype eq 'vertdata') then goto,smelly3
  if (min(othtime1) lt xranminval1) then xranminval1=min(othtime1)
 smelly3:
endelse
xranmaxval1=p1*2400

;  this section checks to see if only one day's data will be
;  on the graph, in which case, the datadates array will change.
;  it also defines the relevant quantities for plotting parameters,
;  e.g.  tick length, etc.

lent1=1.0
silly1=0
line1=1
if (datatype ne 'vertdata') then silly1=-4

if (day1 eq day2) then begin
 lent1=0.05
 silly1=-4
 line1=0
 print,''
 print,''
 print, "you will be plotting data for only one day on plot number 1"
 print, "do you want the wind data displayed on:
 print,''
 print, "a.  a full 24 hour graph"
 print,''
 print, "b.  a graph using the first measurement's time"
 print, "    as the minimum time and the last measurement's"
 print, "    time as the maximum time"
 print,''
 print, "c.  pick your own times"
 print,''
 read,plotques
 print,''
 print,''
 soup=min(timetot1)
 soupest=max(timetot1)
 print,soup,soupest
 if (datatype eq 'vertdata') then goto,smelly4
 if (min(othtime1) lt soup) then soup=min(othtime1)
 if (max(othtime1) gt soupest) then soupest=max(othtime1)
 smelly4:
 souper=(soup+soupest)/2
 insouper=(souper+soup)/2
 outsouper=(souper+soupest)/2
 call_procedure,'crrctthetime',soup,souper,soupest,insouper,outsouper,$
   stup,stuper,stupest,instuper,outstuper
 if (plotques eq 'a') then begin
  p1=4
  datadates1=strarr(5)
  datadates1(1)='600' & datadates1(2)='1200' & datadates1(3)='1800' & $
  datadates1(4)='2400'
  xranmaxval1=2400
  if (soup lt 0) then begin
   xranminval1=soup & datadates1(0)=stup
  endif else begin
   xranminval1=0 & datadates1(0)='0000'
  endelse
 endif
 if (plotques eq 'b') then begin
  if (soup lt 0) then begin
   slam=fix(soup/100)-1
  endif else begin
   slam=fix(soup/100)
  endelse
  offslam=slam*100
  joe=fix(soupest/100)+1
  offjoe=joe*100
  print,slam,offslam
  print,joe,offjoe
  jam=joe-slam
  print,jam
  p1=round(jam/2.)
  print,p1
  datadates1=strarr(p1+1)
  first=offslam
  for poopoo=0,p1 do begin
   call_procedure,'crrctthetime',first,souper,soupest,insouper,outsouper,$
   stup,stuper,stupest,instuper,outstuper
   datadates1(poopoo)=stup
   if poopoo eq p1 then xranmaxval1=first
   first=first+200
  endfor
;  datadates1=[stup,instuper,stuper,outstuper,stupest]
  xranminval1=offslam 
; xranmaxval1=offjoe
 endif
 if (plotques eq 'c') then begin
  print,''
  print, "enter the minimum time, using a decimal format, e.g."
  print, 'use 5.0 to indicate 5:00'
  print,''
  read, soup
  print,''
  print, "enter the maximum time"
  print,''
  read, soupest
  print,''
  soup=fix(soup*100)
  soupest=fix(soupest*100)
  souper=(soup+soupest)/2
  insouper=(souper+soup)/2
  outsouper=(souper+soupest)/2
  if (soup lt 0) then begin
   slam=fix(soup/100)-1
  endif else begin
   slam=fix(soup/100)
  endelse
  offslam=slam*100
  joe=fix(soupest/100)+1
  offjoe=joe*100
  jam=joe-slam
  p1=round(jam/2.)
  datadates1=strarr(p1+1)
  first=offslam
  for poopoo=0,p1 do begin
   call_procedure,'crrctthetime',first,souper,soupest,insouper,outsouper,$
   stup,stuper,stupest,instuper,outstuper
   datadates1(poopoo)=stup
   if poopoo eq p1 then xranmaxval1=first
   first=first+200
  endfor
  xranminval1=offslam
; xranmaxval1=offjoe
;  call_procedure,'crrctthetime',soup,souper,soupest,insouper,outsouper,$
;    stup,stuper,stupest,instuper,outstuper
;  datadates1=[stup,instuper,stuper,outstuper,stupest]
;  xranminval1=soup & xranmaxval1=soupest
 endif
endif

return

end

;  subroutine for storing all of plot 2's info. 

pro twoplot,windtot2,othwind2,othtime2,mnthval1,mnthval2,plotnumber,$
    fileext,datatype,location,site,plottype,lent2,silly2,line2,$
    timetot2,datadates2,yranmaxval,yranminval,xranmaxval2,$
    xranminval2,plottitle2,xplottitle2,yr,date,month1,day1,month2,$
    day2,date1,dat1,dat2,date2,m,k,mm,kk,p2,t2,psfilenametmp1,$
    psfilenametmp2,wnderr2,othwnderr2

switch=''
thefile=''
fulldate=''
tmdate=''
plotques=''
psfilenametmp2=''

;  these values need to be in the looping so that they
;  can change for each opened data file.

continuebuild:

dat=fix(date)
mnthval=strmid(date,0,1)
day=strmid(date,1,2)

;  defining the data filename

thefile='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+'/'+ $
    datatype+'/'+fileext+date+'.dbt'

;  open and read the file to determine the size.
;  and go to the relevant section to add null data,
;  see below for details.

openr,3,thefile,error=bad
if (bad ne 0) then print, "there is no data for "+date
if (bad ne 0) then print,''
if (bad ne 0) then begin

;  if there is no data for a given day, then add bad data to the
;  all days arrays, which will consequently be ignored by the
;  plotting routines.  this section must be skipped the first time
;  around.
;  bad is the open file error variable.
;  storing the all days arrays first.

  storetime1=lonarr(m)
  storewind1=fltarr(m)
  storetime1(*)=timetot2(*)
  storewind1(*)=windtot2(*)
  storewinderr1(*)=wnderr2(*)
  g=m
  m=m+n
  timetot2=lonarr(m)
  windtot2=fltarr(m)
  wnderr2=fltarr(m)
  for l=0,g-1 do begin
   timetot2(l)=storetime1(l)
   windtot2(l)=storewind1(l)
   wnderr2(l)=storewinderr1(l)
  endfor
  h=0
 addnulldata:
  timetot2(k)=(p2*2400)+ttime1(h)
  windtot2(k)=10000
  wnderr2(k)=10000
  k=k+1 & h=h+1
  if (h lt n) then goto, addnulldata

 if (datatype eq 'vertdata') then goto,smelly
  storetime2=lonarr(mm)
  storewind2=fltarr(mm)
  storewinderr2=fltarr(mm)
  storetime2(*)=othtime2(*)
  storewind2(*)=othwind2(*)
  storewinderr2(*)=othwnderr2(*)
  gg=mm
  mm=mm+nn
  othtime2=lonarr(mm)
  othwind2=fltarr(mm)
  othwnderr2=fltarr(mm)
  for ll=0,gg-1 do begin
   othtime2(ll)=storetime2(ll)
   othwind2(ll)=storewind2(ll)
   othwnderr2(ll)=storewinderr2(ll)
  endfor
  hh=0
 adothnlldt:
  othtime2(kk)=(p2*2400)+ttime2(hh)
  othwind2(kk)=10000
  othwnderr2(kk)=10000
  kk=kk+1 & hh=hh+1
  if (hh lt nn) then goto,adothnlldt
 smelly:
endif
if (bad ne 0) then goto, skipreldata

;  ok, here we go.
;  n and nn define the size of each datafile after it is read.
;  define the array sizes and types for the day's data

if (datatype eq 'vertdata') then begin
 j=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
    if (dum5 gt 250) or (dum5 lt -250) then goto, dontincre
 j=j+1
 dontincre:
 endwhile
 n=j
 ttime1=lonarr(n)
 twind1=fltarr(n)
 twinderr1=fltarr(n)
endif
if (datatype eq 'merddata') or (datatype eq 'zonedata') then begin
 j=0 & d=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
    if (dum4 eq 30) and (dum3 eq 0) then begin
     j=j+1
    endif
    if (dum4 eq 30) and (dum3 eq 180) then begin
     d=d+1
    endif
    if (dum4 eq 30) and (dum3 eq 90) then begin
     j=j+1
    endif
    if (dum4 eq 30) and (dum3 eq 270) then begin
     d=d+1
    endif
 endwhile
 n=j
 nn=d
 ttime1=lonarr(n)
 ttime2=lonarr(nn)
 twind1=fltarr(n)
 twind2=fltarr(nn)
 twinderr1=fltarr(n)
 twinderr2=fltarr(nn)
endif
close,3

;  open it now to read it and store the data

openr,3,thefile
if (datatype eq 'vertdata') then begin
 i=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
   if (dum5 gt 250) or (dum5 lt -250) then goto, dontdoit
    tmdate=strmid(fulldate,3,3)
   if (tmdate ne date) then begin
    if (location eq 'southpole') and (yr eq '91') then begin
;or $
;     (location eq 'inuvik') then begin
      ttime1(i)=dum2-2360
    endif else begin
      ttime1(i)=dum2-2400
    endelse
   endif else begin
    ttime1(i)=dum2
   endelse
   twind1(i)=dum5
   twinderr1(i)=dum6
 i=i+1
 dontdoit:
 endwhile
endif
if (datatype eq 'merddata') or (datatype eq 'zonedata') then begin
 i=0 & dd=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
    tmdate=strmid(fulldate,3,3)
    if (dum4 eq 30) and (dum3 eq 0) then begin
     twind1(i)=dum5
     twinderr1(i)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime1(i)=dum2
     endelse
     i=i+1
    endif
    if (dum4 eq 30) and (dum3 eq 180) then begin
     twind2(dd)=dum5
     twinderr2(dd)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime2(dd)=dum2
     endelse
     dd=dd+1
    endif
    if (dum4 eq 30) and (dum3 eq 90) then begin
     twind1(i)=dum5
     twinderr1(i)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime1(i)=dum2
     endelse
     i=i+1
    endif
    if (dum4 eq 30) and (dum3 eq 270) then begin
     twind2(dd)=dum5
     twinderr2(dd)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime2(dd)=dum2
     endelse
     dd=dd+1
    endif
 endwhile
endif
close,3

;  start building the all days arrays, skipping the storage phase
;  on the first go around.

;  m defines the size of the all days arrays
;  g is used as a go-between for the storage arrays,
;  when we need to redefine the size of the all days arrays.

g=m
m=m+n
if (g eq 0) then goto, dontstore
  storetime1=lonarr(g)
  storewind1=fltarr(g)
  storewinderr1=fltarr(g)
  storetime1(*)=timetot2(*)
  storewind1(*)=windtot2(*)
  storewinderr1(*)=wnderr2(*)
dontstore:
timetot2=lonarr(m)
windtot2=fltarr(m)
if (g eq 0) then goto, skippedpart
 for l=0,g-1 do begin
  timetot2(l)=storetime1(l)
  windtot2(l)=storewind1(l)
  wnderr2(l)=storewinderr1(l)
 endfor
skippedpart:

;  build the all days arrays
h=0
daysarray:
 timetot2(k)=(p2*2400)+ttime1(h)
 windtot2(k)=twind1(h)
 wnderr2(k)=twinderr1(h)
k=k+1 & h=h+1
if (h lt n) then goto, daysarray

if (datatype eq 'vertdata') then goto,smelly1
gg=mm
mm=mm+nn
if (gg eq 0) then goto,donotstor
  storetime2=lonarr(gg)
  storewind2=fltarr(gg)
  storewinderr2=fltarr(gg)
  storetime2(*)=othtime2(*)
  storewind2(*)=othwind2(*)
  storewinderr2(*)=othwnderr2(*)
donotstor:
othtime2=lonarr(mm)
othwind2=fltarr(mm)
othwnderr2=fltarr(mm)
if (gg eq 0) then goto,skippypart
 for ll=0,gg-1 do begin
  othtime2(ll)=storetime2(ll)
  othwind2(ll)=storewind2(ll)
  othwnderr2(ll)=storewinderr2(ll)
 endfor
skippypart:
hh=0
othdayarr:
 othtime2(kk)=(p2*2400)+ttime2(hh)
 othwind2(kk)=twind2(hh)
 othwnderr2(kk)=twinderr2(hh)
kk=kk+1 & hh=hh+1
if (hh lt nn) then goto,othdayarr
smelly1:

;  this is the line that is jumped to if there was no data for
;  a given day.  null data would have been stored instead, then
;  the program would come here

skipreldata:

;  now, creating the data dates array, which is used in
;  the plotting procedures as the xaxis of time.

;  p+(pltnum) is the tick number for the all days plots
;  it acts as the datadates array size until the end where
;  then a last day is added to the datadates array to finish
;  off the relevant xtick_name file information.  t then becomes
;  the datadates array size at that point.  p is important though
;  as it defines the tick number.  q acts as the go-between when
;  storing the date info.

q2=p2
p2=p2+1

if (q2 eq 0) then goto, notstoredate
  storedateinfo=strarr(q2)
  storedateinfo(*)=datadates2(*)
notstoredate:

datadates2=strarr(p2)

if (q2 eq 0) then goto, datearray
 for r=0,q2-1 do begin
  datadates2(r)=storedateinfo(r)
 endfor
datearray:

datadates2(t2)=day
t2=t2+1

; the following call changes the date string and the switch string
; if it is necessary.  that is, if the data range covers
; different months, we need to properly change the date string
; so that the computer knows what to look for.

call_procedure, 'chngmnthdate',mnthval,day,date,switch

;  the dat and dat2 variables are used to determine if we are
;  done reading data, then go to the plotting section.

if (dat eq dat2) then goto, finalizearray

;  didn't go to next range of data so now check for a switch,
;  that is, did month change.

if (switch ne 'y') then begin
 dat=dat+1
 date=strcompress(dat,/remove_all)
endif

;  set switch back
switch=''

;  return to top to continue looping thru requested data range

goto, continuebuild

;  this section is for adding the last element to the
;  datadates array, used for the x-axis plotting

finalizearray:
storedateinfo=strarr(p2)
storedateinfo(*)=datadates2(*)
q2=p2
t2=t2+1
datadates2=strarr(t2)
for r=0,q2-1 do begin
 datadates2(r)=storedateinfo(r)
endfor
dat=dat+1
lastdate=strcompress(dat,/remove_all)
lastday=strmid(lastdate,1,2)
lastmnthval=strmid(lastdate,0,1)

call_procedure, 'crrctlastday',lastmnthval,lastday

datadates2(t2-1)=lastday

if (location eq 'southpole') and (yr eq '91') then begin
;or $
; (location eq 'inuvik') then begin
 flttime=fltarr(m)
 for j=0,m-1 do begin
  thtime=timetot2(j)
  call_procedure,'cortodectime',thtime
  flttime(j)=thtime
 endfor
 timetot2=fix(flttime*100)
 if (datatype eq 'merddata') or (datatype eq 'zonedata') then begin
  othflttime=fltarr(mm)
  for j=0,mm-1 do begin
   thtime=othtime2(j)
   call_procedure,'cortodectime',thtime
   othflttime(j)=thtime
  endfor
  othtime2=fix(othflttime*100)
 endif
endif

;  this section makes the plot titles for the wind plot of
;  all the days

if (mnthval1 eq mnthval2) then begin
 if (day1 eq day2) then begin
  if (plotnumber ne 3) and (plotnumber ne 4) then begin
   plottitle2=plottype+' Winds in the Upper Thermosphere!C'+ $
    site+', '+month1+' '+day1+', 19'+yr+'.'
   xplottitle2='Time in UT.'
   psfilenametmp2=psfilenametmp1+fileext+date1+yr
  endif else begin
   plottitle2=site+', '+month1+' '+day1+', 19'+yr+'.'
   xplottitle2='Time in UT.'
   psfilenametmp2=psfilenametmp1+fileext+date1+yr
  endelse
 endif else begin
  if (plotnumber ne 3) and (plotnumber ne 4) then begin
   plottitle2=plottype+' Winds in the Upper Thermosphere!C'+ $
    site+', '+month1+' '+day1+' to '+day2+', 19'+yr+'.'
   xplottitle2='Dates in '+month1+'.'
   psfilenametmp2=psfilenametmp1+fileext+date1+date2+yr
  endif else begin
   plottitle2=site+', '+month1+' '+day1+' to '+day2+', 19'+yr+'.'
   xplottitle2='Dates in '+month1+'.'
   psfilenametmp2=psfilenametmp1+fileext+date1+date2+yr
  endelse
 endelse
endif else begin
  if (plotnumber eq 3) or (plotnumber eq 4) then begin
   plottitle2=site+', '+month1+' '+day1+' to '+month2+' '+$
    day2+', 19'+yr+'.'
   xplottitle2='Dates in '+month1+' and '+month2+'.'
   psfilenametmp2=psfilenametmp1+fileext+date1+date2+yr
  endif else begin
   plottitle2=plottype+' Winds in the Upper Thermosphere!C'+ $
    site+', '+month1+' '+day1+' to '+month2+' '+day2+', 19'+yr+'.'
   xplottitle2='Dates in '+month1+' and '+month2+'.'
   psfilenametmp2=psfilenametmp1+fileext+date1+date2+yr
  endelse
endelse

if (max(windtot2) eq 10000) or (max(othwind2) eq 10000) then begin
  for s=0,m-1 do begin
   if (windtot2(s) eq 10000) then windtot2(s)=0.00001
  endfor
  for ss=0,mm-1 do begin
   if (othwind2(ss) eq 10000) then othwind2(ss)=0.00001
  endfor
  micky=max(windtot2) & minny=min(windtot2)
  if (max(othwind2) gt micky) then micky=max(othwind2)
  if (min(othwind2) lt minny) then minny=min(othwind2)
  for s=0,m-1 do begin
   if (windtot2(s) eq 0.00001) then windtot2(s)=10000
  endfor
  for ss=0,mm-1 do begin
   if (othwind2(ss) eq 0.00001) then othwind2(ss)=10000
  endfor
endif else begin
  micky=max(windtot2) & minny=min(windtot2)
  if (max(othwind2) gt micky) then micky=max(othwind2)
  if (min(othwind2) lt minny) then minny=min(othwind2)
endelse

if (micky gt yranmaxval) or (minny lt yranminval) then begin
  call_procedure,'defineylimits',micky,minny,yranmaxval,yranminval
endif

if (min(timetot2) lt 0) then begin
 xranminval2=min(timetot2)
  if (datatype eq 'vertdata') then goto,smelly2
  if (min(othtime2) lt xranminval2) then xranminval2=min(othtime2)
 smelly2:
endif else begin
 xranminval2=0
  if (datatype eq 'vertdata') then goto,smelly3
  if (min(othtime2) lt xranminval2) then xranminval2=min(othtime2)
 smelly3:
endelse
xranmaxval2=p2*2400

;  this section checks to see if only one day's data will be
;  on the graph, in which case, the datadates array will change.
;  it also defines the relevant quantities for plotting parameters,
;  e.g.  tick length, etc.

lent2=1.0
silly2=0
line2=1

if (day1 eq day2) then begin
 lent2=0.05
 silly2=-4
 line2=0
 print,''
 print,''
 print, "you will be plotting data for only one day on plot number 2"
 print, "do you want the wind data displayed on:
 print,''
 print, "a.  a full 24 hour graph"
 print,''
 print, "b.  a graph using the first measurement's time"
 print, "    as the minimum time and the last measurement's"
 print, "    time as the maximum time"
 print,''
 print, "c.  pick your own times"
 print,''
 read,plotques
 print,''
 print,''
 soup=min(timetot2)
 soupest=max(timetot2)
 if (datatype eq 'vertdata') then goto,smelly4
 if (min(othtime2) lt soup) then soup=min(othtime2)
 if (max(othtime2) gt soupest) then soupest=max(othtime2)
 smelly4:
 souper=(soup+soupest)/2
 insouper=(souper+soup)/2
 outsouper=(souper+soupest)/2
 call_procedure,'crrctthetime',soup,souper,soupest,insouper,outsouper,$
   stup,stuper,stupest,instuper,outstuper
 if (plotques eq 'a') then begin
  p2=4
  datadates2=strarr(5)
  datadates2(1)='600' & datadates2(2)='1200' & datadates2(3)='1800' & $
  datadates2(4)='2400'
  xranmaxval2=2400
  if (soup lt 0) then begin
   xranminval2=soup & datadates2(0)=stup
  endif else begin
   xranminval2=0 & datadates2(0)='0000'
  endelse
 endif
 if (plotques eq 'b') then begin
  if (soup lt 0) then begin
   slam=fix(soup/100)-1
  endif else begin
   slam=fix(soup/100)
  endelse
  offslam=slam*100
  joe=fix(soupest/100)+1
  offjoe=joe*100
  jam=joe-slam
  p2=round(jam/2.)
  datadates2=strarr(p2+1)
  first=offslam
  for poopoo=0,p2 do begin
   call_procedure,'crrctthetime',first,souper,soupest,insouper,outsouper,$
   stup,stuper,stupest,instuper,outstuper
   datadates2(poopoo)=stup
   if poopoo eq p2 then xranmaxval2=first
   first=first+200
  endfor
;  datadates2=[stup,instuper,stuper,outstuper,stupest]
  xranminval2=offslam
; xranmaxval2=offjoe
 endif
 if (plotques eq 'c') then begin
  print,''
  print, "enter the minimum time, using a decimal format, e.g."
  print, 'use 5.0 to indicate 5:00'
  print,''
  read, soup
  print,''
  print, "enter the maximum time"
  print,''
  read, soupest
  print,''
  soup=fix(soup*100)
  soupest=fix(soupest*100)
  souper=(soup+soupest)/2
  insouper=(souper+soup)/2
  outsouper=(souper+soupest)/2
  if (soup lt 0) then begin
   slam=fix(soup/100)-1
  endif else begin
   slam=fix(soup/100)
  endelse
  offslam=slam*100
  joe=fix(soupest/100)+1
  offjoe=joe*100
  jam=joe-slam
  p2=round(jam/2.)
  datadates2=strarr(p2+1)
  first=offslam
  for poopoo=0,p2 do begin
   call_procedure,'crrctthetime',first,souper,soupest,insouper,outsouper,$
   stup,stuper,stupest,instuper,outstuper
   datadates2(poopoo)=stup
   if poopoo eq p2 then xranmaxval2=first
   first=first+200
  endfor
  xranminval2=offslam
;xranmaxval2=offjoe
;  call_procedure,'crrctthetime',soup,souper,soupest,insouper,outsouper,$
;    stup,stuper,stupest,instuper,outstuper
;  datadates2=[stup,instuper,stuper,outstuper,stupest]
;  xranminval2=soup & xranmaxval2=soupest
 endif
endif

return

end

;  subroutine for storing all of plot 3's info. 

pro threeplot,windtot3,othwind3,othtime3,mnthval1,mnthval2,plotnumber,$
    fileext,datatype,location,site,plottype,lent3,silly3,line3,$
    timetot3,datadates3,yranmaxval,yranminval,xranmaxval3,$
    xranminval3,plottitle3,xplottitle3,yr,date,month1,day1,month2,$
    day2,date1,dat1,dat2,date2,m,k,mm,kk,p3,t3,psfilenametmp2,$
    psfilenametmp3,wnderr3,othwnderr3

switch=''
thefile=''
fulldate=''
tmdate=''
plotques=''
psfilenametmp3=''

;  these values need to be in the looping so that they
;  can change for each opened data file.

continuebuild:

dat=fix(date)
mnthval=strmid(date,0,1)
day=strmid(date,1,2)

;  defining the data filename

thefile='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+'/'+ $
    datatype+'/'+fileext+date+'.dbt'

;  open and read the file to determine the size.
;  and go to the relevant section to add null data,
;  see below for details.

openr,3,thefile,error=bad
if (bad ne 0) then print, "there is no data for "+date
if (bad ne 0) then print,''
if (bad ne 0) then begin

;  if there is no data for a given day, then add bad data to the
;  all days arrays, which will consequently be ignored by the
;  plotting routines.  this section must be skipped the first time
;  around.
;  bad is the open file error variable.
;  storing the all days arrays first.

  storetime1=lonarr(m)
  storewind1=fltarr(m)
  storewinderr1=fltarr(m)
  storetime1(*)=timetot3(*)
  storewind1(*)=windtot3(*)
  storewinderr1(*)=wnderr3(*)
  g=m
  m=m+n
  timetot3=lonarr(m)
  windtot3=fltarr(m)
  wnderr3=fltarr(m)
  for l=0,g-1 do begin
   timetot3(l)=storetime1(l)
   windtot3(l)=storewind1(l)
   wnderr3(l)=storewinderr1(l)
  endfor
  h=0
 addnulldata:
  timetot3(k)=(p3*2400)+ttime1(h)
  windtot3(k)=10000
  wnderr3(k)=10000
  k=k+1 & h=h+1
  if (h lt n) then goto, addnulldata

 if (datatype eq 'vertdata') then goto,smelly
  storetime2=lonarr(mm)
  storewind2=fltarr(mm)
  storewinderr2=fltarr(mm)
  storetime2(*)=othtime3(*)
  storewind2(*)=othwind3(*)
  storewinderr2(*)=othwnderr3(*)
  gg=mm
  mm=mm+nn
  othtime3=lonarr(mm)
  othwind3=fltarr(mm)
  othwnderr3=fltarr(mm)
  for ll=0,gg-1 do begin
   othtime3(ll)=storetime2(ll)
   othwind3(ll)=storewind2(ll)
   othwnderr3(ll)=storewind2(ll)
  endfor
  hh=0
 adothnlldt:
  othtime3(kk)=(p3*2400)+ttime2(hh)
  othwind3(kk)=10000
  othwnderr3(kk)=10000
  kk=kk+1 & hh=hh+1
  if (hh lt nn) then goto,adothnlldt
 smelly:
endif
if (bad ne 0) then goto, skipreldata

;  ok, here we go.
;  n and nn define the size of each datafile after it is read.
;  define the array sizes and types for the day's data

if (datatype eq 'vertdata') then begin
 j=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
    if (dum5 gt 250) or (dum5 lt -250) then goto, dontincre
 j=j+1
 dontincre:
 endwhile
 n=j
 ttime1=lonarr(n)
 twind1=fltarr(n)
 twinderr1=fltarr(n)
endif
if (datatype eq 'merddata') or (datatype eq 'zonedata') then begin
 j=0 & d=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
    if (dum4 eq 30) and (dum3 eq 0) then begin
     j=j+1
    endif
    if (dum4 eq 30) and (dum3 eq 180) then begin
     d=d+1
    endif
    if (dum4 eq 30) and (dum3 eq 90) then begin
     j=j+1
    endif
    if (dum4 eq 30) and (dum3 eq 270) then begin
     d=d+1
    endif
 endwhile
 n=j
 nn=d
 ttime1=lonarr(n)
 ttime2=lonarr(nn)
 twind1=fltarr(n)
 twind2=fltarr(nn)
 twinderr1=fltarr(n)
 twinderr2=fltarr(nn)
endif
close,3

;  open it now to read it and store the data

openr,3,thefile
if (datatype eq 'vertdata') then begin
 i=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
   if (dum5 gt 250) or (dum5 lt -250) then goto, dontdoit
    tmdate=strmid(fulldate,3,3)
   if (tmdate ne date) then begin
    if (location eq 'southpole') and (yr eq '91') then begin
;or $
;     (location eq 'inuvik') then begin
      ttime1(i)=dum2-2360
    endif else begin
      ttime1(i)=dum2-2400
    endelse
   endif else begin
    ttime1(i)=dum2
   endelse
   twind1(i)=dum5
   twinderr1(i)=dum6
 i=i+1
 dontdoit:
 endwhile
endif
if (datatype eq 'merddata') or (datatype eq 'zonedata') then begin
 i=0 & dd=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
    tmdate=strmid(fulldate,3,3)
    if (dum4 eq 30) and (dum3 eq 0) then begin
     twind1(i)=dum5
     twinderr1(i)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime1(i)=dum2
     endelse
     i=i+1
    endif
    if (dum4 eq 30) and (dum3 eq 180) then begin
     twind2(dd)=dum5
     twinderr2(dd)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime2(dd)=dum2
     endelse
     dd=dd+1
    endif
    if (dum4 eq 30) and (dum3 eq 90) then begin
     twind1(i)=dum5
     twinderr1(i)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime1(i)=dum2
     endelse
     i=i+1
    endif
    if (dum4 eq 30) and (dum3 eq 270) then begin
     twind2(dd)=dum5
     twinderr2(dd)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime2(dd)=dum2
     endelse
     dd=dd+1
    endif
 endwhile
endif
close,3

;  start building the all days arrays, skipping the storage phase
;  on the first go around.

;  m defines the size of the all days arrays
;  g is used as a go-between for the storage arrays,
;  when we need to redefine the size of the all days arrays.

g=m
m=m+n
if (g eq 0) then goto, dontstore
  storetime1=lonarr(g)
  storewind1=fltarr(g)
  storewinderr1=fltarr(g)
  storetime1(*)=timetot3(*)
  storewind1(*)=windtot3(*)
  storewind1(*)=wnderr3(*)
dontstore:
timetot3=lonarr(m)
windtot3=fltarr(m)
wnderr3=fltarr(m)
if (g eq 0) then goto, skippedpart
 for l=0,g-1 do begin
  timetot3(l)=storetime1(l)
  windtot3(l)=storewind1(l)
  wnderr3(l)=storewinderr1(l)
 endfor
skippedpart:

;  build the all days arrays
h=0
daysarray:
 timetot3(k)=(p3*2400)+ttime1(h)
 windtot3(k)=twind1(h)
 wnderr3(k)=twinderr1(h)
k=k+1 & h=h+1
if (h lt n) then goto, daysarray

if (datatype eq 'vertdata') then goto,smelly1
gg=mm
mm=mm+nn
if (gg eq 0) then goto,donotstor
  storetime2=lonarr(gg)
  storewind2=fltarr(gg)
  storewinderr2=fltarr(gg)
  storetime2(*)=othtime3(*)
  storewind2(*)=othwind3(*)
  storewinderr2(*)=othwnderr3(*)
donotstor:
othtime3=lonarr(mm)
othwind3=fltarr(mm)
othwnderr3=fltarr(mm)
if (gg eq 0) then goto,skippypart
 for ll=0,gg-1 do begin
  othtime3(ll)=storetime2(ll)
  othwind3(ll)=storewind2(ll)
  othwnderr3(ll)=storewinderr2(ll)
 endfor
skippypart:
hh=0
othdayarr:
 othtime3(kk)=(p3*2400)+ttime2(hh)
 othwind3(kk)=twind2(hh)
 othwnderr3(kk)=twinderr2(hh)
kk=kk+1 & hh=hh+1
if (hh lt nn) then goto,othdayarr
smelly1:

;  this is the line that is jumped to if there was no data for
;  a given day.  null data would have been stored instead, then
;  the program would come here

skipreldata:

;  now, creating the data dates array, which is used in
;  the plotting procedures as the xaxis of time.

;  p+(pltnum) is the tick number for the all days plots
;  it acts as the datadates array size until the end where
;  then a last day is added to the datadates array to finish
;  off the relevant xtick_name file information.  t then becomes
;  the datadates array size at that point.  p is important though
;  as it defines the tick number.  q acts as the go-between when
;  storing the date info.

q3=p3
p3=p3+1

if (q3 eq 0) then goto, notstoredate
  storedateinfo=strarr(q3)
  storedateinfo(*)=datadates3(*)
notstoredate:

datadates3=strarr(p3)

if (q3 eq 0) then goto, datearray
 for r=0,q3-1 do begin
  datadates3(r)=storedateinfo(r)
 endfor
datearray:

datadates3(t3)=day
t3=t3+1

; the following call changes the date string and the switch string
; if it is necessary.  that is, if the data range covers
; different months, we need to properly change the date string
; so that the computer knows what to look for.
                                                                         
call_procedure,'chngmnthdate',mnthval,day,date,switch

;  the dat and dat2 variables are used to determine if we are
;  done reading data, then go to the plotting section.

if (dat eq dat2) then goto, finalizearray

;  didn't go to next range of data so now check for a switch,
;  that is, did month change.

if (switch ne 'y') then begin
 dat=dat+1
 date=strcompress(dat,/remove_all)
endif

;  set switch back
switch=''

;  return to top to continue looping thru requested data range

goto, continuebuild

;  this section is for adding the last element to the
;  datadates array, used for the x-axis plotting

finalizearray:
storedateinfo=strarr(p3)
storedateinfo(*)=datadates3(*)
q3=p3
t3=t3+1
datadates3=strarr(t3)
for r=0,q3-1 do begin
 datadates3(r)=storedateinfo(r)
endfor
dat=dat+1
lastdate=strcompress(dat,/remove_all)
lastday=strmid(lastdate,1,2)
lastmnthval=strmid(lastdate,0,1)

call_procedure,'crrctlastday',lastmnthval,lastday

datadates3(t3-1)=lastday

if (location eq 'southpole') and (yr eq '91') then begin
;or $
; (location eq 'inuvik') then begin
 flttime=fltarr(m)
 for j=0,m-1 do begin
  thtime=timetot3(j)
  call_procedure,'cortodectime',thtime
  flttime(j)=thtime
 endfor
 timetot3=fix(flttime*100)
 if (datatype eq 'merddata') or (datatype eq 'zonedata') then begin
  othflttime=fltarr(mm)
  for j=0,mm-1 do begin
   thtime=othtime3(j)
   call_procedure,'cortodectime',thtime
   othflttime(j)=thtime
  endfor
  othtime3=fix(othflttime*100)
 endif
endif

;  this section makes the plot titles for the wind plot of
;  all the days

if (mnthval1 eq mnthval2) then begin
 if (day1 eq day2) then begin
   plottitle3=site+', '+month1+' '+day1+', 19'+yr+'.'
   xplottitle3='Time in UT.'
   psfilenametmp3=psfilenametmp2+fileext+date1+yr
 endif else begin
   plottitle3=site+', '+month1+' '+day1+' to '+day2+', 19'+yr+'.'
   xplottitle3='Dates in '+month1+'.'
   psfilenametmp3=psfilenametmp2+fileext+date1+date2+yr
 endelse
endif else begin
   plottitle3=site+', '+month1+' '+day1+' to '+month2+' '+day2+$
    ', 19'+yr+'.'
   xplottitle3='Dates in '+month1+' and '+month2+'.'
   psfilenametmp3=psfilenametmp2+fileext+date1+date2+yr
endelse

if (max(windtot3) eq 10000) or (max(othwind3) eq 10000) then begin
  for s=0,m-1 do begin
   if (windtot3(s) eq 10000) then windtot3(s)=0.00001
  endfor
  for ss=0,mm-1 do begin
   if (othwind3(ss) eq 10000) then othwind3(ss)=0.00001
  endfor
  micky=max(windtot3) & minny=min(windtot3)
  if (max(othwind3) gt micky) then micky=max(othwind3)
  if (min(othwind3) lt minny) then minny=min(othwind3)
  for s=0,m-1 do begin
   if (windtot3(s) eq 0.00001) then windtot3(s)=10000
  endfor
  for ss=0,mm-1 do begin
   if (othwind3(ss) eq 0.00001) then othwind3(ss)=10000
  endfor
endif else begin
  micky=max(windtot3) & minny=min(windtot3)
  if (max(othwind3) gt micky) then micky=max(othwind3)
  if (min(othwind3) lt minny) then minny=min(othwind3)
endelse

if (micky gt yranmaxval) or (minny lt yranminval) then begin
  call_procedure,'defineylimits',micky,minny,yranmaxval,yranminval
endif

if (min(timetot3) lt 0) then begin
 xranminval3=min(timetot3)
  if (datatype eq 'vertdata') then goto,smelly2
  if (min(othtime3) lt xranminval3) then xranminval3=min(othtime3)
 smelly2:
endif else begin
 xranminval3=0
  if (datatype eq 'vertdata') then goto,smelly3
  if (min(othtime3) lt xranminval3) then xranminval3=min(othtime3)
 smelly3:
endelse
xranmaxval3=p3*2400

;  this section checks to see if only one day's data will be
;  on the graph, in which case, the datadates array will change.
;  it also defines the relevant quantities for plotting parameters,
;  e.g.  tick length, etc.

lent3=1.0
silly3=0
line3=1

if (day1 eq day2) then begin
 lent3=0.05
 silly3=-4
 line3=0
 print,''
 print,''
 print, "you will be plotting data for only one day on plot number 3"
 print, "do you want the wind data displayed on:"
 print,''
 print, "a.  a full 24 hour graph"
 print,''
 print, "b.  a graph using the first measurement's time"
 print, "    as the minimum time and the last measurement's"
 print, "    time as the maximum time"
 print,''
 print, "c.  pick your own times
 read,plotques
 print,''
 print,''
 soup=min(timetot3)
 soupest=max(timetot3)
 if (datatype eq 'vertdata') then goto,smelly4
 if (min(othtime3) lt soup) then soup=min(othtime3)
 if (max(othtime3) gt soupest) then soupest=max(othtime3)
 smelly4:
 souper=(soup+soupest)/2
 insouper=(souper+soup)/2
 outsouper=(souper+soupest)/2
 call_procedure,'crrctthetime',soup,souper,soupest,insouper,outsouper,$
    stup,stuper,stupest,instuper,outstuper
 if (plotques eq 'a') then begin
  p3=4
  datadates3=strarr(5)
  datadates3(1)='600' & datadates3(2)='1200' & datadates3(3)='1800' & $
  datadates3(4)='2400'
  xranmaxval3=2400
  if (soup lt 0) then begin
   xranminval3=soup & datadates3(0)=stup
  endif else begin
   xranminval3=0 & datadates3(0)='0000'
  endelse
 endif
 if (plotques eq 'b') then begin
  if (soup lt 0) then begin
   slam=fix(soup/100)-1
  endif else begin
   slam=fix(soup)
  endelse
  offslam=slam*100
  joe=fix(soupest/100)+1
  offjoe=joe*100
  jam=joe-slam
  p3=round(jam/2.)
  datadates3=strarr(p3+1)
  first=offslam
  for poopoo=0,p3 do begin
   call_procedure,'crrctthetime',first,souper,soupest,insouper,outsouper,$
   stup,stuper,stupest,instuper,outstuper
   datadates3(poopoo)=stup
   if poopoo eq p3 then xranmaxval3=first
   first=first+200
  endfor
  xranminval3=offslam
;xranmaxval3=offjoe
;  datadates3=[stup,instuper,stuper,outstuper,stupest]
 endif
 if (plotques eq 'c') then begin
  print,''
  print, "enter the minimum time, using a decimal format, e.g."
  print, 'use 5.0 to indicate 5:00'
  print,''
  read, soup
  print,''
  print, "enter the maximum time"
  print,''
  read, soupest
  print,''
  soup=fix(soup*100)
  soupest=fix(soupest*100)
  souper=(soup+soupest)/2
  insouper=(souper+soup)/2
  outsouper=(souper+soupest)/2
  if (soup lt 0) then begin
   slam=fix(soup/100)-1
  endif else begin
   slam=fix(soup/100)
  endelse
  offslam=slam*100
  joe=fix(soupest/100)+1
  offjoe=joe*100
  jam=joe-slam
  p3=round(jam/2.)
  datadates3=strarr(p3+1)
  first=offslam
  for poopoo=0,p3 do begin
   call_procedure,'crrctthetime',first,souper,soupest,insouper,outsouper,$
   stup,stuper,stupest,instuper,outstuper
   datadates3(poopoo)=stup
   if poopoo eq p3 then xranmaxval3=first
   first=first+200
  endfor
  xranminval3=offslam
;xranmaxval3=offjoe
;  call_procedure,'crrctthetime',soup,souper,soupest,insouper,outsouper,$
;    stup,stuper,stupest,instuper,outstuper
;  datadates3=[stup,instuper,stuper,outstuper,stupest]
;  xranminval3=soup & xranmaxval3=soupest
 endif
endif

return

end

;  subroutine for storing all of plot 4's info. 

pro fourplot,windtot4,othwind4,othtime4,mnthval1,mnthval2,plotnumber,$
    fileext,datatype,location,site,plottype,lent4,silly4,line4,$
    timetot4,datadates4,yranmaxval,yranminval,xranmaxval4,$
    xranminval4,plottitle4,xplottitle4,yr,date,month1,day1,month2,$
    day2,date1,dat1,dat2,date2,m,k,mm,kk,p4,t4,psfilenametmp3,$
    psfilenametmp4,wnderr4,othwnderr4

switch=''
thefile=''
fulldate=''
tmdate=''
plotques=''
psfilenametmp4=''

;  these values need to be in the looping so that they
;  can change for each opened data file.

continuebuild:

dat=fix(date)
mnthval=strmid(date,0,1)
day=strmid(date,1,2)

;  defining the data filename

thefile='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+'/'+ $
    datatype+'/'+fileext+date+'.dbt'

;  open and read the file to determine the size.
;  and go to the relevant section to add null data,
;  see below for details.

openr,3,thefile,error=bad
if (bad ne 0) then print, "there is no data for "+date
if (bad ne 0) then print,''
if (bad ne 0) then begin

;  if there is no data for a given day, then add bad data to the
;  all days arrays, which will consequently be ignored by the
;  plotting routines.  this section must be skipped the first time
;  around.
;  bad is the open file error variable.
;  storing the all days arrays first.

  storetime1=lonarr(m)
  storewind1=fltarr(m)
  storewinderr1=fltarr(m)
  storetime1(*)=timetot4(*)
  storewind1(*)=windtot4(*)
  storewinderr1(*)=wnderr4(*)
  g=m
  m=m+n
  timetot4=lonarr(m)
  windtot4=fltarr(m)
  wnderr4=fltarr(m)
  for l=0,g-1 do begin
   timetot4(l)=storetime1(l)
   windtot4(l)=storewind1(l)
   wnderr4(l)=storewinderr1(l)
  endfor
  h=0
 addnulldata:
  timetot4(k)=(p4*2400)+ttime1(h)
  windtot4(k)=10000
  wnderr4(k)=10000
  k=k+1 & h=h+1
  if (h lt n) then goto, addnulldata

 if (datatype eq 'vertdata') then goto,smelly
  storetime2=lonarr(mm)
  storewind2=fltarr(mm)
  storewinderr2=fltarr(mm)
  storetime2(*)=othtime4(*)
  storewind2(*)=othwind4(*)
  storewinderr2(*)=othwnderr4(*)
  gg=mm
  mm=mm+nn
  othtime4=lonarr(mm)
  othwind4=fltarr(mm)
  othwnderr4=fltarr(mm)
  for ll=0,gg-1 do begin
   othtime4(ll)=storetime2(ll)
   othwind4(ll)=storewind2(ll)
   othwnderr4(ll)=storewinderr2(ll)
  endfor
  hh=0
 adothnlldt:
  othtime4(kk)=(p4*2400)+ttime2(hh)
  othwind4(kk)=10000
  othwnderr4(kk)=10000
  kk=kk+1 & hh=hh+1
  if (hh lt nn) then goto,adothnlldt
 smelly:
endif
if (bad ne 0) then goto, skipreldata

;  ok, here we go.
;  n and nn define the size of each datafile after it is read.
;  define the array sizes and types for the day's data

if (datatype eq 'vertdata') then begin
 j=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
    if (dum5 gt 250) or (dum5 lt -250) then goto, dontincre
 j=j+1
 dontincre:
 endwhile
 n=j
 ttime1=lonarr(n)
 twind1=fltarr(n)
 twinderr1=fltarr(n)
endif
if (datatype eq 'merddata') or (datatype eq 'zonedata') then begin
 j=0 & d=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
    if (dum4 eq 30) and (dum3 eq 0) then begin
     j=j+1
    endif
    if (dum4 eq 30) and (dum3 eq 180) then begin
     d=d+1
    endif
    if (dum4 eq 30) and (dum3 eq 90) then begin
     j=j+1
    endif
    if (dum4 eq 30) and (dum3 eq 270) then begin
     d=d+1
    endif
 endwhile
 n=j
 nn=d
 ttime1=lonarr(n)
 ttime2=lonarr(nn)
 twind1=fltarr(n)
 twind2=fltarr(nn)
 twinderr1=fltarr(n)
 twinderr2=fltarr(nn)
endif
close,3

;  open it now to read it and store the data

openr,3,thefile
if (datatype eq 'vertdata') then begin
 i=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
   if (dum5 gt 250) or (dum5 lt -250) then goto, dontdoit
    tmdate=strmid(fulldate,3,3)
   if (tmdate ne date) then begin
    if (location eq 'southpole') and (yr eq '91') then begin
;or $
;     (location eq 'inuvik') then begin
      ttime1(i)=dum2-2360
    endif else begin
      ttime1(i)=dum2-2400
    endelse
   endif else begin
    ttime1(i)=dum2
   endelse
   twind1(i)=dum5
   twinderr1(i)=dum6
 i=i+1
 dontdoit:
 endwhile
endif
if (datatype eq 'merddata') or (datatype eq 'zonedata') then begin
 i=0 & dd=0
 while (not eof(3)) do begin
  readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
    dum6,dum7,dum8,dum9
    tmdate=strmid(fulldate,3,3)
    if (dum4 eq 30) and (dum3 eq 0) then begin
     twind1(i)=dum5
     twinderr1(i)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime1(i)=dum2
     endelse
     i=i+1
    endif
    if (dum4 eq 30) and (dum3 eq 180) then begin
     twind2(dd)=dum5
     twinderr2(dd)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
; or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime2(dd)=dum2
     endelse
     dd=dd+1
    endif
    if (dum4 eq 30) and (dum3 eq 90) then begin
     twind1(i)=dum5
     twinderr1(i)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime1(i)=dum2
     endelse
     i=i+1
    endif
    if (dum4 eq 30) and (dum3 eq 270) then begin
     twind2(dd)=dum5
     twinderr2(dd)=dum6
     if (tmdate ne date) then begin
      if (location eq 'southpole') and (yr eq '91') then begin
;or $
;       (location eq 'inuvik') then begin
        ttime1(i)=dum2-2360
      endif else begin
        ttime1(i)=dum2-2400
      endelse
     endif else begin
      ttime2(dd)=dum2
     endelse
     dd=dd+1
    endif
 endwhile
endif
close,3

;  start building the all days arrays, skipping the storage phase
;  on the first go around.

;  m defines the size of the all days arrays
;  g is used as a go-between for the storage arrays,
;  when we need to redefine the size of the all days arrays.

g=m
m=m+n
if (g eq 0) then goto, dontstore
  storetime1=lonarr(g)
  storewind1=fltarr(g)
  storewinderr1=fltarr(g)
  storetime1(*)=timetot4(*)
  storewind1(*)=windtot4(*)
  storewinderr1(*)=wnderr4(*)
dontstore:
timetot4=lonarr(m)
windtot4=fltarr(m)
wnderr4=fltarr(m)
if (g eq 0) then goto, skippedpart
 for l=0,g-1 do begin
  timetot4(l)=storetime1(l)
  windtot4(l)=storewind1(l)
  wnderr4(l)=storewinderr1(l)
 endfor
skippedpart:

;  build the all days arrays
h=0
daysarray:
 timetot4(k)=(p4*2400)+ttime1(h)
 windtot4(k)=twind1(h)
 wnderr4(k)=twinderr1(h)
k=k+1 & h=h+1
if (h lt n) then goto, daysarray

if (datatype eq 'vertdata') then goto,smelly1
gg=mm
mm=mm+nn
if (gg eq 0) then goto,donotstor
  storetime2=lonarr(gg)
  storewind2=fltarr(gg)
  storewinderr2=fltarr(gg)
  storetime2(*)=othtime4(*)
  storewind2(*)=othwind4(*)
  storewinderr2(*)=othwnderr4(*)
donotstor:
othtime4=lonarr(mm)
othwind4=fltarr(mm)
othwnderr4=fltarr(mm)
if (gg eq 0) then goto,skippypart
 for ll=0,gg-1 do begin
  othtime4(ll)=storetime2(ll)
  othwind4(ll)=storewind2(ll)
  othwnderr4(ll)=storewinderr2(ll)
 endfor
skippypart:
hh=0
othdayarr:
 othtime4(kk)=(p4*2400)+ttime2(hh)
 othwind4(kk)=twind2(hh)
 othwnderr4(kk)=twinderr2(hh)
kk=kk+1 & hh=hh+1
if (hh lt nn) then goto,othdayarr
smelly1:

;  this is the line that is jumped to if there was no data for
;  a given day.  null data would have been stored instead, then
;  the program would come here

skipreldata:

;  now, creating the data dates array, which is used in
;  the plotting procedures as the xaxis of time.

;  p+(pltnum) is the tick number for the all days plots
;  it acts as the datadates array size until the end where
;  then a last day is added to the datadates array to finish
;  off the relevant xtick_name file information.  t then becomes
;  the datadates array size at that point.  p is important though
;  as it defines the tick number.  q acts as the go-between when
;  storing the date info.

q4=p4
p4=p4+1

if (q4 eq 0) then goto, notstoredate
  storedateinfo=strarr(q4)
  storedateinfo(*)=datadates4(*)
notstoredate:

datadates4=strarr(p4)

if (q4 eq 0) then goto, datearray
 for r=0,q4-1 do begin
  datadates4(r)=storedateinfo(r)
 endfor
datearray:

datadates4(t4)=day
t4=t4+1

; the following call changes the date string and the switch string
; if it is necessary.  that is, if the data range covers
; different months, we need to properly change the date string
; so that the computer knows what to look for.

call_procedure,'chngmnthdate',mnthval,day,date,switch

;  the dat and dat2 variables are used to determine if we are
;  done reading data, then go to the plotting section.

if (dat eq dat2) then goto, finalizearray

;  didn't go to next range of data so now check for a switch,
;  that is, did month change.

if (switch ne 'y') then begin
 dat=dat+1
 date=strcompress(dat,/remove_all)
endif

;  set switch back
switch=''

;  return to top to continue looping thru requested data range

goto, continuebuild

;  this section is for adding the last element to the
;  datadates array, used for the x-axis plotting

finalizearray:
storedateinfo=strarr(p4)
storedateinfo(*)=datadates4(*)
q4=p4
t4=t4+1
datadates4=strarr(t4)
for r=0,q4-1 do begin
 datadates4(r)=storedateinfo(r)
endfor
dat=dat+1
lastdate=strcompress(dat,/remove_all)
lastday=strmid(lastdate,1,2)
lastmnthval=strmid(lastdate,0,1)

call_procedure,'crrctlastday',lastmnthval,lastday

datadates4(t4-1)=lastday

if (location eq 'southpole') and (yr eq '91') then begin
;or $
; (location eq 'inuvik') then begin
 flttime=fltarr(m)
 for j=0,m-1 do begin
  thtime=timetot4(j)
  call_procedure,'cortodectime',thtime
  flttime(j)=thtime
 endfor
 timetot4=fix(flttime*100)
 if (datatype eq 'merddata') or (datatype eq 'zonedata') then begin
  othflttime=fltarr(mm)
  for j=0,mm-1 do begin
   thtime=othtime4(j)
   call_procedure,'cortodectime',thtime
   othflttime(j)=thtime
  endfor
  othtime4=fix(othflttime*100)
 endif
endif

;  this section makes the plot titles for the wind plot of
;  all the days

if (mnthval1 eq mnthval2) then begin
 if (day1 eq day2) then begin
   plottitle4=site+', '+month1+' '+day1+', 19'+yr+'.'
   xplottitle4='Time in UT.'
   psfilenametmp4=psfilenametmp3+fileext+date1+yr
 endif else begin
   plottitle4=site+', '+month1+' '+day1+' to '+day2+', 19'+yr+'.'
   xplottitle4='Dates in '+month1+'.'
   psfilenametmp4=psfilenametmp3+fileext+date1+date2+yr
 endelse
endif else begin
   plottitle4=site+', '+month1+' '+day1+' to '+month2+' '+day2+$
    ', 19'+yr+'.'
   xplottitle4='Dates in '+month1+' and '+month2+'.'
   psfilenametmp4=psfilenametmp3+fileext+date1+date2+yr
endelse

if (max(windtot4) eq 10000) or (max(othwind4) eq 10000) then begin
  for s=0,m-1 do begin
   if (windtot4(s) eq 10000) then windtot4(s)=0.00001
  endfor
  for ss=0,mm-1 do begin
   if (othwind4(ss) eq 10000) then othwind4(ss)=0.00001
  endfor
  micky=max(windtot4) & minny=min(windtot4)
  if (max(othwind4) gt micky) then micky=max(othwind4)
  if (min(othwind4) lt minny) then minny=min(othwind4)
  for s=0,m-1 do begin
   if (windtot4(s) eq 0.00001) then windtot4(s)=10000
  endfor
  for ss=0,mm-1 do begin
   if (othwind4(ss) eq 0.00001) then othwind4(ss)=10000
  endfor
endif else begin
  micky=max(windtot4) & minny=min(windtot4)
  if (max(othwind4) gt micky) then micky=max(othwind4)
  if (min(othwind4) lt minny) then minny=min(othwind4)
endelse

if (micky gt yranmaxval) or (minny lt yranminval) then begin
  call_procedure,'defineylimits',micky,minny,yranmaxval,yranminval
endif

if (min(timetot4) lt 0) then begin
 xranminval4=min(timetot4)
  if (datatype eq 'vertdata') then goto,smelly2 
  if (min(othtime4) lt xranminval4) then xranminval4=min(othtime4)
 smelly2:
endif else begin
 xranminval4=0
  if (datatype eq 'vertdata') then goto,smelly3
  if (min(othtime4) lt xranminval4) then xranminval4=min(othtime4)
 smelly3:
endelse
xranmaxval4=p4*2400

;  this section checks to see if only one day's data will be
;  on the graph, in which case, the datadates array will change.
;  it also defines the relevant quantities for plotting parameters,
;  e.g.  tick length, etc.

lent4=1.0
silly4=0
line4=1

if (day1 eq day2) then begin
 lent4=0.05
 silly4=-4
 line4=0
 print,''
 print,''
 print, "you will be plotting data for only one day on plot number 4"
 print, "do you want the wind data displayed on:"
 print,''
 print, "a.  a full 24 hour graph"
 print,''
 print, "b.  a graph using the first measurement's time"
 print, "    as the minimum time and the last measurement's"
 print, "    time as the maximum time"
 print,''
 print, "c.  pick your own times"
 print,''
 read,plotques
 print,''
 print,''
 soup=min(timetot4)
 soupest=max(timetot4)
 if (datatype eq 'vertdata') then goto,smelly4
 if (min(othtime4) lt soup) then soup=min(othtime4)
 if (max(othtime4) gt soupest) then soupest=max(othtime4)
 smelly4:
 souper=(soup+soupest)/2
 insouper=(souper+soup)/2
 outsouper=(souper+soupest)/2
 call_procedure,'crrctthetime',soup,souper,soupest,insouper,outsouper,$
   stup,stuper,stupest,instuper,outstuper
 if (plotques eq 'a') then begin
  p4=4
  datadates4=strarr(5)
  datadates4(1)='600' & datadates4(2)='1200' & datadates4(3)='1800' & $
  datadates4(4)='2400'
  xranmaxval4=2400
  if (soup lt 0) then begin
   xranminval4=soup & datadates4(0)=stup
  endif else begin
   xranminval4=0 & datadates4(0)='0000'
  endelse
 endif
 if (plotques eq 'b') then begin
  if (soup lt 0) then begin
   slam=fix(soup/100)-1
  endif else begin
   slam=fix(soup/100)
  endelse
  offslam=slam*100
  joe=fix(soupest/100)+1
  offjoe=joe*100
  jam=joe-slam
  p4=round(jam/2.)
  datadates4=strarr(p4+1)
  first=offslam
  for poopoo=0,p4 do begin
   call_procedure,'crrctthetime',first,souper,soupest,insouper,outsouper,$
   stup,stuper,stupest,instuper,outstuper
   datadates4(poopoo)=stup
   if poopoo eq p4 then xranmaxval4=first
   first=first+200
  endfor
  xranminval4=offslam
;xranmaxval4=offjoe
;  datadates4=[stup,instuper,stuper,outstuper,stupest]
 endif
 if (plotques eq 'c') then begin
  print,''
  print, "enter the minimum time, using a decimal format, e.g."
  print, 'use 5.0 to indicate 5:00'
  print,''
  read, soup
  print,''
  print, "enter the maximum time"
  print,''
  read, soupest
  print,''
  soup=fix(soup*100)
  soupest=fix(soupest*100)
  souper=(soup+soupest)/2
  insouper=(souper+soup)/2
  outsouper=(souper+soupest)/2
  if (soup lt 0) then begin
   slam=fix(soup/100)-1
  endif else begin
   slam=fix(soup/100)
  endelse
  offslam=slam*100
  joe=fix(soupest/100)+1
  offjoe=joe*100
  jam=joe-slam
  p4=round(jam/2.)
  datadates4=strarr(p4+1)
  first=offslam
  for poopoo=0,p4 do begin
   call_procedure,'crrctthetime',first,souper,soupest,insouper,outsouper,$
   stup,stuper,stupest,instuper,outstuper
   datadates4(poopoo)=stup
   if poopoo eq p4 then xranmaxval4=first
   first=first+200
  endfor
  xranminval4=offslam
;xranmaxval4=offjoe
;  call_procedure,'crrctthetime',soup,souper,soupest,insouper,outsouper,$
;    stup,stuper,stupest,instuper,outstuper
;  datadates4=[stup,instuper,stuper,outstuper,stupest]
;  xranminval4=soup & xranmaxval4=soupest
 endif
endif

return

end

;  this sub plots the data from one time series on one page

pro plotoneseries,timetot1,windtot1,xplottitle1,plotnumber,$
    othwind1,othtime1,yr,location,$
    datatype,plottitle1,datadates1,p1,lent1,silly1,xranminval1,$
    xranmaxval1,yranminval,yranmaxval,yplottitle,psfilenametmp1,$
    plottype,site,line1,trig1,trig2,trig3,wnderr1,othwnderr1

common storesine1,correction1,titleinfo1

common storesine2,correction2,titleinfo2

common storesine3,correction3,titleinfo3

!p.font=0
!p.multi=[0,0,plotnumber,0,0]
othsil=-5

decision=''
decision1=''
decision2=''
dummy=''

start:

window,0,retain=2
wset,0
plot,timetot1,windtot1,xrange=[xranminval1,xranmaxval1],$
 xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
 xtitle=xplottitle1,ytitle=yplottitle,title=plottitle1,$
 xticks=p1,xtickname=datadates1,xminor=4,yminor=2,xticklen=lent1,$
 xgridstyle=line1,ygridstyle=1,psym=silly1,symsize=0.9,$
 max_value=9999,pos=[0.1,0.1,0.9,0.9]
errplot,timetot1,windtot1-wnderr1,windtot1+wnderr1
if (datatype eq 'merddata') then begin
 oplot,othtime1,othwind1,psym=othsil,symsize=0.9
 errplot,othtime1,othwind1-othwnderr1,othwind1+othwnderr1
 biginfo='!9V !3is Northward looking'
 moreinfo='!4D !3is Southward looking'
endif
if (datatype eq 'zonedata') then begin
 oplot,othtime1,othwind1,psym=othsil,symsize=0.9
 errplot,othtime1,othwind1-othwnderr1,othwind1+othwnderr1
 biginfo='!9V !3is Eastward looking'
 moreinfo='!4D !3is Westward looking'
endif
if (datatype eq 'merddata') or (datatype eq 'zonedata') then begin
 xyouts,0.71,0.85,biginfo,/normal,/noclip,font=-1
 xyouts,0.71,0.82,moreinfo,/normal,/noclip,font=-1
 !p.font=0
endif

if (decision1 eq 'y') then begin
 print,''
 print, "go back to original plotting arrangement?  y/n"
 print,''
 read,decision2
 if (decision2 eq 'y') then begin
  decision1=''
  datadates1=strddatadates1
  p1=oldp1
  xranminval1=oldxranminval1
  xranmaxval1=oldxranmaxval1
  xplottitle1=oldxplttitle1
  if (max(timetot1) gt 2400) or (max(othtime1) gt 2400) then begin
   silly1=0
   othsil=0
  endif else begin
   silly1=-4
   othsil=-5
  endelse
  goto,start
 endif
 if (decision2 ne 'y') then goto,donery
endif

print,''
print, "plot with no connecting lines between data points?  y/n"
print,''
read,decision1
if (decision1 eq 'y') then begin
 silly1=4
 othsil=5
 oldp1=p1
; p1=4
 oldxplttitle1=xplottitle1
 oldxranminval1=xranminval1
 oldxranmaxval1=xranmaxval1
 xplottitle1='Time in UT.'
 strddatadates1=datadates1
; datadates1=strarr(5)
; soup=min(timetot1)
; soupest=max(timetot1)
; if (datatype eq 'vertdata') then goto,smelly
; if (min(othtime1) lt soup) then soup=min(othtime1)
; if (max(othtime1) gt soupest) then soupest=max(othtime1)
; smelly:
; souper=(soup+soupest)/2
; insouper=(souper+soup)/2
; outsouper=(souper+soupest)/2
; call_procedure,'crrctthetime',soup,souper,soupest,insouper,outsouper,$
;   stup,stuper,stupest,instuper,outstuper
; datadates1=[stup,instuper,stuper,outstuper,stupest]
; xranminval1=soup & xranmaxval1=soupest
endif
if (decision1 eq 'y') then goto,start 

donery:

print,''
print, "save this as postscript?  y/n"
print,''
read,decision
if (decision ne 'y') then goto, next
print,''
 set_plot,'ps'
 psfilename=psfilenametmp1+'.ps'
 device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
   xsize=6,yoffset=1.25,ysize=8.5,font_size=12
 plot,timetot1,windtot1,xrange=[xranminval1,xranmaxval1],$
   xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
   xtitle=xplottitle1, ytitle=yplottitle,title=plottitle1,$
   xticks=p1,xtickname=datadates1,xminor=4,yminor=2,xticklen=lent1,$
   xgridstyle=line1,ygridstyle=1,psym=silly1,symsize=0.9,$
   max_value=9999,pos=[0,0.1,1,0.9]
   errplot,timetot1,windtot1-wnderr1,windtot1+wnderr1
 if (datatype eq 'merddata') then begin
  oplot,othtime1,othwind1,psym=-5,symsize=0.9
  errplot,othtime1,othwind1-othwnderr1,othwind1+othwnderr1
  xyouts,0.68,0.85,'!9V',/normal,/noclip,font=-1
  xyouts,0.7,0.85,' is Northward looking',/normal,/noclip,font=0
  xyouts,0.68,0.82,'!4D',/normal,/noclip,font=-1
  xyouts,0.7,0.82,' is Southward looking',/normal,/noclip,font=0
 endif
 if (datatype eq 'zonedata') then begin
  oplot,othtime1,othwind1,psym=-5,symsize=0.9
  errplot,othtime1,othwind1-othwnderr1,othwind1+othwnderr1
  xyouts,0.68,0.85,'!9V',/normal,/noclip,font=-1
  xyouts,0.7,0.85,' is Eastward looking',/normal,/noclip,font=0
  xyouts,0.68,0.82,'!4D',/normal,/noclip,font=-1
  xyouts,0.7,0.82,' is Westward looking',/normal,/noclip,font=0
 endif
 device,/close
 set_plot,'x'
next:

print,''
print,''
decision=''
print, "would you like to perform a spectral analysis?  y/n"
print,''
read,decision
if (decision ne 'y') then goto,done
print,''

print,''
smplrate=''
print, "In order to spectrally analyze the time series,"
print, "it is necessary to know whether or not the data was"
print, "sampled at regular time intervals, or irregular."
print, "please select one of the following"
print,''
print, "a.  evenly-spaced (in time) measurements"
print, "b.  unevenly-spaced"
print,''
read,smplrate
if (smplrate eq 'a') then begin
 print,''
 print, "please enter the time interval, in seconds, between"
 print, "each measurement."
 print,''
 read, dltinsec
 dltinsec=float(dltinsec)
 print,''
; dltinmin=dltinsec/60.
 dltinhr=dltinsec/3600.
; dltinday=dltinhr/24.

 numb=n_elements(windtot1)
; freq1=findgen((numb/2)+1)/(numb*dltinsec)
; freq2=findgen((numb/2)+1)/(numb*dltinmin)
 freq3=findgen((numb/2)+1)/(numb*dltinhr)
; freq4=findgen((numb/2)+1)/(numb*dltinday)
 powerwindtot1=(abs(fft(windtot1,-1)))^2
; plot,freq1,powerwindtot1(0:numb/2),$
;   xrange=[1./(numb*dltinsec),1./(2.*dltinsec)],$
;   /xtype,/ytype,ytitle='Power Spectrum of '+plottype+' Winds',$
;   xtitle='Frequency in cycles/sec',title=plottitle1,xstyle=1,$
;   ystyle=1,pos=[0.1,0.1,0.9,0.9]
; print,''
; print, "for next plot, hit any key"
; read,dummy
; plot,freq2,powerwindtot1(0:numb/2),$
;   xrange=[1./(numb*dltinmin),1./(2.*dltinmin)],$
;   /xtype,/ytype,ytitle='Power Spectrum of '+plottype+' Winds',$
;   xtitle='Frequency in cycles/min',title=plottitle1,xstyle=1,$
;   ystyle=1,pos=[0.1,0.1,0.9,0.9]
; print,''
; print, "for next plot, hit any key"
; read,dummy
 plot,freq3,powerwindtot1(0:numb/2),$
   xrange=[1./(numb*dltinhr),1./(2.*dltinhr)],$
   /xtype,/ytype,ytitle='Power Spectrum of '+plottype+' Winds',$
   xtitle='Frequency in cycles/hr',title=plottitle1,xstyle=1,$
   ystyle=1,pos=[0.1,0.1,0.9,0.9]
 print,''
; print, "for next plot, hit any key"
; read,dummy
; plot,freq4,powerwindtot1(0:numb/2),$
;   xrange=[1./(numb*dltinday),1./(2.*dltinday)],$
;   /xtype,/ytype,ytitle='Power Spectrum of '+plottype+' Winds',$
;   xtitle='Frequency in cycles/day',title=plottitle1,xstyle=1,$
;   ystyle=1,pos=[0.1,0.1,0.9,0.9]
; print,''
 print, "hit any key to continue"
 read,dummy
 
 print,''
 print,''
 decision=''
 print, "save as a postscript file?  y/n"
 print,''
 read,decision
 if (decision ne 'y') then goto,done
 print,''
 set_plot,'ps'
 psfilename=psfilenametmp1+'pwrspec.ps'
 device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
   xsize=6,yoffset=1.5,ysize=8,font_size=12
 plot,freq3,powerwindtot1(0:numb/2),ytitle='Power Spectrum of '+plottype+$
   ' Winds',xtitle='Frequency in cycles/hr',/ytype,/xtype,$
   title=plottitle1,pos=[0,0.1,1,0.9],xstyle=1,ystyle=1,$
   xrange=[1./(numb*dltinmin),1./(2.*dltinmin)]
 device,/close
 set_plot,'x'
endif

if (smplrate ne 'a') then begin
 call_procedure,'lombperiodgrm',windtot1,timetot1,plotnumber,$
   plottitle1,psfilenametmp1,yranmaxval,yranminval,xranmaxval1,$
   xranminval1,yplottitle,xplottitle1,datadates1,lent1,$
   line1,silly1,p1,yr,location,trig1,trig2,trig3
endif

done:

return

end

;  this sub plots the data from two time series on one page

pro plottwoseries,timetot1,windtot1,xplottitle1,plotnumber,$
    othwind1,othwind2,othtime1,othtime2,datatype,$
    plottitle1,datadates1,p1,lent1,silly1,xranminval1,xranmaxval1,$
    yranminval,yranmaxval,yplottitle,psfilenametmp2,timetot2,windtot2,$
    xplottitle2,plottitle2,datadates2,p2,lent2,silly2,xranminval2,$
    xranmaxval2,plottype,site,line1,line2,wnderr1,othwnderr1,wnderr2,$
    othwnderr2

common storesine1,correction1,titleinfo1

common storesine2,correction2,titleinfo2

common storesine3,correction3,titleinfo3

!p.font=0
!p.multi=[0,0,plotnumber,0,0]

decision=''

window,0,retain=2
wset,0
plot,timetot1,windtot1,xrange=[xranminval1,xranmaxval1],$
 xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
 xtitle=xplottitle1, ytitle=yplottitle,title=plottitle1,$
 xticks=p1,xtickname=datadates1,xminor=4,yminor=2,xticklen=lent1,$
 xgridstyle=line1,ygridstyle=1,psym=silly1,symsize=0.9,$
 max_value=9999,pos=[0.1,0.57,0.9,0.9]
errplot,timetot1,windtot1-wnderr1,windtot1+wnderr1
plot,timetot2,windtot2,xrange=[xranminval2,xranmaxval2],$
 xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
 xtitle=xplottitle2, ytitle=yplottitle,title=plottitle2,$
 xticks=p2,xtickname=datadates2,xminor=4,yminor=2,xticklen=lent2,$
 xgridstyle=line2,ygridstyle=1,psym=silly2,symsize=0.9,$
 max_value=9999,pos=[0.1,0.1,0.9,0.43]
errplot,timetot2,windtot2-wnderr2,windtot2+wnderr2

print,''
print, "save as postscript?  y/n"
print,''
read, decision
if (decision ne 'y') then goto, next
psfilename=psfilenametmp2+'.ps'
set_plot,'ps'
device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
   xsize=6,yoffset=1.25,ysize=8.5,font_size=12
 plot,timetot1,windtot1,xrange=[xranminval1,xranmaxval1],$
   xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
   xtitle=xplottitle1, ytitle=yplottitle,title=plottitle1,$
   xticks=p1,xtickname=datadates1,xminor=4,yminor=2,xticklen=lent1,$
   xgridstyle=line1,ygridstyle=1,psym=silly1,symsize=0.9,$
   max_value=9999,pos=[0,0.57,1,1],charsize=1.125,xcharsize=0.85
 errplot,timetot1,windtot1-wnderr1,windtot1+wnderr1
 plot,timetot2,windtot2,xrange=[xranminval2,xranmaxval2],$
   xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
   xtitle=xplottitle2, ytitle=yplottitle,title=plottitle2,$
   xticks=p2,xtickname=datadates2,xminor=4,yminor=2,xticklen=lent2,$
   xgridstyle=line2,ygridstyle=1,psym=silly2,symsize=0.9,$
   max_value=9999,pos=[0,0,1,0.43],charsize=1.125,xcharsize=0.85
 errplot,timetot2,windtot2-wnderr2,windtot2+wnderr2
device,/close
set_plot,'x'

next:

return

end

;  this sub plots the data from three time series on one page

pro plotthreeseries,timetot1,windtot1,xplottitle1,plotnumber,$
    othwind1,othwind2,othwind3,othtime1,othtime2,othtime3,$
    datatype,$
    plottitle1,datadates1,p1,lent1,silly1,xranminval1,xranmaxval1,$
    yranminval,yranmaxval,yplottitle,psfilenametmp3,timetot2,windtot2,$
    xplottitle2,plottitle2,datadates2,p2,lent2,silly2,xranminval2,$
    xranmaxval2,timetot3,windtot3,xplottitle3,plottitle3,datadates3,p3,$
    lent3,silly3,xranminval3,xranmaxval3,plottype,site,line1,line2,$
    line3,wnderr1,othwnderr1,wnderr2,othwnderr2,wnderr3,othwnderr3

common storesine1,correction1,titleinfo1

common storesine2,correction2,titleinfo2

common storesine3,correction3,titleinfo3

!p.font=0
!p.multi=[0,0,plotnumber,0,0]

decision=''

window,0,retain=2
wset,0
plot,timetot1,windtot1,xrange=[xranminval1,xranmaxval1],$
 xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
 xtitle=xplottitle1, ytitle=yplottitle,title=plottitle1,$
 xticks=p1,xtickname=datadates1,xminor=4,yminor=2,xticklen=lent1,$
 xgridstyle=line1,ygridstyle=1,psym=silly1,symsize=0.9,$
 max_value=9999,pos=[0.1,0.72,0.9,0.9]
errplot,timetot1,windtot1-wnderr1,windtot1+wnderr1
plot,timetot2,windtot2,xrange=[xranminval2,xranmaxval2],$
 xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
 xtitle=xplottitle2,ytitle=yplottitle,title=plottitle2, $
 xticks=p2,xtickname=datadates2,xminor=4,yminor=2,xticklen=lent2, $
 xgridstyle=line2,ygridstyle=1,psym=silly2,symsize=0.9,$
 max_value=9999,pos=[0.1,0.36,0.9,0.64]
errplot,timetot2,windtot2-wnderr2,windtot2+wnderr2
plot,timetot3,windtot3,xrange=[xranminval3,xranmaxval3],$
 xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
 xtitle=xplottitle3,ytitle=yplottitle,title=plottitle3, $
 xticks=p3,xtickname=datadates3,xminor=4,yminor=2,xticklen=lent3, $
 xgridstyle=line3,ygridstyle=1,psym=silly3,symsize=0.9,$
 max_value=9999,pos=[0.1,0.1,0.9,0.28]
errplot,timetot3,windtot3-wnderr3,windtot3+wnderr3

print,''
print, "save as postscript?  y/n"
print,''
read, decision
if (decision ne 'y') then goto, next
psfilename=psfilenametmp3+'.ps'
set_plot,'ps'
device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
   xsize=6,yoffset=1.25,ysize=8.5,font_size=12
 plot,timetot1,windtot1,xrange=[xranminval1,xranmaxval1],$
    xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
    xtitle=xplottitle1, ytitle=yplottitle,title=plottitle1,$
    xticks=p1,xtickname=datadates1,xminor=4,yminor=2,xticklen=lent1,$
    xgridstyle=line1,ygridstyle=1,psym=silly1,symsize=0.9,$
    max_value=9999,pos=[0,0.72,1,1],charsize=1.85,xcharsize=0.9
 errplot,timetot1,windtot1-wnderr1,windtot1+wnderr1
 plot,timetot2,windtot2,xrange=[xranminval2,xranmaxval2],$
    xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
    xtitle=xplottitle2,ytitle=yplottitle,title=plottitle2, $
    xticks=p2,xtickname=datadates2,xminor=4,yminor=2,xticklen=lent2, $
    xgridstyle=line2,ygridstyle=1,psym=silly2,symsize=0.9,$
    max_value=9999,pos=[0,0.36,1,0.64],charsize=1.85,xcharsize=0.9
 errplot,timetot2,windtot2-wnderr2,windtot2+wnderr2
 plot,timetot3,windtot3,xrange=[xranminval3,xranmaxval3],$
    xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
    xtitle=xplottitle3,ytitle=yplottitle,title=plottitle3, $
    xticks=p3,xtickname=datadates3,xminor=4,yminor=2,xticklen=lent3, $
    xgridstyle=line3,ygridstyle=1,psym=silly3,symsize=0.9,$
    max_value=9999,pos=[0,0,1,0.28],charsize=1.85,xcharsize=0.9
 errplot,timetot3,windtot3-wnderr3,windtot3+wnderr3
device,/close
set_plot,'x'

next:

return

end

;  this sub plots the data from four time series on one page

pro plotfourseries,timetot1,windtot1,xplottitle1,plotnumber,$
    othwind1,othwind2,othwind3,othwind4,othtime1,othtime2,$
    othtime3,othtime4,datatype,$
    plottitle1,datadates1,p1,lent1,silly1,xranminval1,xranmaxval1,$
    yranminval,yranmaxval,yplottitle,psfilenametmp4,timetot2,windtot2

common fourplotinfo,xplottitle2,plottitle2,datadates2,p2,lent2,silly2,$
  xranminval2,xranmaxval2,timetot3,windtot3,xplottitle3,plottitle3,$
  datadates3,p3,lent3,silly3,xranminval3,xranmaxval3,timetot4,$
  windtot4,xplottitle4,plottitle4,datadates4,p4,lent4,silly4,$
  xranminval4,xranmaxval4,plottype,site,line1,line2,line3,line4,$
  wnderr1,othwnderr1,wnderr2,othwnderr2,wnderr3,othwnderr3,wnderr4,$
  othwnderr4

!p.font=0
!p.multi=[0,0,plotnumber,0,0]

decision=''

window,0,retain=2
wset,0
plot,timetot1,windtot1,xrange=[xranminval1,xranmaxval1],$
 xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
 xtitle=xplottitle1,ytitle=yplottitle,title=plottitle1,$
 xticks=p1,xtickname=datadates1,xminor=4,yminor=2,xticklen=lent1,$
 xgridstyle=line1,ygridstyle=1,psym=silly1,symsize=0.9,$
 max_value=9999,pos=[0.1,0.75,0.9,0.92]
errplot,timetot1,windtot1-wnderr1,windtot1+wnderr1
plot,timetot2,windtot2,xrange=[xranminval2,xranmaxval2],$
 xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
 xtitle=xplottitle2,ytitle=yplottitle,title=plottitle2, $
 xticks=p2,xtickname=datadates2,xminor=4,yminor=2,xticklen=lent2, $
 xgridstyle=line2,ygridstyle=1,psym=silly2,symsize=0.9,$
 max_value=9999,pos=[0.1,0.51,0.9,0.68]
errplot,timetot2,windtot2-wnderr2,windtot2+wnderr2
plot,timetot3,windtot3,xrange=[xranminval3,xranmaxval3],$
 xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
 xtitle=xplottitle3,ytitle=yplottitle,title=plottitle3, $
 xticks=p3,xtickname=datadates3,xminor=4,yminor=2,xticklen=lent3, $
 xgridstyle=line3,ygridstyle=1,psym=silly3,symsize=0.9,$
 max_value=9999,pos=[0.1,0.27,0.9,0.44]
errplot,timetot3,windtot3-wnderr3,windtot3+wnderr3
plot,timetot4,windtot4,xrange=[xranminval4,xranmaxval4],$
 xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
 xtitle=xplottitle4,ytitle=yplottitle,title=plottitle4, $
 xticks=p4,xtickname=datadates4,xminor=4,yminor=2,xticklen=lent4, $
 xgridstyle=line4,ygridstyle=1,psym=silly4,symsize=0.9,$
 max_value=9999,pos=[0.1,0.03,0.9,0.2]
errplot,timetot4,windtot4-wnderr4,windtot4+wnderr4

print,''
print, "save as postscript?  y/n"
read, decision
print,''
if (decision ne 'y') then goto, next
psfilename=psfilenametmp4+'.ps'
set_plot,'ps'
device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
   xsize=6,yoffset=1.25,ysize=8.5,font_size=12
 plot,timetot1,windtot1,xrange=[xranminval1,xranmaxval1],$
    xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
    xtitle=xplottitle1, ytitle=yplottitle,title=plottitle1,$
    xticks=p1,xtickname=datadates1,xminor=4,yminor=2,xticklen=lent1,$
    xgridstyle=line1,ygridstyle=1,psym=silly1,symsize=0.9,$
    max_value=9999,pos=[0,0.8,1,1],charsize=1.85,xcharsize=0.75
 errplot,timetot1,windtot1-wnderr1,windtot1+wnderr1
 plot,timetot2,windtot2,xrange=[xranminval2,xranmaxval2],$
    xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
    xtitle=xplottitle2,ytitle=yplottitle,title=plottitle2, $
    xticks=p2,xtickname=datadates2,xminor=4,yminor=2,xticklen=lent2, $
    xgridstyle=line2,ygridstyle=1,psym=silly2,symsize=0.9,$
    max_value=9999,pos=[0,0.535,1,0.735],charsize=1.85,xcharsize=0.75
 errplot,timetot2,windtot2-wnderr2,windtot2+wnderr2
 plot,timetot3,windtot3,xrange=[xranminval3,xranmaxval3],$
    xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
    xtitle=xplottitle3,ytitle=yplottitle,title=plottitle3, $
    xticks=p3,xtickname=datadates3,xminor=4,yminor=2,xticklen=lent3, $
    xgridstyle=line3,ygridstyle=1,psym=silly3,symsize=0.9,$
    max_value=9999,pos=[0,0.265,1,0.465],charsize=1.85,xcharsize=0.75
 errplot,timetot3,windtot3-wnderr3,windtot3+wnderr3
 plot,timetot4,windtot4,xrange=[xranminval4,xranmaxval4],$
    xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
    xtitle=xplottitle4,ytitle=yplottitle,title=plottitle4,$
    xticks=p4,xtickname=datadates4,xminor=4,yminor=2,xticklen=lent4, $
    xgridstyle=line4,ygridstyle=1,psym=silly4,symsize=0.9,$
    max_value=9999,pos=[0,0,1,0.2],charsize=1.85,xcharsize=0.75
 errplot,timetot4,windtot4-wnderr4,windtot4+wnderr4
device,/close
set_plot,'x'

next:

return

end

;  this sub fixes Inuvik and Southpole data that has time in
;  hr:min, when we want decimal time

pro cortodectime,thtime

if (thtime lt 0) then begin
 thtime=strcompress(thtime,/remove_all)
 if (strlen(thtime) eq 2) then begin
  hrs='0'
  min=float(strmid(thtime,1,1))
  dec=strmid(strcompress(min/60.,/remove_all),2,2)
 endif
 if (strlen(thtime) eq 3) then begin
  hrs='0'
  min=float(strmid(thtime,1,2))
  dec=strmid(strcompress(min/60.,/remove_all),2,2)
 endif
 if (strlen(thtime) eq 4) then begin
  hrs=strmid(thtime,1,1)
  min=float(strmid(thtime,2,2))
  dec=strmid(strcompress(min/60.,/remove_all),2,2)
 endif
 if (strlen(thtime) eq 5) then begin
  hrs=strmid(thtime,1,2)
  min=float(strmid(thtime,3,2))
  dec=strmid(strcompress(min/60.,/remove_all),2,2)
 endif
 thtime='-'+hrs+'.'+dec
endif else begin
 thtime=strcompress(thtime,/remove_all)
 if (strlen(thtime) eq 1) then begin
  hrs='0'
  min=float(thtime)
  dec=strmid(strcompress(min/60.,/remove_all),2,2)
 endif
 if (strlen(thtime) eq 2) then begin
  hrs='0'
  min=float(thtime)
  dec=strmid(strcompress(min/60.,/remove_all),2,2)
  endif
 if (strlen(thtime) eq 3) then begin
  hrs=strmid(thtime,0,1)
  min=float(strmid(thtime,1,2))
  dec=strmid(strcompress(min/60.,/remove_all),2,2)
 endif
 if (strlen(thtime) eq 4) then begin
  hrs=strmid(thtime,0,2)
  min=float(strmid(thtime,2,2))
  dec=strmid(strcompress(min/60.,/remove_all),2,2)
 endif
 if (strlen(thtime) eq 5) then begin
  hrs=strmid(thtime,0,3)
  min=float(strmid(thtime,3,2))
  dec=strmid(strcompress(min/60.,/remove_all),2,2)
 endif
 thtime=hrs+'.'+dec
endelse

thtime=float(thtime)

return

end

;  this sub corrects time that is not in decimal format.

pro dectime,thtime

if (strlen(thtime) eq 1) then begin
 hrs='0' & dec='0'+thtime
endif
if (strlen(thtime) eq 2) then begin
 hrs='0' & dec=thtime
endif
if (strlen(thtime) eq 3) then begin
  hrs=strmid(thtime,0,1) & dec=strmid(thtime,1,2)
endif
if (strlen(thtime) eq 4) then begin
 hrs=strmid(thtime,0,2) & dec=strmid(thtime,2,2)
endif
if (strlen(thtime) eq 5) then begin
 hrs=strmid(thtime,0,3) & dec=strmid(thtime,3,2)
endif
 
thtime=hrs+'.'+dec

return

end

;  this sub is for truncating wind data that is being analyzed
;  with Lomb techniques

pro truncdata,wind,time,numb

decision=''
print,''
soup=min(time)
soupest=max(time)
souper=(soup+soupest)/2
insouper=(souper+soup)/2
outsouper=(souper+soupest)/2
call_procedure,'crrctthetime',soup,souper,soupest,insouper,outsouper,$
  stup,stuper,stupest,instuper,outstuper
print, 'your data covers the time frame of '+stup+' to '+stupest+' UT'
print,''
print, "please define the window of time that you want your"
print, "truncated wind array to cover"
print,''
print, "select your choice"
print,''
print, "the defaults are:"
print,''
print, "a. for 24 hours of data, the new time window is the 4th hour"
print, "   to the 21st hour"
print,''
print, "b. for 48 hours of data, the new time window is the 4th hour"
print, "   to the 45th hour"
print,''
print, "c. for 72 hours of data, the new time window is the 7th hour"
print, "   to the 68th hour"
print,''
print, "d. for 96 hours of data, the new time window is the 7th hour"
print, "   to the 88th hour"
print,''
print, "e. select your own time window"
print,''
read,decision
if (decision eq 'e') then begin
 print,''
 print, "please select the beginning and end of your new"
 print, "time window.  note:  please write your times in"
 print, "decimal format, e.g. write 3.5 for 0330 UT."
 print,''
 print, 'recall, your current time window is '+stup+' to '+stupest+' UT'
 print,''
 print, "the beginning of new time window?"
 print,''
 read,frontchop
 frontchop=fix(frontchop*100)
 print,''
 print, "the end?"
 print,''
 read,endchop
 endchop=fix(endchop*100)
 newnumb=0 & gg=0
 for qq=0,numb-1 do begin
  if (time(qq) ge frontchop) and (time(qq) le endchop) then $
    newnumb=newnumb+1
 endfor
 trnktime=intarr(newnumb)
 trnkwind=dblarr(newnumb)
 for qq=0,numb-1 do begin
  if (time(qq) ge frontchop) and (time(qq) le endchop) then begin
   trnktime(gg)=time(qq)
   trnkwind(gg)=wind(qq)
   gg=gg+1
  endif
 endfor
 numb=newnumb
endif
if (decision eq 'a') or (decision eq 'b') or $
   (decision eq 'c') or (decision eq 'd') then begin
 newnumb=0 & gg=0
 if (soupest le 2400) then begin
  for qq=0,numb-1 do begin
   if (time(qq) ge 400) and (time(qq) le 2100) then newnumb=newnumb+1
  endfor
  trnktime=intarr(newnumb)
  trnkwind=dblarr(newnumb)
   for qq=0,numb-1 do begin
   if (time(qq) ge 400) and (time(qq) le 2100) then begin
    trnktime(gg)=time(qq)
    trnkwind(gg)=wind(qq)
    gg=gg+1
   endif
  endfor
 endif
 if (soupest gt 2400) and (soupest le 4800) then begin
  for qq=0,numb-1 do begin
   if (time(qq) ge 400) and (time(qq) le 4500) then newnumb=newnumb+1
  endfor
  trnktime=intarr(newnumb)
  trnkwind=dblarr(newnumb)
  for qq=0,numb-1 do begin
   if (time(qq) ge 400) and (time(qq) le 4500) then begin
    trnktime(gg)=time(qq)
    trnkwind(gg)=wind(qq)
    gg=gg+1
   endif
  endfor
 endif
 if (soupest gt 4800) and (soupest le 7200) then begin
  for qq=0,numb-1 do begin
    if (time(qq) ge 700) and (time(qq) le 6800) then newnumb=newnumb+1
  endfor
  trnktime=intarr(newnumb)
  trnkwind=dblarr(newnumb)
  for qq=0,numb-1 do begin
   if (time(qq) ge 700) and (time(qq) le 6800) then begin
    trnktime(gg)=time(qq)
    trnkwind(gg)=wind(qq)
    gg=gg+1
   endif
  endfor
 endif
 if (soupest gt 7200) and (soupest le 9600) then begin
  for qq=0,numb-1 do begin
    if (time(qq) ge 700) and (time(qq) le 8800) then newnumb=newnumb+1
  endfor
  trnktime=intarr(newnumb)
  trnkwind=dblarr(newnumb)
  for qq=0,numb-1 do begin
   if (time(qq) ge 700) and (time(qq) le 8800) then begin
    trnktime(gg)=time(qq)
    trnkwind(gg)=wind(qq)
    gg=gg+1
   endif
  endfor
 endif
 numb=newnumb
 numb=newnumb
endif
print,''
time=trnktime
wind=trnkwind

return

end

;  this sub contains the actual lomb algorithm, give it the relevant
;  info, and it generates the Lomb normalized periodogram

pro generatelomb,wind,time,numb,freq,lomb,np,lombmax,freqpeak,prob,$
    jmax,lwfrq,hghfrq,rlvfrqs,rlvindx,she,dasher,signiflomb,var,meany,$
    firsttime,lasttime

ofac=double(4.)
hifac=double(2.)
lombmax=0.
dif=double(lasttime-firsttime)
sum=double(lasttime+firsttime)
nele=n_elements(wind)

nyquist=double(nele/(2.*dif))
hghfrq=double(hifac*nyquist)
lwfrq=double(1./(dif*ofac))
tmpfrq=double(lwfrq)
tave=double(sum/2.)
np=fix((ofac*hifac*numb)/2.)
effm=double(hifac*nele)
signifprob=0.05
; signifprob2=0.001
signiflomb=-(alog(1-((1-signifprob)^(1/effm))))
; signiflomb2=-(alog(1-((1-signifprob2)^(1/effm))))
dasher=fltarr(fix(0.666666*np))
; dasher2=fltarr(fix(0.666666*np))
dasher(*)=signiflomb
; dasher2(*)=signiflomb2
she=fix(0)

wpr=dblarr(nele)
wpi=dblarr(nele)
wr=dblarr(nele)
wi=dblarr(nele)
freq=dblarr(np)
lomb=dblarr(np)
rlvfrqs=dblarr(1)
strdstuff=dblarr(1)
rlvindx=intarr(1)
strdindx=intarr(1)

print,''
print,''
var=variance(wind,meany)
print,''
print, "variance calculated"
print,''
print, "hang on.  Lomb spectrum being generated."
print,''

for j=0,nele-1 do begin
 arg=double((2.*!dpi)*((time(j)-tave)*tmpfrq))
 wpr(j)=double(-2.)*double((sin(0.5*arg))^2)
 wpi(j)=double(sin(arg))
 wr(j)=double(cos(arg))
 wi(j)=wpi(j)
endfor

for i=0,np-1 do begin
 freq(i)=tmpfrq
 sumsh=double(0.)
 sumc=double(0.)
 for j=0,nele-1 do begin
  c=wr(j)
  s=wi(j)
  sumsh=double(sumsh+s*c)
  sumc=double(sumc+(c-s)*(c+s))
 endfor

 wtau=double((atan(2.*sumsh,sumc))/2.)
 swtau=double(sin(wtau))
 cwtau=double(cos(wtau))
 sums=double(0.)
 sumc=double(0.)
 sumsy=double(0.)
 sumcy=double(0.)
 for j=0,nele-1 do begin
  s=wi(j)
  c=wr(j)
  ss=double((s*cwtau)-(c*swtau))
  cc=double((c*cwtau)+(s*swtau))
  sums=double(sums+(ss^2))
  sumc=double(sumc+(cc^2))
  yy=double(wind(j))-meany
  sumsy=double(sumsy+(yy*ss))
  sumcy=double(sumcy+(yy*cc))
  wtemp=wr(j)
  wr(j)=(wr(j)*wpr(j)-wi(j)*wpi(j))+wr(j)
  wi(j)=(wi(j)*wpr(j)+wtemp*wpi(j))+wi(j)
 endfor

 lomb(i)=(1./(2.*var))*((sumcy^2/sumc)+(sumsy^2/sums))

 rlvlomb=double(exp(-lomb(i)))
 rlvprob=1.-((1.-rlvlomb)^effm)
 if (rlvprob lt signifprob) then begin
  prvshe=she
  she=she+1
  if (prvshe eq 0) then goto,skippy
  strdstuff=dblarr(prvshe)
  strdindx=intarr(prvshe)
  strdstuff(*)=rlvfrqs(*)
  strdindx(*)=rlvindx(*)
  rlvfrqs=dblarr(she)
  rlvindx=intarr(she)
  for yy=0,prvshe-1 do begin
   rlvfrqs(yy)=strdstuff(yy)
   rlvindx(yy)=strdindx(yy)
  endfor
 skippy:
  rlvfrqs(she-1)=freq(i)
  rlvindx(she-1)=i
 endif

 if (lomb(i) ge lombmax) then begin
  lombmax=lomb(i)
  jmax=i
  freqpeak=double(freq(i))
 endif

 tmpfrq=tmpfrq+lwfrq
endfor

expy=double(exp(-lombmax))
prob=1.-((1.-expy)^effm)

return

end

;  this sub generates the Lomb normalized periodogram for unevenly
;  sampled data, specifically, vertical wind measurements with
;  an irregular time interval.

pro lombperiodgrm,feelwind,feeltime,plotnumber,plottitle,$
    psfilenametmp,yranmaxval,yranminval,xranmaxval,xranminval,$
    yplottitle,xplottitle,datadates,lent,line,silly,p,yr,location,$
    trig1,trig2,trig3

common storesine1,correction1,titleinfo1

common storesine2,correction2,titleinfo2

common storesine3,correction3,titleinfo3

print,''
print,''
print,''
print, "Lomb Normalized Periodogram routine for generating"
print, "power spectra to unevenly sampled wind data."
print,''
print,''
print,''

startover:
dummy=''
windowinfo=''
truncinfo=''
sinusoidinfo=''
crosstitle=''
psfilecross=''
psfilelomb=''
psfilewindow=''
psfiletrun=''
psfilesinusoid=''
psfilewindcorr=''
freqinfo=''
lombinfo=''
incre=fix(0)
increinfo=''
corrinfo=''
newxplottitle=''
datearray=datadates
xplotinfo=xplottitle
plotinfo=plottitle
psfileinfo=psfilenametmp
wind=double(feelwind)
thewind=double(feelwind)
numb=n_elements(wind)
time=feeltime
thetime=feeltime

if (max(wind) eq 10000) then begin
 chicken=0
 for dodo=0,numb-1 do begin
  if (wind(dodo) eq 10000) then goto,oops
   chicken=chicken+1
  oops:
 endfor
 fixtime=intarr(chicken) & fixwind=dblarr(chicken)
 fixxy=0
 for dodo=0,numb-1 do begin
  if (wind(dodo) ne 10000) then begin
   fixtime(fixxy)=time(dodo)
   fixwind(fixxy)=wind(dodo)
   fixxy=fixxy+1
  endif
 endfor
 numb=chicken
 wind=fixwind
 time=fixtime
 thewind=fixwind
 thetime=fixtime
endif

if (min(time) lt 0) then time=time-(min(time))

print,''
print,''
thedecision=''
print, "you can continue on and generate single Lomb periodograms,"
print, "using the current time series, or, more elaborately,"
print, "you can generate a Lomb dynamic spectrum with the current"
print, "time series."
print,''
print,''
print,''
print, "select an option"
print,''
print, "a.  continue on and generate a single Lomb periodogram using"
print, "    the current time series"
print,''
print, "b.  generate a dynamic spectrum using the current time series"
print,''
print, "c.  truncate the current time series and then generate a"
print, "    single Lomb periodogram"
print,''
print, "d.  truncate the current time series and then generate a"
print, "    a dynamic spectrum, using the truncated series"
print,''
print, "e.  quit, you weren't meant to be here in the first place"
print,''
read,thedecision
if (thedecision eq 'a') then goto,continue
if (thedecision eq 'c') or (thedecision eq 'd') then begin
 print,''
 psfiletrun=psfileinfo+'trnc'
 call_procedure,'truncdata',wind,time,numb
 truncinfo='!CTruncated.'
 soup=min(time)
 soupest=max(time)
 souper=(soup+soupest)/2
 insouper=(souper+soup)/2
 outsouper=(souper+soupest)/2
 call_procedure,'crrctthetime',soup,souper,soupest,insouper,outsouper,$
   stup,stuper,stupest,instuper,outstuper
 datearray=strarr(5)
 p=4
 datearray=[stup,instuper,stuper,outstuper,stupest]
 print,''
 print,''
 print, "here's the truncated data"
 newxplottitle='Time in UT.'
 print,''
 window,0,retain=2
 wset,0
 plot,time,wind,xrange=[soup,soupest],$
  xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
  xtitle=newxplottitle,ytitle=yplottitle,title=plotinfo+truncinfo,$
  xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
  xgridstyle=line,ygridstyle=1,psym=silly,symsize=0.9,$
  max_value=9999,pos=[0.1,0.15,0.9,0.85]
 print,''
 print,''
 decision1=''
 print, "save this as postscript?  y/n"
 print,''
 read,decision1
 if (decision1 ne 'y') then goto,next
 print,''
 decision2=''
 print, "here is the postscript filename"
 print,''
 print, psfiletrun+'.ps'
 print, ''
 print, "do you want to change it?  y/n"
 print,''
 read,decision2
 if (decision2 eq 'y') then begin
  print,''
  print, "type in the filename you want, including full directory"
  print, "structure, if necessary.  do not include the .ps"
  print,''
  read, psfiletrun
 endif
 set_plot,'ps'
 psfilename=psfiletrun+'.ps'
 device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
   xsize=6,yoffset=1.5,ysize=8,font_size=12
 plot,time,wind,xrange=[soup,soupest],$
  xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
  xtitle=newxplottitle,ytitle=yplottitle,title=plottitle+truncinfo,$
  xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
  xgridstyle=line,ygridstyle=1,psym=silly,symsize=0.9,$
  max_value=9999,pos=[0,0.1,1,0.9]
 device,/close
 set_plot,'x'
 next:
endif
if (thedecision eq 'c') then goto,continue
if (thedecision eq 'b') or (thedecision eq 'd') then begin
 call_procedure,'dynamicspec',wind,time,plotnumber,plottitle,$
   psfilenametmp,yranmaxval,yranminval,soup,soupest,$
   yplottitle,newxplottitle,datearray,lent,line,silly,p,yr,location,$
   incre,increinfo
endif
if (thedecision eq 'b') or (thedecision eq 'd') then goto,startover
if (thedecision eq 'e') then goto,doney

continue:

flttime=dblarr(numb)
for j=0,numb-1 do begin
 thtime=time(j)
 thtime=strcompress(thtime,/remove_all)
 call_procedure,'dectime',thtime
 flttime(j)=thtime
endfor
time=flttime
thtime=strcompress(xranmaxval,/remove_all)
call_procedure,'dectime',thtime
corxrnmxvl=thtime
thtime=strcompress(xranminval,/remove_all)
call_procedure,'dectime',thtime
corxrnmnvl=thtime

tobegin:

print,''
decision=''
print, "please select a choice"
print,''
print, "a.  window the wind data with a Welch window,"
print,''
print, "b.  with a Hanning window,"
print,''
print, "c.  do not window the data"
print,''
read,decision
if (decision eq 'a') then begin
 if (truncinfo eq '') then begin
  psfilewindow=psfileinfo+'wlch'+strcompress(incre,/remove_all)
  thextitle=xplotinfo
 endif else begin
  psfilewindow=psfiletrun+'wlch'+strcompress(incre,/remove_all)
  thextitle=newxplottitle
 endelse
 print,''
 print, "windowing the data with a Welch window"
 print,''
 welchwindow=welch(numb)
 wind(*)=wind(*)*welchwindow(*)
 print,''
 print, "here's the wind data multiplied by the Welch window"
 windowinfo='!CMultiplied by a Welch window.'
 print,''
endif
if (decision eq 'b') then begin
 if (truncinfo eq '') then begin
  psfilewindow=psfileinfo+'hann'+strcompress(incre,/remove_all)
  thextitle=xplotinfo
 endif else begin
  psfilewindow=psfiletrun+'hann'+strcompress(incre,/remove_all)
  thextitle=newxplottitle
 endelse
 print,''
 print, "windowing the data with a Hanning window"
 print,''
 hannwindow=hanning(numb)
 wind(*)=wind(*)*hannwindow(*)
 print,''
 print, "here's the wind data multiplied by the Hanning window"
 windowinfo='!CMultiplied by a Hanning window.'
 print,''
endif
if (decision eq 'a') or (decision eq 'b') then begin
 print,''
 window,1,retain=2
 wset,1
 plot,time,wind,xrange=[corxrnmnvl,corxrnmxvl],$
  xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
  xtitle=thextitle,ytitle=yplottitle,subtitle='!C'+increinfo,$
  title=plotinfo+truncinfo+windowinfo,$
  xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
  xgridstyle=line,ygridstyle=1,psym=silly,symsize=0.9,$
  max_value=9999,pos=[0.1,0.15,0.9,0.85]
 print,''
 decision1=''
 print, "save this as postscript?  y/n"
 print,''
 read,decision1
 if (decision1 ne 'y') then goto, next1
 decision2=''
 print,''
 print, "here is the postscript filename"
 print,''
 print, psfilewindow+'.ps'
 print, ''
 print, "do you want to change it?  y/n"
 print,''
 read,decision2
 if (decision2 eq 'y') then begin
  print,''
  print, "type in the filename you want, including full directory"
  print, "structure, if necessary.  do not include the .ps"
  print,''
  read, psfilewindow
 endif
 set_plot,'ps'
 psfilename=psfilewindow+'.ps'
 device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
   xsize=6,yoffset=1.5,ysize=8,font_size=12
 plot,time,wind,xrange=[corxrnmnvl,corxrnmxvl],$
  xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
  xtitle=thextitle,ytitle=yplottitle,subtitle='!C'+increinfo,$
  title=plotinfo+truncinfo+windowinfo,$
  xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
  xgridstyle=line,ygridstyle=1,psym=silly,symsize=0.9,$
  max_value=9999,pos=[0,0.1,1,0.9]
 device,/close
 set_plot,'x'
 next1:
endif

firsttime=min(time)
lasttime=max(time)
call_procedure,'generatelomb',wind,time,numb,freq,lomb,np,lombmax,$
   freqpeak,prob,jmax,lwfrq,hghfrq,rlvfrqs,rlvindx,she,dasher,$
   signiflomb,var,meany,firsttime,lasttime

probinfo=strcompress(string(prob,format='(f25.16)'),/remove_all)
probinfo=strmid(probinfo,0,6)
normpower=strmid(strcompress(lombmax,/remove_all),0,5)
peakfreq=strmid(strcompress(freqpeak,/remove_all),0,6)
peakperiod=strmid(strcompress((1./freqpeak),/remove_all),0,6)

lombinfo='!C'+'Peak of the Lomb Spectrum occurs at frequency '+$
  peakfreq+' cycles/hr,!C'+'corresponding to a period of '+peakperiod+$
  ' hrs,!C'+'with a significance level of '+probinfo+'.!C'+$
  'Normalized power at the peak is '+normpower+'.'
; if (incre gt 0) then begin
; lombinfo=lombinfo+'!C'+increinfo
;endif
if (truncinfo eq '') then $
 psfilelomb=psfileinfo+'lombspec'+strcompress(incre,/remove_all) else $
 psfilelomb=psfiletrun+'lombspec'+strcompress(incre,/remove_all)

window,2,retain=2
wset,2
plot,freq,lomb,xrange=[lwfrq,hghfrq],$
  title='Normalized Lomb Periodogram of!C'+plotinfo+increinfo,$
  ytitle='Spectral Power.',xtitle='Frequency in cycles/hr.',$
  subtitle=lombinfo,xstyle=1,charsize=1.125,charthick=1.5,$
  ystyle=1,pos=[0.1,0.2,0.9,0.85]
if (lombmax ge signiflomb) then begin
 oplot,freq,dasher,linestyle=2
; oplot,freq,dasher2,linestyle=3
 xyouts,freq(fix(0.666666*np)+3),signiflomb,'significance level 0.05',$
   /noclip
; xyouts,freq(fix(0.666666*np)+3),signiflomb2,'significance level 0.001'
endif
print,''
print, "freqs with prob. higher than 0.05 are"
for jj=0,she-1 do begin
 print,strmid(strcompress(rlvfrqs(jj),/remove_all),0,6),'   ',$
  strcompress(rlvindx(jj),/remove_all)
endfor
print,''
print,''
print,''
decision=''
print, "save this as postscript?  y/n"
print,''
read,decision
if (decision ne 'y') then goto,next2
print,''
print,''
decision1=''
print,''
print, "here is the postscript filename"
print,''
print, psfilelomb+'.ps'
print, ''
print, "do you want to change it?  y/n"
print,''
read,decision1
if (decision1 eq 'y') then begin
 print,''
 print, "type in the filename you want, including full directory"
 print, "structure, if necessary.  do not include the .ps"
 print,''
 read, psfilelomb
endif
set_plot,'ps'
psfilename=psfilelomb+'.ps'
device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
  xsize=6,yoffset=1.5,ysize=8,font_size=12
plot,freq,lomb,xrange=[lwfrq,hghfrq],$
  title='Normalized Lomb Periodogram of!C'+plotinfo+increinfo,$
  ytitle='Spectral Power.',xtitle='Frequency in cycles/hr.',$
  subtitle=lombinfo,xstyle=1,charsize=1.125,xcharsize=0.85,$
  ystyle=1,pos=[0,0.15,1,0.95]
if (lombmax ge signiflomb) then begin
 oplot,freq,dasher,linestyle=2
; oplot,freq,dasher2,linestyle=3
 xyouts,freq(fix(0.666666*np)+3),signiflomb,'significance level 0.05',$
   /noclip
; xyouts,freq(fix(0.666666*np)+3),signiflomb2,'significance level 0.001'
endif
device,/close
set_plot,'x'
print,''
next2:

print,''
nextdecision=''
print, "Choose.  Choose the form of the destructor!"
print,''
print, "a. truncate the current wind data so that you are"
print, "   not using data covering increments of days,"
print, "   and generate a new Lomb spectrum"
print,''
print, "   note:  truncation will be from original data, not"
print, "          windowed data, so windowing will be necessary"
print, "          again, if wanted."
print,''
print, "b. remove the current sinusoidal component from the"
print, "   wind data and generate a new Lomb spectrum in"
print, "   order to look for other frequency components"
print,''
print, "   note:  sinusoidal component subtraction will be from"
print, "          original data, not windowed data, so windowing"
print, "          will be necessary again, if wanted."
print,''
print, "c. go back and start over with the original wind data,"
print, "   that is, erase anything you have done to this point,"
print, "   and go back to the original time series"
print,''
print, "d. finish this analysis off, and go back to look at some"
print, "   other sort of analysis"
print,''
read,nextdecision
if (nextdecision eq 'a') then begin
 decision1=''
 print,''
 time=thetime
 wind=thewind 
 psfiletrun=psfileinfo+'trnc'
 call_procedure,'truncdata',wind,time,numb
 truncinfo='!CTruncated.'
 soup=min(time)
 soupest=max(time)
 souper=(soup+soupest)/2
 insouper=(souper+soup)/2
 outsouper=(souper+soupest)/2
 call_procedure,'crrctthetime',soup,souper,soupest,insouper,outsouper,$
   stup,stuper,stupest,instuper,outstuper
 datearray=strarr(5)
 p=4
 datearray=[stup,instuper,stuper,outstuper,stupest]
 newxplottitle='Time in UT.'
 print,''
 print, "here's the truncated data"
 print,''
 window,0,retain=2
 wset,0
 plot,time,wind,xrange=[soup,soupest],$
  xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
  xtitle=newxplottitle,ytitle=yplottitle,title=plotinfo+truncinfo,$
  xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
  xgridstyle=line,ygridstyle=1,psym=silly,symsize=0.9,$
  max_value=9999,pos=[0.1,0.15,0.9,0.85]
 print,''
 decision2=''
 print, "save this as postscript?  y/n"
 print,''
 read,decision2
 if (decision2 ne 'y') then goto,next3
 decision3=''
 print,''
 print, "here is the postscript filename"
 print,''
 print, psfiletrun+'.ps'
 print, ''
 print, "do you want to change it?  y/n"
 print,''
 read,decision3
 if (decision3 eq 'y') then begin
  print,''
  print, "type in the filename you want, including full directory"
  print, "structure, if necessary.  do not include the .ps"
  print,''
  read, psfiletrun
 endif
 set_plot,'ps'
 psfilename=psfiletrun+'.ps'
 device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
   xsize=6,yoffset=1.5,ysize=8,font_size=12
 plot,time,wind,xrange=[soup,soupest],$
  xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
  xtitle=newxplottitle,ytitle=yplottitle,title=plotinfo+truncinfo,$
  xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
  xgridstyle=line,ygridstyle=1,psym=silly,symsize=0.9,$
  max_value=9999,pos=[0,0.1,1,0.9]
 device,/close
 set_plot,'x'
 next3:
 print,''
 decision4=''
 print, "you now have the option of generating another Lomb"
 print, "periodogram, using this truncated time series, or, more"
 print, "elaborately, you can generate a Lomb dynamic spectrum"
 print, "using this current time series."
 print,''
 print, "select an option"
 print,''
 print, "a.  continue on and generate a single Lomb periodogram"
 print,''
 print, "b.  generate a dynamic spectrum"
 print,''
 read,decision4
 if (decision4 eq 'a') then goto,continue2
 if (decision4 eq 'b') then begin
  call_procedure,'dynamicspec',wind,time,plotnumber,plottitle,$
    psfilenametmp,yranmaxval,yranminval,soup,soupest,$
    yplottitle,newxplottitle,datearray,lent,line,silly,p,yr,location,$
    incre,increinfo
 endif
 if (decision4 eq 'b') then goto,startover

 continue2:
 flttime=dblarr(numb)
 for j=0,numb-1 do begin
  thtime=time(j)
  thtime=strcompress(thtime,/remove_all)
  call_procedure,'dectime',thtime
  flttime(j)=thtime
 endfor
 time=flttime
 corxrnmxvl=max(time)
 corxrnmnvl=min(time)
endif
if (nextdecision eq 'a') then goto,tobegin

if (nextdecision eq 'b') then begin
 fullpower=double(total(lomb))
 for ii=0,np-1 do begin
  if (ii eq jmax) or (ii eq jmax-1) or (ii eq jmax+1) or $
     (ii eq jmax-2) or (ii eq jmax+2) then goto,next4
   if (lomb(ii) ge signiflomb) then begin
    fullpower=fullpower-lomb(ii)
   endif
  next4:
 endfor
 unnormpower=double(fullpower*var)
 amppy2=double(sqrt(unnormpower/np))
 amppy=double(sqrt(var))
 windcorrect=dblarr(numb)
 ampltd=amppy2
 stampltd=strmid(strcompress(ampltd,/remove_all),0,5)
 print,''
 print, "amplitude of sinusoid calculated."
 print,''

 windcorrect=double(ampltd*sin(!dpi*2.*freqpeak*time))

 sinusoidinfo='!CSinusoidal component '+strcompress(incre+1,/remove_all)+'.'
 freqinfo='!C'+'Sinusoid is of frequency '+peakfreq+' cycles/hr,!C'+$
  'corresponding to a period of '+peakperiod+' hrs,!C'+$
  'with a significance level of '+probinfo+'.'
 if (truncinfo eq '') then begin 
  psfilesinusoid=psfileinfo+'snusoid'+strcompress(incre,/remove_all)
  psfilewindcorr=psfileinfo+'windcorr'+strcompress(incre,/remove_all)
  thextitle=xplotinfo
 endif else begin
  psfilesinusoid=psfiletrun+'snusoid'+strcompress(incre,/remove_all)
  psfilewindcorr=psfiletrun+'windcorr'+strcompress(incre,/remove_all)
  thextitle=newxplottitle
 endelse
 print,''
 print, "here's the generated sinusoid."
 print,''
 window,1,retain=2
 wset,1
 plot,time,windcorrect,xrange=[corxrnmnvl,corxrnmxvl],$
  xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
  xtitle=thextitle,ytitle=yplottitle,subtitle=freqinfo,$
  title=plotinfo+sinusoidinfo,$
  xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
  xgridstyle=line,ygridstyle=1,psym=4,symsize=0.9,$
  max_value=9999,pos=[0.1,0.2,0.9,0.85]
 print,''
 print,''
 decision1=''
 print, "save this as postscript?  y/n"
 print,''
 read,decision1
 if (decision1 ne 'y') then goto,next5
 decision2=''
 print,''
 print, "here is the postscript filename"
 print,''
 print, psfilesinusoid+'.ps'
 print, ''
 print, "do you want to change it?  y/n"
 print,''
 read,decision2
 if (decision2 eq 'y') then begin
  print,''
  print, "type in the filename you want, including full directory"
  print, "structure, if necessary.  do not include the .ps"
  print,''
  read, psfilesinusoid
 endif
 set_plot,'ps'
 psfilename=psfilesinusoid+'.ps'
 device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
   xsize=6,yoffset=1.5,ysize=8,font_size=12
 plot,time,windcorrect,xrange=[corxrnmnvl,corxrnmxvl],$
  xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
  xtitle=thextitle,ytitle=yplottitle,subtitle=freqinfo,$
  title=plotinfo+sinusoidinfo,$
  xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
  xgridstyle=line,ygridstyle=1,psym=4,symsize=0.9,$
  max_value=9999,pos=[0,0.1,1,0.9]
 device,/close
 set_plot,'x'
 next5:

 nimble=2*(numb-1)
 lag=intarr(nimble+1)
 lag(numb-1)=0
 truelag=fltarr(nimble+1)
 truelag(numb-1)=0.
 truelag(indgen(numb-1))=0.-(((numb-1)-findgen(numb-1))/16.)
 truelag(nimble-indgen(numb-1))=((numb-1)-findgen(numb-1))/16.
 lag(indgen(numb-1))=0-((numb-1)-indgen(numb-1))
 lag(nimble-indgen(numb-1))=(numb-1)-indgen(numb-1)

; print,''
; print, "performing cross correlation between the actual wind"
; print, "data and the generated sinusoid, in order to determine"
; print, "the phase between the two.  if wind data was windowed"
; print, "prior to Lomb spectrum, then the windowed data will be"
; print, "used in the cross correlation"
; print,''
; corrinfo='!CCross correlation between wind data and sinusoid '+$
;     strcompress(incre+1,/remove_all)+'.'
; crosscorr=c_correlate(wind,windcorrect,lag)
; maxcross=0.

; if (truncinfo eq '') then $
;  psfileauto=psfileinfo+'auto'+strcompress(incre,/remove_all) else $
;  psfileauto=psfiletrun+'auto'+strcompress(incre,/remove_all)
; acorr=a_correlate(wind,lag)
; window,2,retain=2
; wset,2
; plot,truelag,acorr,xstyle=1,$
;   title=plotinfo,$
;   xtitle='Lag in hours.',$
;   ytitle='Auto correlation coefficient.',$
;   pos=[0.1,0.2,0.9,0.85]
; print,''
; decision1=''
; print, "save this as postscript?  y/n"
; print,''
; read,decision1
; if (decision1 ne 'y') then goto,next6
; decision2=''
; print,''
; print, "here is the postscript filename"
; print,''
; print, psfileauto+'.ps'
; print, ''
; print, "do you want to change it?  y/n"
; print,''
; read,decision2
; if (decision2 eq 'y') then begin
;  print,''
;  print, "type in the filename you want, including full directory"
;  print, "structure, if necessary.  do not include the .ps"
;  print,''
;  read, psfileauto
; endif
; set_plot,'ps'
; psfilename=psfileauto+'.ps'
; device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
;   xsize=6,yoffset=1.5,ysize=8,font_size=12
; plot,truelag,acorr,xstyle=1,$
;   title=plotinfo,$
;   xtitle='Lag in hours.',$
;   ytitle='Auto correlation coefficient.',$
;   pos=[0,0.1,1,0.9]
; device,/close
; set_plot,'x'
; next6:

; maxlag=0.
; for j=0,nimble do begin
;  if (abs(crosscorr(j)) gt abs(maxcross)) then begin
;   maxcross=crosscorr(j)
;   maxlag=truelag(j)
;   themaxx=j
;  endif
; endfor
; if (maxcross lt 0.) then $
;  crossmax=strmid(strcompress(maxcross,/remove_all),0,6) else $
;  crossmax=strmid(strcompress(maxcross,/remove_all),0,5)
; if (maxlag lt 0.) then $
;  lagmax=strmid(strcompress(maxlag,/remove_all),0,6) else $
;  lagmax=strmid(strcompress(maxlag,/remove_all),0,5)
; print,''
; if (truncinfo eq '') then $
;  psfilecross=psfileinfo+'cross'+strcompress(incre,/remove_all) else $
;  psfilecross=psfiletrun+'cross'+strcompress(incre,/remove_all)
; crosstitle='!CMaximum correlation is '+crossmax+$
;    ' and occurs at lag '+lagmax+' hrs.'
; print,''
; print, "here's the cross correlation plot"
; print,''
; window,2,retain=2
; wset,2
; plot,truelag,crosscorr,xstyle=1,$
;   title=plotinfo+corrinfo,subtitle=crosstitle+freqinfo,$
;   xtitle='Lag in hours.',$
;   ytitle='Cross correlation coefficient.',$
;   pos=[0.1,0.2,0.9,0.85]
; print,''
; decision1=''
; print, "save this as postscript?  y/n"
; print,''
; read,decision1
; if (decision1 ne 'y') then goto,next6
; decision2=''
; print,''
; print, "here is the postscript filename"
; print,''
; print, psfilecross+'.ps'
; print, ''
; print, "do you want to change it?  y/n"
; print,''
; read,decision2
; if (decision2 eq 'y') then begin
;  print,''
;  print, "type in the filename you want, including full directory"
;  print, "structure, if necessary.  do not include the .ps"
;  print,''
;  read, psfilecross
; endif
; set_plot,'ps'
; psfilename=psfilecross+'.ps'
; device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
;   xsize=6,yoffset=1.5,ysize=8,font_size=12
; plot,truelag,crosscorr,xstyle=1,$
;   title=plotinfo+corrinfo,subtitle=crosstitle+freqinfo,$
;   xtitle='Lag in hours.',$
;   ytitle='Cross correlation coefficient.',$
;   pos=[0,0.1,1,0.9]
; device,/close
; set_plot,'x'
; next6:

; checkcrscorrs:
; limbo=0
; rlvlags=fltarr(1)
; rlvlgindx=intarr(1)
; rlvcrscor=fltarr(1)
; print,''
; print, "please enter the amount that defines which cross correlation"
; print, "may be relevant, i.e., give the amount to subtract from the"
; print, "max correlation, in order to get the index of other possible"
; print, "correlations"
; print,''
; read, littlebit
;
; for j=0,nimble do begin
;  if (abs(crosscorr(j)) gt (abs(maxcross)-littlebit)) then begin
;   prvlimbo=limbo
;   limbo=limbo+1
;   if (prvlimbo eq 0) then goto,skipper
;   strdlag=fltarr(prvlimbo)
;   strdlgindx=intarr(prvlimbo)
;   strdcrscor=fltarr(prvlimbo)
;   strdlag(*)=rlvlags(*)
;   strdlgindx(*)=rlvlgindx(*)
;   strdcrscor(*)=rlvcrscor(*)
;   rlvlags=fltarr(limbo)
;   rlvlgindx=intarr(limbo)
;   rlvcrscor=fltarr(limbo)
;   for yy=0,prvlimbo-1 do begin
;    rlvlags(yy)=strdlag(yy)
;    rlvlgindx(yy)=strdlgindx(yy)
;    rlvcrscor(yy)=strdcrscor(yy)
;   endfor
;  skipper:
;   rlvlags(limbo-1)=truelag(j)
;   rlvlgindx(limbo-1)=j
;   rlvcrscor(limbo-1)=crosscorr(j)
;  endif
; endfor
; strrlvcrs=strarr(limbo)
; strrlvlags=strarr(limbo)
; for cc=0,limbo-1 do begin
;  if (rlvcrscor(cc) lt 0.) then $
;   strrlvcrs(cc)=strmid(strcompress(rlvcrscor(cc),/remove_all),0,6) else $
;   strrlvcrs(cc)=strmid(strcompress(rlvcrscor(cc),/remove_all),0,5)
;  if (rlvlags(cc) lt 0.) then $
;   strrlvlags(cc)=strmid(strcompress(rlvlags(cc),/remove_all),0,6) else $
;   strrlvlags(cc)=strmid(strcompress(rlvlags(cc),/remove_all),0,5)
; endfor

 if (incre eq 0) then begin
  wind=thewind-windcorrect
 endif else begin
  wind=storewind-windcorrect
 endelse
 print,''
 booger=variance(wind,avg)
 print,strmid(strcompress(booger,/remove_all),0,7)
 print,''

 for dada=0,nimble do begin
  windcorrect=double(ampltd*sin(!dpi*2.*freqpeak*(time+truelag(dada))))
  if (incre eq 0) then begin
   wind=thewind-windcorrect
  endif else begin
   wind=storewind-windcorrect
  endelse
  newbooger=variance(wind,avg)
  if (newbooger lt booger) then begin
   booger=newbooger
   maxlag=truelag(dada)
   themaxx=dada
   print,strmid(strcompress(booger,/remove_all),0,7)
  endif
 endfor
 windcorrect=double(ampltd*sin(!dpi*2.*freqpeak*(time+maxlag)))
 if (incre eq 0) then begin
  wind=thewind-windcorrect
 endif else begin
  wind=storewind-windcorrect
 endelse
 print,''

; print,''
; print,''
; print, "you can now look at the wind correction with the different"
; print, "lags associated with the different peaks of the cross"
; print, "correlation coefficient"
; print,''
; print,''
; print, "here's the sinusoid with the lag correction corresponding"
; print, "to the peak cross correlation,"
; print,''
; print,''
; print, 'and the corrected wind data with the current '+$
;  'sinusoidal component and '+strcompress(incre,/remove_all)+$
;  ' other component(s) removed'
; print,''
; print,''
; print,''
; correctwindpart:
; windcorrect=double(ampltd*sin(!dpi*2.*freqpeak*(time+maxlag)))

; print,''
; print, "here's the sinusoid with the lag correction corresponding"
; print, "to the corrected wind with least variance."
; if (maxlag lt 0.) then $
;  lagmax=strmid(strcompress(maxlag,/remove_all),0,6) else $
;  lagmax=strmid(strcompress(maxlag,/remove_all),0,5)
; print,''
; window,1,retain=2
; wset,1
; plot,time,windcorrect,xrange=[corxrnmnvl,corxrnmxvl],$
;  xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
;  xtitle=thextitle,ytitle=yplottitle,$
;  subtitle=freqinfo+'!CPhase is '+lagmax+' hrs.',$
;  title=plotinfo+sinusoidinfo+'!CPhase corrected.',$
;  xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
;  xgridstyle=line,ygridstyle=1,psym=4,symsize=0.9,$
;  max_value=9999,pos=[0.1,0.2,0.9,0.85]
 print,''
 print,''
; if (incre eq 0) then begin
;  wind=thewind-windcorrect
; endif else begin
;  wind=storewind-windcorrect
; endelse
; print,''
; booger=variance(wind,avg)
; print,''
; print,''
; print, "this is the variance in this particular corrected wind series"
; print,strmid(strcompress(booger,/remove_all),0,7)
; print,''
; print,''
; print,''
; print, "and here is the corrected wind"
; print, 'it has a variance of '+strmid(strcompress(booger,/remove_all),0,7)
; print,''
; print, 'the corrected wind data has the current '+$
;  'sinusoidal component and '+strcompress(incre,/remove_all)+$
;  ' other component(s) removed'
; window,3,retain=2
; wset,3
; plot,time,wind,xrange=[corxrnmnvl,corxrnmxvl],$
;  xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
;  xtitle=thextitle,ytitle=yplottitle,$
;  title=plotinfo+'!C'+strcompress(incre+1,/remove_all)+$
;    ' sinusoidal component(s) removed',$
;  xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
;  xgridstyle=line,ygridstyle=1,psym=silly,symsize=0.9,$
;  max_value=9999,pos=[0.1,0.15,0.9,0.85] 
; print,''
; print,''
; decision9=''
; print, "do you want to try your wind correction with other possibly"
; print, "relevant lags?  y/n"
; print,''
; read, decision9
; if (decision9 eq 'y') then begin
;  print,''
;  print,''
;  print, "here are the cross correlation coefficients that are close"
;  print, "to the peak correlation, with the corresponding lags and index"
;  print,''
;  for mm=0,limbo-1 do print,strrlvcrs(mm),'   ',strrlvlags(mm),$
;     '   ',strcompress(rlvlgindx(mm),/remove_all)
;  print,''
;  print,''
;  print,''
;  print, 'recall, the current lag being used is '+lagmax+', of cross '+$
;   'correlation '+crossmax
;  print,'corresponding to index '+strcompress(themaxx,/remove_all)
;  print,''
;  print,''
;  print,''
;  print, "please select the index of the lag you want to use"
;  print,''
;  read, picky
;  themaxx=fix(picky)
;  for tricky=0,limbo-1 do begin
;   if (picky eq rlvlgindx(tricky)) then begin
;    maxlag=rlvlags(tricky)
;    maxcross=rlvcrscor(tricky)
;   endif
;  endfor
;  if (maxlag lt 0.) then $
;   lagmax=strmid(strcompress(maxlag,/remove_all),0,6) else $
;   lagmax=strmid(strcompress(maxlag,/remove_all),0,5)
;  if (maxcross lt 0.) then $
;   crossmax=strmid(strcompress(maxcross,/remove_all),0,6) else $
;   crossmax=strmid(strcompress(maxcross,/remove_all),0,5)
;  print,''
;  print,''
;  print, "here are the wind correction and the corrected wind time series"
;  print, "with the new lag"
;  print,''
;  print,''
; endif
; if (decision9 eq 'y') then goto,correctwindpart
; if (decision9 ne 'y') then begin
;  print,''
;  decision11=''
;  print, "do you want to go back and check a wider range of cross"
;  print, "correlations?  y/n"
;  print,''
;  read,decision11
;  if (decision11 eq 'y') then begin
;    maxcross=0.
;    maxlag=0.
;    for j=0,nimble do begin
;     if (abs(crosscorr(j)) gt abs(maxcross)) then begin
;      maxcross=crosscorr(j)
;      maxlag=truelag(j)
;      themaxx=j
;     endif
;    endfor
;    if (maxcross lt 0.) then $
;     crossmax=strmid(strcompress(maxcross,/remove_all),0,6) else $
;     crossmax=strmid(strcompress(maxcross,/remove_all),0,5)
;    if (maxlag lt 0.) then $
;     lagmax=strmid(strcompress(maxlag,/remove_all),0,6) else $
;     lagmax=strmid(strcompress(maxlag,/remove_all),0,5)
;  endif
;  if (decision11 eq 'y') then goto,checkcrscorrs
;  print,''
;  decision10=''
;  print, "this current lag is the lag you wish to use as the phase"
;  print, "to your wind correction sinusoid?  y/n"
;  print,''
;  read, decision10
;  if (decision10 eq 'y') then begin
   incre=incre+1
   increinfo='!C '+strcompress(incre,/remove_all)+' sinusoidal component(s) removed.'
   storewind=wind
   psfilesinusoid=psfilesinusoid+'nphz'
   print,''
   print,''
   print, "here's the sinusoid with the lag correction corresponding"
   print, "to the corrected wind with least variance."
   if (maxlag lt 0.) then $
    lagmax=strmid(strcompress(maxlag,/remove_all),0,6) else $
    lagmax=strmid(strcompress(maxlag,/remove_all),0,5)
   print,''
   print,''
   window,1,retain=2
   wset,1
   plot,time,windcorrect,xrange=[corxrnmnvl,corxrnmxvl],$
    xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
    xtitle=thextitle,ytitle=yplottitle,$
    subtitle=freqinfo+'!CPhase is '+lagmax+' hrs.',$
    title=plotinfo+sinusoidinfo+'!CPhase corrected.',$
    xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
    xgridstyle=line,ygridstyle=1,psym=4,symsize=0.9,$
    max_value=9999,pos=[0.1,0.2,0.9,0.85]
   print,''
   decision1=''
   print, "save this as postscript?  y/n"
   print,''
   read,decision1
   if (decision1 ne 'y') then goto,next7
   decision2=''
   print,''
   print, "here is the postscript filename"
   print,''
   print, psfilesinusoid+'.ps'
   print, ''
   print, "do you want to change it?  y/n"
   print,''
   read,decision2
   if (decision2 eq 'y') then begin
    print,''
    print, "type in the filename you want, including full directory"
    print, "structure, if necessary.  do not include the .ps"
    print,''
    read, psfilesinusoid
   endif
   set_plot,'ps'
   psfilename=psfilesinusoid+'.ps'
   device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
     xsize=6,yoffset=1.5,ysize=8,font_size=12
   plot,time,windcorrect,xrange=[corxrnmnvl,corxrnmxvl],$
    xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
    xtitle=thextitle,ytitle=yplottitle,$
    subtitle=freqinfo+'!CPhase is '+lagmax+' hrs.',$
    title=plotinfo+sinusoidinfo+'!CPhase corrected.',$
    xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
    xgridstyle=line,ygridstyle=1,psym=4,symsize=0.9,$
    max_value=9999,pos=[0,0.1,1,0.9]
   device,/close
   set_plot,'x'
   next7:

   print,''
   print, "saving sinusoid info to common block for future reference"
   print,''
   if (trig1 eq 'y') and (trig2 eq 'y') and (trig3 eq 'y') then begin
    print, "cants stores no more!"
   endif
   if (trig1 eq 'y') and (trig2 eq 'y') and (trig3 ne 'y') then begin
    trig3='y'
    correction3=windcorrect
    titleinfo3='!CSinusoidal component '+strcompress(incre,/remove_all)+$
     ' is of frequency '+peakfreq+' cycles/hr,!C'+$
     'corresponding to a period of '+peakperiod+' hrs.!C'+$
     'Amplitude of oscillation is '+stampltd+' m/s.'
   endif
   if (trig1 eq 'y') and (trig2 ne 'y') then begin
    trig2='y'
    correction2=windcorrect
    titleinfo2='!CSinusoidal component '+strcompress(incre,/remove_all)+$
     ' is of frequency '+peakfreq+' cycles/hr,!C'+$
     'corresponding to a period of '+peakperiod+' hrs.!C'+$
     'Amplitude of oscillation is '+stampltd+' m/s.'
   endif
   if (trig1 ne 'y') then begin
    trig1='y'
    correction1=windcorrect
    titleinfo1='!CSinusoidal component '+strcompress(incre,/remove_all)+$
     ' is of frequency '+peakfreq+' cycles/hr,!C'+$
     'corresponding to a period of '+peakperiod+' hrs.!C'+$
     'Amplitude of oscillation is '+stampltd+' m/s.'
   endif
   print,''
   print,''
   print, "and here is the corrected wind"
   print, 'it has a variance of '+strmid(strcompress(booger,/remove_all),0,7)
   print,''
   print, 'the corrected wind data has the current '+$
    'sinusoidal component and '+strcompress(incre-1,/remove_all)+$
    ' other component(s) removed'
   print,''
   window,3,retain=2
   wset,3
   plot,time,wind,xrange=[corxrnmnvl,corxrnmxvl],$
    xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
    xtitle=thextitle,ytitle=yplottitle,$
    title=plotinfo+increinfo,$
    xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
    xgridstyle=line,ygridstyle=1,psym=silly,symsize=0.9,$
    max_value=9999,pos=[0.1,0.15,0.9,0.85]
   print,''
   decision1=''
   print, "save this as postscript?  y/n"
   print,''
   read,decision1
   if (decision1 ne 'y') then goto,next8
    decision2=''
    print,''
    print, "here is the postscript filename"
    print,''
    print, psfilewindcorr+'.ps'
    print, ''
    print, "do you want to change it?  y/n"
    print,''
    read,decision2
    if (decision2 eq 'y') then begin
     print,''
     print, "type in the filename you want, including full directory"
     print, "structure, if necessary.  do not include the .ps"
     print,''
     read, psfilewindcorr
    endif
    set_plot,'ps'
    psfilename=psfilewindcorr+'.ps'
    device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
      xsize=6,yoffset=1.5,ysize=8,font_size=12
    plot,time,wind,xrange=[corxrnmnvl,corxrnmxvl],$
     xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
     xtitle=thextitle,ytitle=yplottitle,$
     title=plotinfo+increinfo,$
     xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
     xgridstyle=line,ygridstyle=1,psym=silly,symsize=0.9,$
     max_value=9999,pos=[0,0.1,1,0.9]
    device,/close
    set_plot,'x'
    next8:
;  endif
;  if (decision10 ne 'y') then print,"returning to windcorrection mode"
;  if (decision10 ne 'y') then goto,correctwindpart
; endif

 print,''
 decision3=''
 print, "you now have the option of generating another Lomb"
 print, "periodogram, based on the current time series, with"
 print, "its sinusoidal component(s) removed, or, more elaborately,"
 print, "you can generate a Lomb dynamic spectrum using this"
 print, "current time series"
 print,''
 print, "select an option"
 print,''
 print, "a.  continue on and generate a single Lomb periodogram"
 print,''
 print, "b.  generate a dynamic spectrum"
 print,''
 print, "c.  go back and start over with the original wind data,"
 print, "    that is, erase anything you have done to this point,"
 print, "    and go back to the original time series"
 print,''
 print, "d.  finish this analysis off, and go back to look at some"
 print, "    other sort of analysis"
 print,''
 print,''
 read,decision3
 if (decision3 eq 'a') then goto,continue3
 if (decision3 eq 'b') then begin
  call_procedure,'dynamicspec',wind,time,plotnumber,plottitle,$
    psfilenametmp,yranmaxval,yranminval,soup,soupest,$
    yplottitle,xplottitle,datadates,lent,line,silly,p,yr,location,$
    incre,increinfo
 endif
 if (decision3 eq 'b') then goto,startover
 if (decision3 eq 'c') then goto,startover
 if (decision3 eq 'd') then goto,doney
continue3:
endif
if (nextdecision eq 'b') then goto,tobegin

if (nextdecision eq 'c') then goto,startover
if (nextdecision eq 'd') then goto,doney

doney:

return

end

;  this routine is for constructing a dynamic spectrum of long
;  time series of wind data, e.g. a time series that is 72 hours long

pro dynamicspec,feelwind,feeltime,plotnumber,plottitle,$
    psfileinfo,yranmaxval,yranminval,xranmaxval,xranminval,$
    yplottitle,xplottitle,datadates,lent,line,silly,p,yr,location,$
    incre,increinfo

print,''
print,''
print,''
print, "Lomb Normalized Periodogram routine for generating"
print, "a dynamic spectrum of a long time series of unevenly"
print, "sampled wind data.  a power spectrum is generated for"
print, "each segmented piece of time series of wind data, at"
print, "increments you select"
print,''
print,''
print,''
print, "please enter the size of your time frame window in hours"
print,''
read,timeframesize
print,''
print, "please enter the incrementation value, i.e. the amount"
print, "of time, in decimal, to advance forward thru the wind data"
print, "after each periodogram is generated, e.g. 0.5 for every half hour"
print,''
read,timeincre

dummy=''
crosstitle=''
psfiledynlomb=''
freqinfo=''
lombinfo=''
timewindow=fix(0)
fronttime=0.
backtime=float(timeframesize)
newxplottitle='Time in UT."
datearray=datadates
xplotinfo=xplottitle
plotinfo=plottitle
wind=double(feelwind)
fullnumb=n_elements(wind)
time=feeltime
dynamicspec=fltarr(1,1)
dynamtime=fltarr(1)

testy1=fix(0) & testy2=fix(timeframesize*100) & maxnumb=fix(0)
nexttest:
testy3=fix(0)
for pp=0,fullnumb-1 do begin
 if (time(pp) ge testy1) and (time(pp) le testy2) then begin
  testy3=testy3+1
 endif
endfor
if (testy3 gt maxnumb) then maxnumb=testy3
testy1=testy1+fix(timeincre*100) & testy2=testy2+fix(timeincre*100)
if (testy2 gt max(time)) then goto,ufinish
goto,nexttest

ufinish:
fullbegin=min(time)
fullend=max(time)
middle=(fullbegin+fullend)/2
insouper=(souper+soup)/2
outsouper=(souper+soupest)/2
call_procedure,'crrctthetime',fullbegin,middle,fullend,insouper,outsouper,$
  stup,stuper,stupest,instuper,outstuper
print,''
print, 'your data covers the time frame of '+stup+' to '+stupest+' UT'
print,''

beginning:
print,''
winfo=strcompress(timewindow+1,/remove_all)
ftimeinfo=strmid(strcompress(fronttime,/remove_all),0,5)
btimeinfo=strmid(strcompress(backtime,/remove_all),0,5)
print,''
print, 'time window frame '+winfo+' extends from '+ftimeinfo+$
  ' to '+btimeinfo+'.'
print,''
print,''
frontchop=fix(fronttime*100)
print,''
print,''
endchop=fix(backtime*100)
newnumb=0 & gg=0
for qq=0,fullnumb-1 do begin
 if (time(qq) ge frontchop) and (time(qq) le endchop) then $
   newnumb=newnumb+1
endfor
trnktime=intarr(newnumb)
trnkwind=dblarr(newnumb)
for qq=0,fullnumb-1 do begin
 if (time(qq) ge frontchop) and (time(qq) le endchop) then begin
  trnktime(gg)=time(qq)
  trnkwind(gg)=wind(qq)
  gg=gg+1
 endif
endfor
numb=newnumb
calctime=trnktime
calcwind=trnkwind
soup=min(calctime)
soupest=max(calctime)
souper=(soup+soupest)/2
insouper=(souper+soup)/2
outsouper=(souper+soupest)/2
call_procedure,'crrctthetime',soup,souper,soupest,insouper,outsouper,$
  stup,stuper,stupest,instuper,outstuper
datearray=strarr(5)
datearray=[stup,instuper,stuper,outstuper,stupest]

flttime=dblarr(numb)
for j=0,numb-1 do begin
 thtime=calctime(j)
 thtime=strcompress(thtime,/remove_all)
 call_procedure,'dectime',thtime
 flttime(j)=thtime
endfor
calctime=flttime
corxrnmnvl=min(calctime)
corxrnmxvl=max(calctime)

print,''
print, "here's the data of the current time frame"
print,''
print,''
window,0,retain=2
wset,0
plot,calctime,calcwind,xrange=[corxrnmnvl,corxrnmxvl],$
 xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
 xtitle=newxplottitle,ytitle=yplottitle,subtitle='!C'+increinfo,$
 title=plotinfo,$
 xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
 xgridstyle=line,ygridstyle=1,psym=silly,symsize=0.9,$
 max_value=9999,pos=[0.1,0.15,0.9,0.85]
print,''

print,''
print,''
print, "windowing the wind data with a Welch window"
print,''
print,''
welchwindow=welch(numb)
calcwind(*)=calcwind(*)*welchwindow(*)
print,''
windowinfo='!CMultiplied by a Welch window.'
print, "and here's the data multiplied by the Welch window"
print,''
print,''
window,1,retain=2
wset,1
plot,calctime,calcwind,xrange=[corxrnmnvl,corxrnmxvl],$
 xstyle=1,ystyle=1,yrange=[yranminval,yranmaxval],yticklen=1.0,$
 xtitle=newxplottitle,ytitle=yplottitle,subtitle='!C'+increinfo,$
 title=plotinfo+windowinfo,$
 xticks=p,xtickname=datearray,xminor=4,yminor=2,xticklen=lent,$
 xgridstyle=line,ygridstyle=1,psym=silly,symsize=0.9,$
 max_value=9999,pos=[0.1,0.15,0.9,0.85]
print,''

firsttime=fronttime
lasttime=backtime
call_procedure,'generatelomb',calcwind,calctime,maxnumb,freq,lomb,np,$
   lombmax,freqpeak,prob,jmax,lwfrq,hghfrq,rlvfrqs,rlvindx,she,$
   dasher,signiflomb,var,meany,firsttime,lasttime

if (timewindow eq 0) then begin
 dynamicspec=dblarr(1,np)
 dynamictime=fltarr(1)
 indxdyntime=intarr(1)
endif

probinfo=strcompress(string(prob,format='(f25.16)'),/remove_all)
probinfo=strmid(probinfo,0,6)
normpower=strmid(strcompress(lombmax,/remove_all),0,5)
peakfreq=strmid(strcompress(freqpeak,/remove_all),0,6)
peakperiod=strmid(strcompress((1./freqpeak),/remove_all),0,6)

lombinfo='!C'+'Peak of the Lomb Spectrum occurs at frequency '+$
  peakfreq+' cycles/hr,!C'+'corresponding to a period of '+peakperiod+$
  ' hrs.!C'+'Significance level is '+probinfo+'.!C'+$$
  'Normalized power at the peak is '+normpower+'.'

psfilelomb=psfileinfo+'lombspec'+strcompress(incre,/remove_all)
print,''
print, 'this is the full Lomb spectrum'
print,''

window,2,retain=2
wset,2
plot,freq,lomb,xrange=[lwfrq,hghfrq],$
  title='Normalized Lomb Periodogram of!C'+plotinfo,$
  ytitle='Spectral Power.',xtitle='Frequency in cycles/hr.',$
  subtitle=lombinfo,xstyle=1,$
  ystyle=1,pos=[0.1,0.2,0.9,0.85]
oplot,freq,dasher,linestyle=2
; oplot,freq,dasher2,linestyle=3
xyouts,freq(fix(0.666666*np)+3),signiflomb,'significance level 0.05'
; xyouts,freq(fix(0.666666*np)+3),signiflomb2,'significance level 0.001'
print,''
print, "freqs with prob. higher than 0.05 are"
for jj=0,she-1 do begin
 print,strmid(strcompress(rlvfrqs(jj),/remove_all),0,6),'   ',$
   strcompress(rlvindx(jj),/remove_all)
endfor
print,''
print, "this spectrum is being added to the dynamic spectrum array"
print,''
print, "moving on to next time window"
print,''

prvtimewindow=timewindow
timewindow=timewindow+1
if (prvtimewindow eq 0) then goto,skippy
 strddyspec=dblarr(prvtimewindow,np)
 strddytime=fltarr(prvtimewindow)
 strdindxdytime=intarr(prvtimewindow)
 strddyspec(*,*)=dynamicspec(*,*)
 strddytime(*)=dynamictime(*)
 strdindxdytime(*)=indxdyntime(*)
 dynamicspec=dblarr(timewindow,np)
 dynamictime=fltarr(timewindow)
 indxdyntime=intarr(timewindow)
 for yy=0,prvtimewindow-1 do begin
  dynamicspec(yy,*)=strddyspec(yy,*)
  dynamictime(yy)=strddytime(yy)
  indxdyntime(yy)=strdindxdytime(yy)
 endfor
skippy:
dynamicspec(timewindow-1,*)=lomb(*)
dynamictime(timewindow-1)=(fronttime+backtime)/2.
indxdyntime(timewindow-1)=timewindow

fronttime=fronttime+timeincre
backtime=backtime+timeincre
if (fix(backtime*100) gt fullend) then goto,done

goto, beginning

done:

psfiledynlomb=psfileinfo+'dynlomb'+strcompress(incre,/remove_all)
scaledspec=dblarr(timewindow,np)
for ii=0,timewindow-1 do begin
 for jj=0,np-1 do begin
  scaledspec(ii,jj)=dynamicspec(ii,jj)-signiflomb
  if (scaledspec(ii,jj) lt 0.) then scaledspec(ii,jj)=0.
 endfor
endfor
period=1./freq

; theticks=timewindow/

print,''
print, "dynamic spectrum complete.  here it is"
print,''

loadct=4
contour,dynamicspec,indxdyntime,freq,/nodata,/noerase,$
 xstyle=1,ystyle=1,$
 xtitle='Mean time of each time window.',$
 ytitle='Frequency in cycles/hr.',$
 title='Lomb Dynamic Spectrum for '+plotinfo+'!C'+increinfo,$
 pos=[0.1,0.15,0.9,0.85]
tvscl,dynamicspec,0.11,0.16,/normal

print,''
decision1=''
print,''
print, "save this as postscript?  y/n"
print,''
read,decision1
if (decision1 eq 'y') then begin
 decision2=''
 print,''
 print, "here is the postscript filename"
 print,''
 print, psfiledynlomb+'.ps'
 print, ''
 print, "do you want to change it?  y/n"
 print,''
 read,decision2
 if (decision2 eq 'y') then begin
  print,''
  print, "type in the filename you want, including full directory"
  print, "structure, if necessary.  do not include the .ps"
  print,''
  read, psfiledynlomb
 endif
 set_plot,'ps'
 psfilename=psfiledynlomb+'.ps'
 device,filename=psfilename,/helvetica,/bold,/inches,xoffset=1.25,$
   xsize=6,yoffset=1.5,ysize=8,font_size=12
 tvscl,scaledspectrum
 contour,scaledspectrum,dynamictime,freq,/nodata,xstyle=1,ystyle=1,$
  xtitle='Mean time of each data window.',$
  ytitle='Frequency in cycles/hr.',$
  title='Lomb Dynamic Spectrum for '+plotinfo+'!C'+increinfo
 device,/close
 set_plot,'x'
endif

print,''
print, "Finished with dynamic spectrum calculations."
print, "Returning to standard Lomb periodogram options,"
print, "still using the current time series."
print,''
 
return

end

;  this sub begins the process of histogram analysis

pro starthistogram,lasttrigger,trigger1,trigger2

print,''
; print, "Note:  you will NOT be prompted to save the plots"
; print, "you generate until you have completed adding data"
; print, "to a partictular histogram."
print,''
; print, "Once you have decided that a particular histogram"
; print, "is complete, you will be given the option of"
; print, "saving the histogram to postscript file, the"
; print, "histogram with its Gaussian fit, the residual of"
; print, "the Gaussian from the histogram, and the option"
; print, "of seeing the Gaussian plotted with other Gaussian"
; print, "Gaussian fits from previous histograms."
print,''

call_procedure,'getsiteinfo',location,site,datatype,plottype,fileext

; m and k are the key!  my initials...
m=0 & k=0 & steppinstone=0

call_procedure,'rangeofdays',date1,date2,yr,steppinstone
call_procedure,'defineimportant',date,dat1,dat2,date1,date2,month1,$
  month2,day1,day2,mnthval1,mnthval2
call_procedure,'compiledata',windtot,date,date1,date2,dat1,dat2,yr,$
  m,k,location,datatype,fileext

; save the size of the current wind data array.
size=m & increm=k

call_procedure,'findscaling',vplotarray,yplotarray,histtotal,$
  windtot,xitchy,yitchy,butt,bigbin
call_procedure,'starthisting',windtot,histtotal,rndedhisttotal,$
  leftovers,duallftovrs,stinky,butt,bigbin
call_procedure,'plothistograms',windtot,histtotal,rndedhisttotal,$
  stinky,leftovers,duallftovrs,vplotarray,yplotarray,xitchy,$
  yitchy,plottype,site,day1,day2,mnthval1,$
  mnthval2,month1,month2,yr,date1,date2,dat1,dat2,location,$
  datatype,fileext,size,increm,butt,lasttrigger,steppinstone,$
  trigger1,trigger2

return

end

;  this sub reads the relevant wind data and creates the arrays
;  for doing the histogram analysis.  the sub is similar to the
;  other reading routines but a bit different because it does not
;  require nearly as much information passed to it.

pro compiledata,windtot,date,date1,date2,dat1,dat2,yr,m,k,location,$
     datatype,fileext

switch=''
thefile=''
fulldate=''
tmdate=''
year=''
dummy=''

;  start the process of reading the data and forming the arrays

startthehist:

dat=fix(date)
mnthval=strmid(date,0,1)
day=strmid(date,1,2)

;  defining the data filename

thefile='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+'/'+ $
    datatype+'/'+fileext+date+'.dbt'

;  open and read the file to determine the size.
;  and go to the relevant section to add null data,
;  see below for details.

openr,3,thefile,error=bad
 if (bad ne 0) then print, "there is no data for "+date
 if (bad ne 0) then print, "skipping to next day"
 if (bad ne 0) then print,''
 if (bad ne 0) then goto, createnextdayfile

j=0
while (not eof(3)) do begin
 readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
   dum6,dum7,dum8,dum9
   if (dum5 gt 250) or (dum5 lt -250) then goto, dontincre
j=j+1
dontincre:
endwhile
close,3

;  n defines the size of each datafile after it is read.
;  define the array sizes and types for the day's data.

n=j
wind=fltarr(n)
year=strmid(fulldate,0,2)

;  open it now to read it and store the data

openr,3,thefile

i=0
while (not eof(3)) do begin
 readf,3,format='(a6,i6,2i8,5f8.1)',fulldate,dum2,dum3,dum4,dum5, $
   dum6,dum7,dum8,dum9
  if (dum5 gt 250) or (dum5 lt -250) then goto, dontdoit
   wind(i)=dum5
i=i+1
dontdoit:
endwhile

close,3

;  start building the all days arrays, skipping the storage phase
;  on the first go around.

;  m defines the size of the all days arrays
;  g is used as a go-between for the storage arrays,
;  when we need to redefine the size of the all days arrays.

g=m
m=m+n

;  skip the storage phase on first loop

if (g eq 0) then goto, dontstorearray
  storewind=fltarr(g)
  storewind(*)=windtot(*)
dontstorearray:

;  define the size of the all days arrays.

windtot=fltarr(m)

;  skipping the storage phase

if (g eq 0) then goto, skippedpart
 for l=0,g-1 do begin
  windtot(l)=storewind(l)
 endfor
skippedpart:

;  build the all days arrays

h=0
createarray:
 windtot(k)=wind(h)
k=k+1 & h=h+1
if (h lt n) then goto, createarray

createnextdayfile:

; the following call changes the date string and the switch string
; if it is necessary.  that is, if the data range covers
; different months, we need to properly change the date string
; so that the computer knows what to look for.

call_procedure, 'chngmnthdate',mnthval,day,date,switch

;  the dat and dat2 variables are used to determine if we are
;  done reading data, then go to the plotting section.

if (dat eq dat2) then goto, done

;  didn't go to plotting section so now check for a switch
;  that is, did month change.

if (switch ne 'y') then begin
 dat=dat+1
 date=strcompress(dat,/remove_all)
endif

;  set switch back
switch=''

;  return to top to continue looping thru requested data range

goto, startthehist

done:

return

end

;  this routine gives a requested scaling to the bins for the 
;  histogram plots.

pro findscaling,vplotarray,yplotarray,histtotal,windtot,xitchy,yitchy,$
    butt,bigbin

themaxx=max(windtot) & theminn=min(windtot)

question=''
scale=''

;  building the histogram array.  resolution, the bin size,
;  is always 5 m/s

print,''
print,''
print, "pick your own scale for the histogram or the computer"
print, "will pick the minimum scale to accomodate the data"
print,''
print, "a.  your own choice or"
print, "b.  the computer scales"
print,''
read, question
if (question eq 'a') then begin
  print,''
  print,''
  print, "pick the scale you want to see this data on"
  print,''
  print, "a.  -125 m/s to 125 m/s"
  print, "b.  -150 to 150"
  print, "c.  -175 to 175"
  print, "d.  -200 to 200"
  print, "e.  -225 to 225"
  print, "f.  -250 to 250"
  print,''
  read, scale
endif
if (question eq 'a') and (scale eq 'a') or $
 (question ne 'a') and (themaxx le 125) or $
 (question ne 'a') and (theminn ge -125) then begin $
  xitchy=10
  butt=51
  histtotal=intarr(butt)
  bigbin=125
  yitchy=fix(butt/8)
  yplotarray=replicate('     ',yitchy+1)
  vplotarray=strarr(11)
  vplotarray(0)='-125'
  vplotarray(1)='-100'
  vplotarray(2)='-75'
  vplotarray(3)='-50'
  vplotarray(4)='-25'
  vplotarray(5)='0'
  vplotarray(6)='25'
  vplotarray(7)='50'
  vplotarray(8)='75'
  vplotarray(9)='100'
  vplotarray(10)='125'
endif
if (question eq 'a') and (scale eq 'b') or $
 (question ne 'a') and (themaxx gt 125) and (themaxx le 150) or $
 (question ne 'a') and (theminn lt -125) and (theminn ge -150) then begin
  xitchy=12
  butt=61
  histtotal=intarr(butt)
  bigbin=150
  yitchy=fix(butt/8)
  yplotarray=replicate('     ',yitchy+1)
  vplotarray=strarr(13)
  vplotarray(0)='-150'
  vplotarray(1)='-125'
  vplotarray(2)='-100'
  vplotarray(3)='-75'
  vplotarray(4)='-50'
  vplotarray(5)='-25'
  vplotarray(6)='0'
  vplotarray(7)='25'
  vplotarray(8)='50'
  vplotarray(10)='100'
  vplotarray(11)='125'
  vplotarray(12)='150'
endif
if (question eq 'a') and (scale eq 'c') or $
 (question ne 'a') and (themaxx gt 150) and (themaxx le 175) or $
 (question ne 'a') and (theminn lt -150) and (theminn ge -175) then begin
  xitchy=14
  butt=71
  histtotal=intarr(butt)
  bigbin=175
  yitchy=fix(butt/8)
  yplotarray=replicate('     ',yitchy+1)
  vplotarray=strarr(15)
  vplotarray(0)='-175'
  vplotarray(1)='-150'
  vplotarray(2)='-125'
  vplotarray(3)='-100'
  vplotarray(4)='-75'
  vplotarray(5)='-50'
  vplotarray(6)='-25'
  vplotarray(7)='0'
  vplotarray(8)='25'
  vplotarray(9)='50'
  vplotarray(10)='75'
  vplotarray(11)='100'
  vplotarray(12)='125'
  vplotarray(13)='150'
  vplotarray(14)='175'
endif
if (question eq 'a') and (scale eq 'd') or $
 (question ne 'a') and (themaxx gt 175) and (themaxx le 200) or $
 (question ne 'a') and (theminn lt -175) and (theminn ge -200) then begin
  xitchy=16
  butt=81
  histtotal=intarr(butt)
  bigbin=200
  yitchy=fix(butt/8)
  yplotarray=replicate('     ',yitchy+1)
  vplotarray=strarr(17)
  vplotarray(0)='-200'
  vplotarray(1)='-175'
  vplotarray(2)='-150'
  vplotarray(3)='-125'
  vplotarray(4)='-100'
  vplotarray(5)='-75'
  vplotarray(6)='-50'
  vplotarray(7)='-25'
  vplotarray(8)='0'
  vplotarray(9)='25'
  vplotarray(10)='50'
  vplotarray(11)='75'
  vplotarray(12)='100'
  vplotarray(13)='125'
  vplotarray(14)='150'
  vplotarray(15)='175'
  vplotarray(16)='200'
endif
if (question eq 'a') and (scale eq 'e') or $
 (question ne 'a') and (themaxx gt 200) and (themaxx le 225) or $
 (question ne 'a') and (theminn lt -200) and (theminn ge -225) then begin
  xitchy=18
  butt=91
  histtotal=intarr(butt)
  bigbin=225
  yitchy=fix(butt/8)
  yplotarray=replicate('     ',yitchy+1)
  vplotarray=strarr(19)
  vplotarray(0)='-225'
  vplotarray(1)='-200'
  vplotarray(2)='-175'
  vplotarray(3)='-150'
  vplotarray(4)='-125'
  vplotarray(5)='-100'
  vplotarray(6)='-75'
  vplotarray(7)='-50'
  vplotarray(8)='-25'
  vplotarray(9)='0'
  vplotarray(10)='25'
  vplotarray(11)='50'
  vplotarray(12)='75'
  vplotarray(13)='100'
  vplotarray(14)='125'
  vplotarray(15)='150'
  vplotarray(16)='175'
  vplotarray(17)='200'
  vplotarray(18)='225'
endif
if (question eq 'a') and (scale eq 'f') or $
 (question ne 'a') and (themaxx gt 225) and (themaxx le 250) or $
 (question ne 'a') and (theminn lt -225) and (theminn ge -250) then begin
  xitchy=20
  butt=101
  histtotal=intarr(butt)
  bigbin=250
  yitchy=fix(butt/8)
  yplotarray=replicate('     ',yitchy+1)
  vplotarray=strarr(21)
  vplotarray(0)='-250'
  vplotarray(1)='-225'
  vplotarray(2)='-200'
  vplotarray(3)='-175'
  vplotarray(4)='-150'
  vplotarray(5)='-125'
  vplotarray(6)='-100'
  vplotarray(7)='-75'
  vplotarray(8)='-50'
  vplotarray(9)='-25'
  vplotarray(10)='0'
  vplotarray(11)='25'
  vplotarray(12)='50'
  vplotarray(13)='75'
  vplotarray(14)='100'
  vplotarray(15)='125'
  vplotarray(16)='150'
  vplotarray(17)='175'
  vplotarray(18)='200'
  vplotarray(19)='225'
  vplotarray(20)='250'
endif

return

end

;  this sub actually creates the histogramed wind data, that is,
;  actually bins the wind measurements into 5 m/s bins.

pro starthisting,windtot,histtotal,rndedhisttotal,leftovers,$
    duallftovrs,stinky,butt,bigbin

for b=0,bigbin,5 do begin
 if (b eq 0) then begin
  dummyzero=where(windtot ge -(b+2.5) and windtot lt b+2.5, hist0)
 endif
 if (b eq 0) then goto, blah1
  dummyp=where(windtot ge b-2.5 and windtot lt b+2.5, hist1)
  dummyn=where(windtot lt -(b-2.5) and windtot gt -(b+2.5), hist2)
  histtotal((butt-1)/2)=hist0
  histtotal((b/5)+((butt-1)/2))=hist1
  histtotal(((butt-1)/2)-(b/5))=hist2
blah1:
endfor

rndedhisttotal=round(histtotal)
leftovers=intarr(butt)
duallftovrs=intarr(butt)
stinky=indgen(butt)

return

end

;  this sub provides the fitted gaussian distribution, the
;  width, peak position, and height of a given histogram.
;  thanks Mark.

pro gauss,inx,iny,xpos,width,height,fit

;=============================================
;
;  Given arrays inx, and iny, this routine
;  returns the position, width, height, and
;  the best-fit Gaussian for those data.
;
;  Mark Conde, Fairbanks, June 1998.

   npt    = n_elements(inx)
   n      = total(iny)
   xy     = total(inx*iny)
   xpos   = xy/n
   dev    = iny*(inx-xpos)^2
   width  = sqrt(total(dev)/n)
   steps  = inx(1:npt-1) - inx(0:npt-2)
   area   = total(steps*(iny(1:npt-1) + iny(0:npt-2))/2)
   height = area/(width*2*sqrt(!pi))*sqrt(2)
   fit    = height*exp(-0.5*((inx-xpos)/width)^2)

return

end

;  this sub plots the stored gaussian fits with the current
;  gaussian fit

pro pltoldhstofits,stinky,thefit,rangeofy,fllgssxtitle,$
   xitchy,vplotarray,gssplttitle,nrmalzedfit,nrmrngeofy,butt,$
   strdgssdtetitl,strdteinfo,yitchy,yplotarray,trigger1,trigger2,$
   gsspsfiletmp,yplttitl

common stored1,oldstinky1,oldfit1,oldrngofy1,oldfllgssxttl1,$
   oldxitchy1,oldyitchy1,oldypltrray1,oldvpltrray1,$
   oldgssplttitl1,oldnrmlzedft1,$
   oldnrmrngofy1,oldbutt1,oldgssdtetitl1,olddteinfo1
common stored2,oldstinky2,oldfit2,oldrngofy2,oldfllgssxttl2,$
   oldxitchy2,oldyitchy2,oldypltrray2,oldvpltrray2,$
   oldgssplttitl2,oldnrmlzedft2,$
   oldnrmrngofy2,oldbutt2,oldgssdtetitl2,olddteinfo2

dummy=''
!p.font=0

if (trigger1 eq 'y') and (trigger2 ne 'y') then begin
 decision=''
 print,''
 print, "the current gaussian will be saved automatically"
 print,''
 print, "do you want to see the other stored gaussian"
 print, "plotted with the current gaussian?  y/n"
 print,''
 read,decision
 if (decision ne 'y') then goto,goback
 print,''
 print, "here is the previously stored gaussian fit."
 print, "you had the chance to save it as postscript already"
 print,''
 wset,0
 plot,oldstinky1,oldfit1,yrange=[0,oldrngofy1],ystyle=1,$
  xstyle=1,xticklen=1.0,xtitle=oldfllgssxttl1,xticks=oldxitchy1,$
  xtickname=oldvpltrray1,title=oldgssplttitl1,thick=2.0,$
  xgridstyle=1,xminor=2,yminor=2,ytitle=yplttitl,$
  pos=[0.1,0.1,0.9,0.9]
 print, "hit any key to continue"
 read,dummy
 print,''
 print, "here is the previously stored gaussian and the"
 print, "current gaussian plotted together"
 print,''
 print,''
 if (oldnrmrngofy1 gt nrmrngeofy) then $
  thisnormrange=oldnrmrngofy1 else thisnormrange=nrmrngeofy
 if (oldbutt1 gt butt) then begin
  temp=fltarr(oldbutt1)
  endpieces=oldbutt1-butt
  endpieces=endpieces/2
  love=oldbutt1-1
  temp(0:endpieces)=0
  temp(love-endpieces:love)=0
  temp(endpieces:love-endpieces)=nrmalzedfit
  wset,0
  plot,oldstinky1,oldnrmlzedft1,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=oldxitchy1,thick=2.0,$
   xtickname=oldvpltrray1,xgridstyle=1,xminor=2,yticks=oldyitchy1,$
   title=gssplttitle+'!C'+oldgssdtetitl1,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1,$
   ytickname=oldypltrray1,pos=[0.1,0.15,0.9,0.9],$
   yminor=2
  oplot,oldstinky1,temp
  decision=''
  print,''
  print, "save this as a postscript?  y/n"
  print,''
  read,decision
  if (decision ne 'y') then goto,goback
  set_plot,'ps'
  gausspsfileA=gsspsfletmp+olddteinfo1+'.ps'
  device,filename=gausspsfileA,/helvetica,/bold,/inches,$
    xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
  plot,oldstinky1,oldnrmlzedft1,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=oldxitchy1,thick=2.0,$
   xtickname=oldvpltrray1,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1,$
   pos=[0,0.1,1,0.9],ytickname=oldypltrray1,yticks=oldyitchy1,$
   yminor=2
  oplot,oldstinky1,temp
  device,/close
  set_plot,'x'
 endif
 if (butt gt oldbutt1) then begin
  temp=fltarr(butt)
  endpieces=butt-oldbutt1
  endpieces=endpieces/2
  love=butt-1
  temp(0:endpieces)=0
  temp(love-endpieces:love)=0
  temp(endpieces:love-endpieces)=oldnrmlzedft1
  wset,0
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1,$
   ytickname=yplotarray,pos=[0.1,0.15,0.9,0.9],yticks=yitchy,$
   yminor=2
  oplot,stinky,temp
  decision=''
  print,''
  print, "save this as a postscript?  y/n"
  print,''
  read,decision
  if (decision ne 'y') then goto,goback
  set_plot,'ps'
  gausspsfileA=gsspsfletmp+olddteinfo1+'.ps'
  device,filename=gausspsfileA,/helvetica,/bold,/inches,$
    xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1,$
   pos=[0,0.1,1,0.9],ytickname=yplotarray,yticks=yitchy,$
   yminor=2
  oplot,stinky,temp
  device,/close
  set_plot,'x'
 endif
 if (butt eq oldbutt1) then begin
  wset,0
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1,$
   ytickname=yplotarray,pos=[0.1,0.15,0.9,0.9],yticks=yitchy,$
   yminor=2
  oplot,oldstinky1,oldnrmlzedft1
  decision=''
  print,''
  print, "save this as a postscript?  y/n"
  print,''
  read,decision
  if (decision ne 'y') then goto,goback
  set_plot,'ps'
  gausspsfileA=gsspsfletmp+olddteinfo1+'.ps'
  device,filename=gausspsfileA,/helvetica,/bold,/inches,$
    xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1,$
   pos=[0,0.1,1,0.9],ytickname=yplotarray,yticks=yitchy,$
   yminor=2
  oplot,oldstinky1,oldnrmlzedft1
  device,/close
  set_plot,'x'
 endif
goto,goback
endif

if (trigger1 eq 'y') and (trigger2 eq 'y') then begin
 decision=''
 print,''
 print, "do you want to see the other stored gaussians"
 print, "plotted with the current gaussian?  y/n"
 print,''
 read,decision
 if (decision ne 'y') then goto,donehere
 print,''
 print, "here are the other two previously stored gaussians."
 print, "you had the chance to save these as postscript already"
 print,''
 wset,0
 plot,oldstinky1,oldfit1,yrange=[0,oldrngofy1],ystyle=1,$
  xstyle=1,xticklen=1.0,xtitle=oldfllgssxttl1,xticks=oldxitchy1,$
  xtickname=oldvpltrray1,title=oldgssplttitl1,thick=2.0,$
  xgridstyle=1,xminor=2,pos=[0.1,0.1,0.9,0.9],$
  yminor=2,ytitle=yplttitl
 wset,1
 plot,oldstinky2,oldfit2,yrange=[0,oldrngofy2],ystyle=1,$
  xstyle=1,xticklen=1.0,xtitle=oldfllgssxttl2,xticks=oldxitchy2,$
  xtickname=oldvpltrray2,title=oldgssplttitl2,thick=2.0,$
  xgridstyle=1,xminor=2,pos=[0.1,0.1,0.9,0.9],$
  yminor=2,ytitle=yplttitl
 print, "hit any key to continue"
 read,dummy
 print,''
 print, "here are the two previously stored gaussians plotted"
 print, "separately with the current gaussian"
 print,''
 print, "stored fit # 1 and current gaussian"
 print,''
 if (oldnrmrngofy1 gt nrmrngeofy) then $
  thisnormrange=oldnrmrngofy1 else thisnormrange=nrmrngeofy
 if (oldbutt1 gt butt) then begin
  temp=fltarr(oldbutt1)
  endpieces=oldbutt1-butt
  endpieces=endpieces/2
  love=oldbutt1-1
  temp(0:endpieces)=0
  temp(love-endpieces:love)=0
  temp(endpieces:love-endpieces)=nrmalzedfit
  wset,0
  plot,oldstinky1,oldnrmlzedft1,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=oldxitchy1,thick=2.0,$
   xtickname=oldvpltrray1,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1,$
   pos=[0.1,0.15,0.9,0.9],ytickname=oldypltrray1,yticks=oldyitchy1,$
   yminor=2
  oplot,oldstinky1,temp
  decision=''
  print,''
  print, "save this as a postscript?  y/n"
  print,''
  read,decision
  if (decision ne 'y') then goto,nextpart
  set_plot,'ps'
  gausspsfileA=gsspsfletmp+olddteinfo1+'.ps'
  device,filename=gausspsfileA,/helvetica,/bold,/inches,$
    xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
  plot,oldstinky1,oldnrmlzedft1,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=oldxitchy1,thick=2.0,$
   xtickname=oldvpltrray1,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1,$
   pos=[0,0.1,1,0.9],ytickname=oldypltrray1,yticks=oldyitchy1,$
   yminor=2
  oplot,oldstinky1,temp
  device,/close
  set_plot,'x'
 endif
 if (butt gt oldbutt1) then begin
  temp=fltarr(butt)
  endpieces=butt-oldbutt1
  endpieces=endpieces/2
  love=butt-1
  temp(0:endpieces)=0
  temp(love-endpieces:love)=0
  temp(endpieces:love-endpieces)=oldnrmlzedft1
  wset,0
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1,$
   ytickname=yplotarray,pos=[0.1,0.15,0.9,0.9],yticks=yitchy,$
   yminor=2
  oplot,stinky,temp
  decision=''
  print,''
  print, "save this as a postscript?  y/n"
  print,''
  read,decision
  if (decision ne 'y') then goto,nextpart
  set_plot,'ps'
  gausspsfileA=gsspsfletmp+olddteinfo1+'.ps'
  device,filename=gausspsfileA,/helvetica,/bold,/inches,$
    xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1,$
   pos=[0,0.1,1,0.9],ytickname=yplotarray,yticks=yitchy,$
   yminor=2
  oplot,stinky,temp
  device,/close
  set_plot,'x'
 endif
 if (butt eq oldbutt1) then begin
  wset,0
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1,$
   ytickname=yplotarray,pos=[0.1,0.15,0.9,0.9],yticks=yitchy,$
   yminor=2
  oplot,oldstinky1,oldnrmlzedft1
  decision=''
  print,''
  print, "save this as a postscript?  y/n"
  print,''
  read,decision
  if (decision ne 'y') then goto,nextpart
  set_plot,'ps'
  gausspsfileA=gsspsfletmp+olddteinfo1+'.ps'
  device,filename=gausspsfileA,/helvetica,/bold,/inches,$
    xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1,$
   pos=[0,0.1,1,0.9],ytickname=yplotarray,yticks=yitchy,$
   yminor=2
  oplot,oldstinky1,oldnrmlzedft1
  device,/close
  set_plot,'x'
 endif
nextpart:
 print, "stored fit # 2 and current gaussian"
 print,''
 if (oldnrmrngofy2 gt nrmrngeofy) then $
  thisnormrange=oldnrmrngofy2 else thisnormrange=nrmrngeofy
 if (oldbutt2 gt butt) then begin
  temp=fltarr(oldbutt2)
  endpieces=oldbutt2-butt
  endpieces=endpieces/2
  love=oldbutt2-1
  temp(0:endpieces)=0
  temp(love-endpieces:love)=0
  temp(endpieces:love-endpieces)=nrmalzedfit
  wset,1
  plot,oldstinky2,oldnrmlzedft2,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=oldxitchy2,thick=2.0,$
   xtickname=oldvpltrray2,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl2,$
   pos=[0.1,0.15,0.9,0.9],ytickname=oldypltrray2,yticks=oldyitchy2,$
   yminor=2
  oplot,oldstinky2,temp
  decision=''
  print,''
  print, "save this as a postscript?  y/n"
  print,''
  read,decision
  if (decision ne 'y') then goto,nextpart2
  set_plot,'ps'
  gausspsfileA=gsspsfletmp+olddteinfo2+'.ps'
  device,filename=gausspsfileA,/helvetica,/bold,/inches,$
    xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
  plot,oldstinky2,oldnrmlzedft2,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=oldxitchy2,thick=2.0,$
   xtickname=oldvpltrray2,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl2,$
   pos=[0,0.1,1,0.9],ytickname=oldypltrray2,yticks=oldyitchy2,$
   yminor=2
  oplot,oldstinky2,temp
  device,/close
  set_plot,'x'
 endif
 if (butt gt oldbutt2) then begin
  temp=fltarr(butt)
  endpieces=butt-oldbutt2
  endpieces=endpieces/2
  love=butt-1
  temp(0:endpieces)=0
  temp(love-endpieces:love)=0
  temp(endpieces:love-endpieces)=oldnrmlzedft2
  wset,1
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl2,$
   ytickname=yplotarray,pos=[0.1,0.15,0.9,0.9],yticks=yitchy,$
   yminor=2
  oplot,stinky,temp
  decision=''
  print,''
  print, "save this as a postscript?  y/n"
  print,''
  read,decision
  if (decision ne 'y') then goto,nextpart2
  set_plot,'ps'
  gausspsfileA=gsspsfletmp+olddteinfo2+'.ps'
  device,filename=gausspsfileA,/helvetica,/bold,/inches,$
    xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl2,$
   pos=[0,0.1,1,0.9],ytickname=yplotarray,yticks=yitchy,$
   yminor=2
  oplot,stinky,temp
  device,/close
  set_plot,'x'
 endif
 if (butt eq oldbutt2) then begin
  wset,1
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl2,$
   ytickname=yplotarray,pos=[0.1,0.15,0.9,0.9],yticks=yitchy,$
   yminor=2
  oplot,oldstinky2,oldnrmlzedft2
  decision=''
  print,''
  print, "save this as a postscript?  y/n"
  print,''
  read,decision
  if (decision ne 'y') then goto,nextpart2
  set_plot,'ps'
  gausspsfileA=gsspsfletmp+olddteinfo2+'.ps'
  device,filename=gausspsfileA,/helvetica,/bold,/inches,$
    xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl2,$
   pos=[0,0.1,1,0.9],ytickname=yplotarray,yticks=yitchy,$
   yminor=2
  oplot,oldstinky2,oldnrmlzedft2
  device,/close
  set_plot,'x'
 endif
nextpart2:
 print,''
 print, "here are the two previously stored gaussians plotted"
 print, "together with the current gaussian"
 print,''
 if (oldnrmrngofy2 gt oldnrmrngofy1) and $
   (oldnrmrngofy2 gt nrmrngeofy) then begin
   thisnormrange=oldnrmrngofy2
 endif
 if (oldnrmrngofy1 gt oldnrmrngofy2) and $
   (oldnrmrngofy1 gt nrmrngeofy) then begin
   thisnormrange=oldnrmrngofy1
 endif
 if (nrmrngeofy gt oldnrmrngofy2) and $
   (nrmrngeofy gt oldnrmrngofy1) then begin
   thisnormrange=nrmrngeofy
 endif
 if (oldbutt1 gt oldbutt2) and (oldbutt1 gt butt) then begin
  temp1=fltarr(oldbutt1)
  temp2=fltarr(oldbutt1)
  endpieces1=oldbutt1-oldbutt2
  endpieces2=oldbutt1-butt
  endpieces1=endpieces1/2
  endpieces2=endpieces2/2
  love=oldbutt1-1
  temp1(0:endpieces1)=0
  temp1(love-endpieces1:love)=0
  temp2(0:endpieces2)=0
  temp2(love-endpieces2:love)=0
  temp1(endpieces1:love-endpieces1)=oldnrmlzedft2
  temp2(endpieces2:love-endpieces2)=nrmalzedfit
  window,2,retain=2
  wset,2
  plot,oldstinky1,oldnrmlzedft1,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=oldxitchy1,thick=2.0,$
   xtickname=oldvpltrray1,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1+'!C'+$
    oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1+'!C'+$
    oldfllgssxttl2,$
   ytickname=oldypltrray1,pos=[0.1,0.2,0.9,0.9],yticks=oldyitchy1,$
   yminor=2
  oplot,oldstinky1,temp1
  oplot,oldstinky1,temp2
  decision=''
  print,''
  print, "save this as a postscript?  y/n"
  print,''
  read,decision
  if (decision ne 'y') then goto,donehere
  set_plot,'ps'
  gausspsfileA=gsspsfletmp+olddteinfo1+olddteinfo2+'.ps'
  device,filename=gausspsfileA,/helvetica,/bold,/inches,$
    xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
  plot,oldstinky1,oldnrmlzedft1,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=oldxitchy1,thick=2.0,$
   xtickname=oldvpltrray1,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1+'!C'+$
    oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1+'!C'+$
    oldfllgssxttl2,$
   ytickname=oldypltrray1,pos=[0,0.1,1,0.9],yticks=oldyitchy1,$
   yminor=2
  oplot,oldstinky1,temp1
  oplot,oldstinky1,temp2
  device,/close
  set_plot,'x'
 endif
 if (oldbutt2 gt oldbutt1) and (oldbutt2 gt butt) then begin
  temp1=fltarr(oldbutt2)
  temp2=fltarr(oldbutt2)
  endpieces1=oldbutt2-oldbutt1
  endpieces2=oldbutt2-butt
  endpieces1=endpieces1/2
  endpieces2=endpieces2/2
  love=oldbutt2-1
  temp1(0:endpieces1)=0
  temp1(love-endpieces1:love)=0
  temp2(0:endpieces2)=0
  temp2(love-endpieces2:love)=0
  temp1(endpieces1:love-endpieces1)=oldnrmlzedft1
  temp2(endpieces2:love-endpieces2)=nrmalzedfit
  window,2,retain=2
  wset,2
  plot,oldstinky2,oldnrmlzedft2,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=oldxitchy2,thick=2.0,$
   xtickname=oldvpltrray2,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1+'!C'+$
    oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1+'!C'+$
    oldfllgssxttl2,$
   ytickname=oldypltrray2,pos=[0.1,0.2,0.9,0.9],yticks=oldyitchy2,$
   yminor=2
  oplot,oldstinky2,temp1
  oplot,oldstinky2,temp2
  decision=''
  print,''
  print, "save this as a postscript?  y/n"
  print,''
  read,decision
  if (decision ne 'y') then goto,donehere
  set_plot,'ps'
  gausspsfileA=gsspsfletmp+olddteinfo1+olddteinfo2+'.ps'
  device,filename=gausspsfileA,/helvetica,/bold,/inches,$
    xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
  plot,oldstinky2,oldnrmlzedft2,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=oldxitchy2,thick=2.0,$
   xtickname=oldvpltrray2,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1+'!C'+$
    oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1+'!C'+$
    oldfllgssxttl2,$
   ytickname=oldypltrray2,pos=[0,0.1,1,0.9],yticks=oldyitchy2,$
   yminor=2
  oplot,oldstinky2,temp1
  oplot,oldstinky2,temp2
  device,/close
  set_plot,'x'
 endif
 if (butt gt oldbutt1) and (butt gt oldbutt2) then begin
  temp1=fltarr(butt)
  temp2=fltarr(butt)
  endpieces1=butt-oldbutt1
  endpieces2=butt-oldbutt2
  endpieces1=endpieces1/2
  endpieces2=endpieces2/2
  love=butt-1
  temp1(0:endpieces1)=0
  temp1(love-endpieces1:love)=0
  temp2(0:endpieces2)=0
  temp2(love-endpieces2:love)=0
  temp1(endpieces1:love-endpieces1)=oldnrmlzedft1
  temp2(endpieces2:love-endpieces2)=oldnrmlzedft2
  window,2,retain=2
  wset,2
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1+'!C'+$
    oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1+'!C'+$
    oldfllgssxttl2,$
   ytickname=yplotarray,pos=[0.1,0.2,0.9,0.9],yticks=yitchy,$
   yminor=2
  oplot,stinky,temp1
  oplot,stinky,temp2
  decision=''
  print,''
  print, "save this as a postscript?  y/n"
  print,''
  read,decision
  if (decision ne 'y') then goto,donehere
  set_plot,'ps'
  gausspsfileA=gsspsfletmp+olddteinfo1+olddteinfo2+'.ps'
  device,filename=gausspsfileA,/helvetica,/bold,/inches,$
    xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1+'!C'+$
    oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1+'!C'+$
    oldfllgssxttl2,$
   ytickname=yplotarray,pos=[0,0.1,1,0.9],yticks=yitchy,$
   yminor=2
  oplot,stinky,temp1
  oplot,stinky,temp2
  device,/close
  set_plot,'x'
 endif
 if (butt eq oldbutt2) and (butt eq oldbutt1) then begin
  window,2,retain=2
  wset,2
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1+'!C'+$
    oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1+'!C'+$
    oldfllgssxttl2,$
   ytickname=yplotarray,pos=[0.1,0.2,0.9,0.9],yticks=yitchy,$
   yminor=2
  oplot,oldstinky1,oldnrmlzedft1
  oplot,oldstinky2,oldnrmlzedft2
  decision=''
  print,''
  print, "save this as a postscript?  y/n"
  print,''
  read,decision
  if (decision ne 'y') then goto,donehere
  set_plot,'ps'
  gausspsfileA=gsspsfletmp+olddteinfo1+olddteinfo2+'.ps'
  device,filename=gausspsfileA,/helvetica,/bold,/inches,$
    xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
  plot,stinky,nrmalzedfit,yrange=[0,thisnormrange],$
   ystyle=1,xstyle=1,xticklen=1.0,xticks=xitchy,thick=2.0,$
   xtickname=vplotarray,xgridstyle=1,xminor=2,$
   title=gssplttitle+'!C'+oldgssdtetitl1+'!C'+$
    oldgssdtetitl2,$
   xtitle=fllgssxtitle+'!C'+oldfllgssxttl1+'!C'+$
    oldfllgssxttl2,$
   ytickname=yplotarray,pos=[0,0.1,1,0.9],yticks=yitchy,$
   yminor=2
  oplot,oldstinky1,oldnrmlzedft1
  oplot,oldstinky2,oldnrmlzedft2
  device,/close
  set_plot,'x'
 endif
endif

donehere:
decision=''
savegauss=''
print,''
print, "do you want to store the current gaussian over"
print, "either of the other two?  y/n"
print,''
read,savegauss
if (savegauss eq 'y') then begin
 wset,0
 plot,stinky,thefit,yrange=[0,rangeofy],ystyle=1,xstyle=1,$
  xticklen=1.0,xtitle=fllgssxtitle,xticks=xitchy,$
  xtickname=vplotarray,title=gssplttitle,thick=2.0,$
  xgridstyle=1,xminor=2,$
  pos=[0.1,0.1,0.9,0.9],yminor=2,ytitle=yplttitl
 print,''
 print, "here's the current gaussian fit by itself again."
 print,''
 print, "hit any key to continue"
 read,dummy
 print,''
 print, "here is stored gaussian fit # 1"
 print,''
 wset,1
 plot,oldstinky1,oldfit1,yrange=[0,oldrngofy1],ystyle=1,$
  xstyle=1,xticklen=1.0,xtitle=oldfllgssxttl1,xticks=oldxitchy1,$
  xtickname=oldvpltrray1,title=oldgssplttitl1,thick=2.0,$
  xgridstyle=1,xminor=2,pos=[0.1,0.1,0.9,0.9],$
  yminor=2,ytitle=yplttitl
 print, "hit any key to continue"
 read,dummy
 print,''
 print, "here is stored gaussian fit # 2"
 print,''
 wset,2
 plot,oldstinky2,oldfit2,yrange=[0,oldrngofy2],ystyle=1,$
  xstyle=1,xticklen=1.0,xtitle=oldfllgssxttl2,xticks=oldxitchy2,$
  xtickname=oldvpltrray2,title=oldgssplttitl2,thick=2.0,$
  xgridstyle=1,xminor=2,pos=[0.1,0.1,0.9,0.9],$
  yminor=2,ytitle=yplttitl
 print, "hit any key to continue"
 read,dummy
 decision=''
 print,''
 print, "which previously stored gaussian do you want to store"
 print, "the current gaussian over?"
 print,''
 print, "a.  store current fit over stored fit # 1"
 print, "b.  store current fit over stored fit # 2"
 print,''
 read,decision
 if (decision eq 'a') then begin
  oldstinky1=stinky & oldfit1=thefit & oldrngofy1=rangeofy & $
  oldfllgssxttl1=fllgssxtitle & oldxitchy1=xitchy & $
  oldvpltrray1=vplotarray & oldgssplttitl1=gssplttitle & $
  oldnrmlzedft1=nrmalzedfit & oldnrmrngofy1=nrmrngeofy & $
  oldbutt1=butt & oldgssdtetitl1=strdgssdtetitl & $
  olddteinfo1=strdteinfo & oldyitchy1=yitchy & $
  oldypltrray1=yplotarray
 endif else begin
  oldstinky2=stinky & oldfit2=thefit & oldrngofy2=rangeofy & $
  oldfllgssxttl2=fllgssxtitle & oldxitchy2=xitchy & $
  oldvpltrray2=vplotarray & oldgssplttitl2=gssplttitle & $
  oldnrmlzedft2=nrmalzedfit & oldnrmrngofy2=nrmrngeofy & $
  oldbutt2=butt & oldgssdtetitl2=strdgssdtetitl & $
  olddteinfo2=strdteinfo & oldyitchy2=yitchy & $
  oldypltrray2=yplotarray
 endelse
endif

goback:

return

end

;  this sub handles all plotting for the histograms, gaussian fits,
;  residues, title creation.

pro plothistograms,windtot,histtotal,rndedhisttotal,stinky,leftovers,$
    duallftovrs,vplotarray,yplotarray,xitchy,yitchy,plottype,$
    site,day1,day2,mnthval1,mnthval2,$
    month1,month2,yr,date1,date2,dat1,dat2,location,datatype,$
    fileext,size,increm,butt,lasttrigger,steppinstone,trigger1,$
    trigger2

common stored1,oldstinky1,oldfit1,oldrngofy1,oldfllgssxttl1,$
   oldxitchy1,oldyitchy1,oldypltrray1,oldvpltrray1,$
   oldgssplttitl1,oldnrmlzedft1,$
   oldnrmrngofy1,oldbutt1,oldgssdtetitl1,olddteinfo1
common stored2,oldstinky2,oldfit2,oldrngofy2,oldfllgssxttl2,$
   oldxitchy2,oldyitchy2,oldypltrray2,oldvpltrray2,$
   oldgssplttitl2,oldnrmlzedft2,$
   oldnrmrngofy2,oldbutt2,oldgssdtetitl2,olddteinfo2

if (lasttrigger eq '') then begin
 trigger1=''
 trigger2=''
 oldfllgssxttl1=''
 oldfllgssxttl2=''
 oldgssdtetitl1=''
 oldgssdtetitl2=''
 oldgssplttitl1=''
 oldgssplttitl2=''
 olddteinfo1=''
 olddteinfo2=''
endif

hstplttitle=''
gssplttitle=''
twogssplttitl=''
septwogsspltttl=''
twsepgssplttitl=''
gaussxtitle=''
fllgssxtitle=''
fllpgss1xttl=''
pcofgss2xttl=''
strdteinfo=''
strdgssdtetitl=''
hstgsssbtitl=''
hst2gsssbtitl=''
yplttitl=''
xhstplttitl=''
hstpsfletmp=''
gsspsfletmp=''
twgsspsfletmp=''
gsspsfile=''
twgsspsfile=''
twsepgsspsfle=''
hstpsfile=''
hstpsflegss=''
hstpsfleres=''
hstpsfletwgss=''
hstpsfletwgres=''

dummy='' & decision='' & savegauss=''

continueitall:

!p.font=0

;  creating all relevant plot titles and filenames

yplttitl='Number of Occurrences'

if (steppinstone eq 0) then begin
 if (mnthval1 eq mnthval2) then begin
  if (day1 eq day2) then begin
   hstplttitle='Distribution of '+plottype+$
    ' Winds in the Upper Thermosphere!C'+site+', '+month1+' '+day1+$
    ', 19'+yr
   gssplttitle='Gaussian Fit to '+plottype+$
    ' Wind Distribution for!C'+site+', '+month1+' '+day1+', 19'+yr
   twogssplttitl='Two-Gaussian Fit to '+plottype+$
    ' Wind Distribution for!C'+site+', '+month1+' '+day1+', 19'+yr
   twsepgssplttitl='Both Gaussians from two-Gaussian Fit to '+plottype+$
    ' Wind Distribution for!C'+site+', '+month1+' '+day1+', 19'+yr
   gaussxtitle='!C'+'Peak of the Gaussian for '+month1+' '+day1+', 19'+yr
   strdgssdtetitl=site+', '+month1+' '+day1+', 19'+yr
   strdteinfo=yr+date1
;   hstpsfletmp='/usr/users/mpkryn/windanalysis/test/psfilestest/'+$
;    'hist'+fileext+yr+date1
;   gsspsfletmp='/usr/users/mpkryn/windanalysis/test/psfilestest/'+$
;    'gauss'+fileext+yr+date1
;   twgsspsfletmp='/usr/users/mpkryn/windanalysis/test/psfilestest/'+$
;    'twogauss'+fileext+yr+date1
   hstpsfletmp='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+$
    datatype+'/psfiles/'+'hist'+fileext+yr+date1
  gsspsfletmp='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+$
    datatype+'/psfiles/'+'gauss'+fileext+yr+date1
   twgsspsfletmp='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+$
    datatype+'/psfiles/'+'twogauss'+fileext+yr+date1
  endif else begin
   hstplttitle='Distribution of '+plottype+$
    ' Winds in the Upper Thermosphere!C'+site+', '+month1+' '+day1+$
    ' to '+day2+', 19'+yr
   gssplttitle='Gaussian Fit to '+plottype+$
    ' Wind Distribution for!C'+site+', '+month1+' '+day1+' to '+$
    day2+', 19'+yr
   twogssplttitl='Two-Gaussian Fit to '+plottype+$
    ' Wind Distribution for!C'+site+', '+month1+' '+day1+' to '+$
    day2+', 19'+yr
   twsepgssplttitl='Both Gaussians from two-Gaussian Fit to '+plottype+$
    ' Wind Distribution for!C'+site+', '+month1+' '+day1+' to '+$
    day2+', 19'+yr
   gaussxtitle='!C'+'Peak of the Gaussian for '+month1+' '+day1+$
    ' to '+day2+', 19'+yr
   strdgssdtetitl=site+', '+month1+' '+day1+$
    ' to '+day2+', 19'+yr
   strdteinfo=yr+date1+date2
;   hstpsfletmp='/usr/users/mpkryn/windanalysis/test/psfilestest/'+$
;    'hist'+fileext+yr+date1+date2
;   gsspsfletmp='/usr/users/mpkryn/windanalysis/test/psfilestest/'+$
;    'gauss'+fileext+yr+date1+date2
;   twgsspsfletmp='/usr/users/mpkryn/windanalysis/test/psfilestest/'+$
;    'twogauss'+fileext+yr+date1+date2
   hstpsfletmp='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+$
    datatype+'/psfiles/'+'hist'+fileext+yr+date1+date2
   gsspsfletmp='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+$
    datatype+'/psfiles/'+'gauss'+fileext+yr+date1+date2
   twgsspsfletmp='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+$
    datatype+'/psfiles/'+'twogauss'+fileext+yr+date1+date2
  endelse
 endif else begin
   hstplttitle='Distribution of '+plottype+$
    ' Winds in the Upper Thermosphere!C'+site+', '+month1+' '+day1+$
    ' to '+month2+' '+day2+', 19'+yr
   gssplttitle='Gaussian Fit to '+plottype+$
    ' Wind Distribution for!C'+site+', '+month1+' '+day1+' to '+$
    month2+' '+day2+', 19'+yr
   twogssplttitl='Two-Gaussian Fit to '+plottype+$
    ' Wind Distribution for!C'+site+', '+month1+' '+day1+' to '+$
    month2+' '+day2+', 19'+yr
   twsepgssplttitl='Both Gaussians from two-Gaussian Fit to '+plottype+$
    ' Wind Distribution for!C'+site+', '+month1+' '+day1+' to '+$
    month2+' '+day2+', 19'+yr
   gaussxtitle='!C'+'Peak of the Gaussian for '+month1+' '+day1+' to '+$
    month2+' '+day2+', 19'+yr
   strdgssdtetitl=site+', '+month1+' '+day1+' to '+$
    month2+' '+day2+', 19'+yr
   strdteinfo=yr+date1+date2
;   hstpsfletmp='/usr/users/mpkryn/windanalysis/test/psfilestest/'+$
;    'hist'+fileext+yr+date1+date2
;   gsspsfletmp='/usr/users/mpkryn/windanalysis/test/psfilestest/'+$
;    'gauss'+fileext+yr+date1+date2
;   twgsspsfletmp='/usr/users/mpkryn/windanalysis/test/psfilestest/'+$
;    'twogauss'+fileext+yr+date1+date2
   hstpsfletmp='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+$
    datatype+'/psfiles/'+'hist'+fileext+yr+date1+date2
   gsspsfletmp='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+$
    datatype+'/psfiles/'+'gauss'+fileext+yr+date1+date2
   twgsspsfletmp='/usr/users/mpkryn/windanalysis/'+location+'/'+yr+$
    datatype+'/psfiles/'+'twogauss'+fileext+yr+date1+date2
 endelse
endif
if (steppinstone eq 1) then begin
 if (yr eq prevyr) then begin
  if (mnthval1 eq mnthval2) then begin
   if (day1 eq day2) then begin
    hstplttitle=hstplttitle+',!C'+month1+' '+day1
    gssplttitle=gssplttitle+',!C'+month1+' '+day1
    twogssplttitl=twogssplttitl+',!C'+month1+' '+day1
    twsepgssplttitl=twsepgssplttitl+',!C'+month1+' '+day1
    gaussxtitle=gaussxtitle+',!C'+month1+' '+day1
    strdgssdtetitl=strdgssdtetitl+',!C'+month1+' '+day1
    strdteinfo=strdteinfo+date1
    hstpsfletmp=hstpsfletmp+date1
    gsspsfletmp=gsspsfletmp+date1
    twgsspsfletmp=twgsspsfletmp+date1
   endif else begin
    hstplttitle=hstplttitle+',!C'+month1+' '+day1+' to '+day2
    gssplttitle=gssplttitle+',!C'+month1+' '+day1+' to '+day2
    twogssplttitl=twogssplttitl+',!C'+month1+' '+day1+' to '+day2
    twsepgssplttitl=twsepgssplttitl+',!C'+month1+' '+day1+' to '+day2
    gaussxtitle=gaussxtitle+',!C'+month1+' '+day1+' to '+day2
    strdgssdtetitl=strdgssdtetitl+',!C'+month1+' '+day1+$
     ' to '+day2
    strdteinfo=strdteinfo+date1+date2
    hstpsfletmp=hstpsfletmp+date1+date2
    gsspsfletmp=gsspsfletmp+date1+date2
    twgsspsfletmp=twgsspsfletmp+date1+date2
   endelse
  endif else begin
    hstplttitle=hstplttitle+',!C'+month1+' '+day1+' to '+$
     month2+' '+day2
    gssplttitle=gssplttitle+',!C'+month1+' '+day1+' to '+$
     month2+' '+day2
    twogssplttitl=twogssplttitl+',!C'+month1+' '+day1+' to '+$
     month2+' '+day2
    twsepgssplttitl=twsepgssplttitl+',!C'+month1+' '+day1+' to '+$
     month2+' '+day2
    gaussxtitle=gaussxtitle+',!C'+month1+' '+day1+' to '+$
     month2+' '+day2
    strdgssdtetitl=strdgssdtetitl+',!C'+month1+' '+day1+$
     ' to '+month2+' '+day2
    strdteinfo=strdteinfo+date1+date2
    hstpsfletmp=hstpsfletmp+date1+date2
    gsspsfletmp=gsspsfletmp+date1+date2
    twgsspsfletmp=twgsspsfletmp+date1+date2
  endelse
 endif else begin
  if (mnthval1 eq mnthval2) then begin
   if (day1 eq day2) then begin
    hstplttitle=hstplttitle+',!C'+month1+' '+day1+', 19'+yr
    gssplttitle=gssplttitle+',!C'+month1+' '+day1+', 19'+yr
    twogssplttitl=twogssplttitl+',!C'+month1+' '+day1+', 19'+yr
    twsepgssplttitl=twsepgssplttitl+',!C'+month1+' '+day1+', 19'+yr
    gaussxtitle=gaussxtitle+',!C'+month1+' '+day1+', 19'+yr
    strdgssdtetitl=strdgssdtetitl+',!C'+month1+' '+$
     day1+', 19'+yr
    strdteinfo=strdteinfo+yr+date1
    hstpsfletmp=hstpsfletmp+yr+date1
    gsspsfletmp=gsspsfletmp+yr+date1
    twgsspsfletmp=twgsspsfletmp+yr+date1
   endif else begin
    hstplttitle=hstplttitle+',!C'+month1+' '+day1+' to '+day2+$
     ', 19'+yr
    gssplttitle=gssplttitle+',!C'+month1+' '+day1+' to '+day2+$
     ', 19'+yr
    twogssplttitl=twogssplttitl+',!C'+month1+' '+day1+' to '+$
     day2+', 19'+yr
    twsepgssplttitl=twsepgssplttitl+',!C'+month1+' '+day1+' to '+$
     day2+', 19'+yr
    gaussxtitle=gaussxtitle+',!C'+month1+' '+day1+' to '+day2+$
     ', 19'+yr
    strdgssdtetitl=strdgssdtetitl+',!C'+month1+' '+day1+$
     ' to '+day2+', 19'+yr
    strdteinfo=strdteinfo+yr+date1+date2
    hstpsfletmp=hstpsfletmp+yr+date1+date2
    gsspsfletmp=gsspsfletmp+yr+date1+date2
    twgsspsfletmp=twgsspsfletmp+yr+date1+date2
   endelse
  endif else begin
    hstplttitle=hstplttitle+',!C'+month1+' '+day1+' to '+$
     month2+' '+day2+', 19'+yr
    gssplttitle=gssplttitle+',!C'+month1+' '+day1+' to '+$
     month2+' '+day2+', 19'+yr
    twogssplttitl=twogssplttitl+',!C'+month1+' '+day1+' to '+$
     month2+' '+day2+', 19'+yr
    twsepgssplttitl=twsepgssplttitl+',!C'+month1+' '+day1+' to '+$
     month2+' '+day2+', 19'+yr
    gaussxtitle=gaussxtitle+',!C'+month1+' '+day1+' to '+$
     month2+' '+day2+', 19'+yr
    strdgssdtetitl=strdgssdtetitl+',!C'+month1+' '+day1+$
     ' to '+month2+' '+day2+', 19'+yr
    strdteinfo=strdteinfo+yr+date1+date2
    hstpsfletmp=hstpsfletmp+yr+date1+date2
    gsspsfletmp=gsspsfletmp+yr+date1+date2
    twgsspsfletmp=twgsspsfletmp+yr+date1+date2
  endelse
 endelse
endif

xhstplttitl='!C'+'Vertical Velocity  m/s  ;  Bin size is 5 m/s!C'+$
   'Total # of measurements is'+strcompress(size)
septwogsspltttl=twogssplttitl+',!C'+'and each Gaussian separately'

gsspsfile=gsspsfletmp+'.ps'
twgsspsfile=twgsspsfletmp+'.ps'
twsepgsspsfle=twgsspsfletmp+'separate.ps'
hstpsfile=hstpsfletmp+'.ps'
hstpsflegss=hstpsfletmp+'gauss.ps'
hstpsfleres=hstpsfletmp+'resid.ps'
hstpsfletwgss=hstpsfletmp+'twogauss.ps'
hstpsfletwgres=hstpsfletmp+'twgresid.ps'

rangeofy=max(histtotal)+10
nrmrngeofy=float(rangeofy)/float(size)

;  plot the histogram

window,0,retain=2
wset,0
plot,stinky,rndedhisttotal,yrange=[0,rangeofy],psym=10,$
  ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
  xtitle=xhstplttitl,xticks=xitchy,xtickname=vplotarray,$
  title=hstplttitle,thick=2.0,xminor=2,yticklen=1.0,$
  xgridstyle=1,ygridstyle=1,pos=[0.1,0.15,0.9,0.9]
print,''
print, "hit any key to continue"
read,dummy
print,''
print,''
print, "a gaussian is being fit to this histogram...please stand by."
print,''

;  call to Mark's procedure for getting the gaussian fit, the
;  peakposition and the width
;  call_procedure,'gauss',stinky,histtotal,pkps,wdth,hght,thefit
;  pkps is the peakposition of the fit in array location units, we
;  need to convert that to meters/sec.  butt is total # of elements
;  of the array, so need to have a peakpos that is centered around
;  "zero m/s" velocity.  wdth needs to be in m/s as well.  wdth is
;  actually the half-width at 1/e of the fit.

;  no longer using Mark's fitting routine.  will use the IDL library
;  fitting routines, which uses chi-squared testing of fit.
;  aa is the array that holds our guessed-at parameters for fitting
;  a gaussian.
aa=fltarr(3)
aa=[1.,1.,1.]
thefit=fitthegauss(stinky,histtotal,aa)
truepeak=(aa(1) - ((butt-1)/2))*5
truewidth=5*(2*aa(2))
nrmalzedfit=thefit/size
if (truepeak lt 0) then begin
 strpeak=strmid(strcompress(truepeak,/rem),0,5)
endif else begin
  strpeak=strmid(strcompress(truepeak,/rem),0,4)
endelse
if (truewidth lt 0) then begin
 strwidth=strmid(strcompress(truewidth,/rem),0,5)
endif else begin
 strwidth=strmid(strcompress(truewidth,/rem),0,4)
endelse
; deviationtemp=stdev(thefit,meany)
; deviationhist=stdev(histtotal,jerk)

fllgssxtitle=gaussxtitle+' occurred at '+strpeak+$
    ' m/s.  The width is '+strwidth+' m/s.!C'+$
    'Total # of measurements is'+strcompress(size)
hstgsssbtitl='!C'+'Peak of the Gaussian occurred at '+strpeak+$
    ' m/s.  The width is '+strwidth+' m/s.'

window,1,retain=2
wset,1
plot,stinky,rndedhisttotal,yrange=[0,rangeofy],psym=10,$
  ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
  xtitle=xhstplttitl,xticks=xitchy,subtitle=hstgsssbtitl,$
  xtickname=vplotarray,thick=2.0,xgridstyle=1,xminor=2,$
  title=hstplttitle+'!Cwith Gaussian Fit',yticklen=1.0,$
  ygridstyle=1,pos=[0.1,0.2,0.9,0.85]
oplot,stinky,thefit
print,''
print, "hit any key to continue"
read,dummy

print,''
print,''
print, "the residue of the gaussian from the histogram"
print, "is being calculated...please stand by."
print,''
leftovers=histtotal-thefit
rndedlftovrs=round(leftovers)
gdeatin=fix(max(leftovers)+10)
bdeatin=fix(min(leftovers)-10)
window,2,retain=2
wset,2
plot,stinky,rndedlftovrs,yrange=[bdeatin,gdeatin],$
 psym=10,ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
 xtitle=xhstplttitl,xticks=xitchy,xtickname=vplotarray,$
 title=hstplttitle+'!CHistory minus Gaussian Fit',thick=2.0,$
 xgridstyle=1,xminor=2,yticklen=1.0,ygridstyle=1,$
 pos=[0.1,0.2,0.9,0.85]
print,''
print, "hit any key to continue"
read,dummy

print,''
print,''
print, "here's the gaussian fit by itself."
print,''
window,3,retain=2
wset,3
plot,stinky,thefit,yrange=[0,rangeofy],ystyle=1,xstyle=1,$
 xticklen=1.0,xtitle=fllgssxtitle,xticks=xitchy,$
 xtickname=vplotarray,title=gssplttitle,$
 thick=2.0,pos=[0.1,0.15,0.9,0.9],yminor=2,ytitle=yplttitl,$
 xgridstyle=1,xminor=2
print,''
print, "hit any key to continue"
read,dummy

print,''
print, "two gaussians (added together) are being fit to the"
print, "histogram...please stand by."
print,''
; aaa is the array that holds our guessed-at parameters for fitting
; the two gaussians.
aaa=fltarr(6)
aaa=[1.,1.,1.,1.,1.,1.]
twofit=fittwogauss(stinky,histtotal,aaa,pf1,pf2)
peakofpf1 = (aaa(1) - ((butt-1)/2))*5
widthofpf1 = 5*(2*aaa(2))
peakofpf2 = (aaa(4) - ((butt-1)/2))*5
widthofpf2 = 5*(2*aaa(5))
nrmlzedtwoft=twofit/size
pcnrmlzdtwoft1=pf1/size
pcnrmlzdtwoft2=pf2/size
if (peakofpf1 lt 0) then begin
 strpeakpf1=strmid(strcompress(peakofpf1,/rem),0,5)
endif else begin
 strpeakpf1=strmid(strcompress(peakofpf1,/rem),0,4)
endelse
strwidthpf1=strmid(strcompress(widthofpf1,/rem),0,4)
if (peakofpf2 lt 0) then begin
 strpeakpf2=strmid(strcompress(peakofpf2,/rem),0,5)
endif else begin
 strpeakpf2=strmid(strcompress(peakofpf2,/rem),0,4)
endelse
if (widthofpf1 lt 0) then begin
 strwidthpf1=strmid(strcompress(widthofpf1,/rem),0,5)
endif else begin
 strwidthpf1=strmid(strcompress(widthofpf1,/rem),0,4)
endelse
if (widthofpf2 lt 0) then begin
 strwidthpf2=strmid(strcompress(widthofpf2,/rem),0,5)
endif else begin
 strwidthpf2=strmid(strcompress(widthofpf2,/rem),0,4)
endelse

fllpgss1xttl='!C'+'Peak of first Gaussian occurred at '+strpeakpf1+$
   ' m/s.  The width is '+strwidthpf1+' m/s.!C'
pcofgss2xttl='Peak of second Gaussian occurred at '+strpeakpf2+$
   ' m/s.  The width is '+strwidthpf2+' m/s.!C'+$
   'Total # of measurements is'+strcompress(size)
hst2gsssbtitl='!C'+'Peak of first Gaussian occurred at '+strpeakpf1+$
   ' m/s.  The width is '+strwidthpf1+' m/s.!C'+$
   'Peak of second Gaussian occurred at '+strpeakpf2+$
   ' m/s.  The width is '+strwidthpf2+' m/s.'

wset,0
plot,stinky,rndedhisttotal,yrange=[0,rangeofy],psym=10,$
  ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
  xtitle=xhstplttitl,xticks=xitchy,subtitle=hst2gsssbtitl,$
  xtickname=vplotarray,thick=2.0,xgridstyle=1,xminor=2,$
  title=hstplttitle+'!Cwith Two-Gaussian Fit',$
  yticklen=1.0,ygridstyle=1,pos=[0.1,0.2,0.9,0.85]
oplot,stinky,twofit
print,''
print, "hit any key to continue"
read,dummy
print,''

print,''
print, "here's the two-gaussian fit, and each of the two gaussians"
print, "which make up the fit."
print,''
wset,1
plot,stinky,twofit,yrange=[0,rangeofy],ystyle=1,xstyle=1,$
 xticklen=1.0,xtitle=fllpgss1xttl+pcofgss2xttl,xticks=xitchy,$
 xtickname=vplotarray,thick=2.0,pos=[0.1,0.2,0.9,0.85],yminor=2,$
 ytitle=yplttitl,xgridstyle=1,xminor=2,title=septwogsspltttl
oplot,stinky,pf1
oplot,stinky,pf2
print,''
print, "hit any key to continue"
read,dummy
print,''
print,''
print, "here's the two gaussians, by themselves."
print,''
wset,2
plot,stinky,pf1,yrange=[0,rangeofy],ystyle=1,xstyle=1,$
 xticklen=1.0,xtitle=fllpgss1xttl+pcofgss2xttl,xticks=xitchy,$
 xtickname=vplotarray,thick=2.0,pos=[0.1,0.2,0.9,0.85],yminor=2,$
 ytitle=yplttitl,xgridstyle=1,xminor=2,title=twsepgssplttitl
oplot,stinky,pf2
print,''
print, "hit any key to continue"
read,dummy
print,''

print,''
print, "the residue of the two-gaussian from the histogram"
print, "is being calculated...please stand by."
print,''
duallftovrs=histtotal-twofit
rndduallftovrs=round(duallftovrs)
damgdeatin=fix(max(duallftovrs)+10)
dambdeatin=fix(min(duallftovrs)-10)
wset,3
plot,stinky,rndduallftovrs,yrange=[dambdeatin,damgdeatin],$
 psym=10,ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
 xtitle=xhstplttitl,xticks=xitchy,xtickname=vplotarray,$
 title=hstplttitle+'!CHistory minus Two-Gaussian Fit',thick=2.0,$
 xgridstyle=1,xminor=2,yticklen=1.0,ygridstyle=1,$
 pos=[0.1,0.15,0.9,0.85]
print,''
print, "hit any key to continue"
read,dummy
print,''

print,''
print, "what is your wish?"
print,''
decision=''
print, "a.  continue adding data to this particular histogram, or"
print,''
print, "b.  treat this histogram as completed, begin postscripting"
print, "    these plots, if desired, and store the gaussian"
print, "    distribution for further reference, particularly for"
print, "    comparison to other stored gaussians"
print,''
read,decision
if (decision eq 'a') then goto, continuehisto
if (decision ne 'a') then goto, dosomesavin

continuehisto:
 steppinstone=1
  prevmonth1=month1 & prevday1=day1 & prevmonth2=month2 & $
  prevday2=day2 & prevyr=yr & prevmnthval1=mnthval1 & $
  prevmnthval2=mnthval2 & prevdat1=dat1 & prevdat2=dat2
 call_procedure,'rangeofdays',date1,date2,yr,steppinstone
 call_procedure,'defineimportant',date,dat1,dat2,date1,date2,month1,$
   month2,day1,day2,mnthval1,mnthval2
 call_procedure,'compiledata',windtot,date,date1,date2,dat1,dat2,yr,$
   size,increm,location,datatype,fileext
 call_procedure,'findscaling',vplotarray,yplotarray,histtotal,$
   windtot,xitchy,yitchy,butt,bigbin
 call_procedure,'starthisting',windtot,histtotal,rndedhisttotal,$
   leftovers,duallftovrs,stinky,butt,bigbin
goto,continueitall

dosomesavin:

window,0,retain=2
wset,0
plot,stinky,rndedhisttotal,yrange=[0,rangeofy],psym=10,$
  ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
  xtitle=xhstplttitl,xticks=xitchy,xtickname=vplotarray,$
  title=hstplttitle,thick=2.0,xgridstyle=1,xminor=2,$
  yticklen=1.0,ygridstyle=1,pos=[0.1,0.15,0.9,0.9]
print,''
decision=''
print, "here's the histogram again.  save it as postscript?  y/n"
print,''
read,decision
if (decision ne 'y') then goto, next
set_plot,'ps'
device,filename=hstpsfile,/helvetica,/bold,/inches,xoffset=1.125,$
  xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
 plot,stinky,rndedhisttotal,yrange=[0,rangeofy],psym=10,$
  ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
  xtitle=xhstplttitl,xticks=xitchy,xtickname=vplotarray,$
  title=hstplttitle,thick=2.0,yticklen=1.0,xminor=2,$
  ygridstyle=1,pos=[0,0.1,1,0.9],xgridstyle=1
device,/close
set_plot,'x'
next:

plot,stinky,rndedhisttotal,yrange=[0,rangeofy],psym=10,$
  ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
  xtitle=xhstplttitl,xticks=xitchy,subtitle=hstgsssbtitl,$
  xtickname=vplotarray,thick=2.0,xgridstyle=1,xminor=2,$
  title=hstplttitle+'!Cwith Gaussian Fit',yticklen=1.0,$
  ygridstyle=1,pos=[0.1,0.2,0.9,0.85]
oplot,stinky,thefit
decision=''
print,''
print, "here's the histogram with gaussian fit again.  postscript?  y/n"
print,''
read,decision
if (decision ne 'y') then goto, next2
set_plot,'ps'
device,filename=hstpsflegss,/helvetica,/bold,/inches,xoffset=1.125,$
  xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
 plot,stinky,rndedhisttotal,yrange=[0,rangeofy],psym=10,$
  ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
  xtitle=xhstplttitl,xticks=xitchy,subtitle=hstgsssbtitl,$
  xtickname=vplotarray,thick=2.0,xgridstyle=1,xminor=2,$
  title=hstplttitle+'!Cwith Gaussian Fit',pos=[0,0.1,1,0.9],$
  yticklen=1.0,ygridstyle=1
 oplot,stinky,thefit
device,/close
set_plot,'x'
next2:

plot,stinky,rndedlftovrs,yrange=[bdeatin,gdeatin],$
 psym=10,ystyle=10,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
 xtitle=xhstplttitl,xticks=xitchy,xtickname=vplotarray,$
 title=hstplttitle+'!CHistory minus Gaussian',thick=2.0,$
 xgridstyle=1,ygridstyle=1,xminor=2,yticklen=1.0,$
 pos=[0.1,0.2,0.9,0.85]
decision=''
print,''
print, "here's the residuals plot again.  postscript?  y/n"
print,''
read,decision
if (decision ne 'y') then goto, next3
set_plot,'ps'
device,filename=hstpsfleres,/helvetica,/bold,/inches,$
   xoffset=1.125,xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
 plot,stinky,rndedlftovrs,yrange=[bdeatin,gdeatin],$
  psym=10,ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
  xtitle=xhstplttitl,xticks=xitchy,xtickname=vplotarray,$
  title=hstplttitle+'!CHistory minus Gaussian',thick=2.0,$
  xgridstyle=1,ygridstyle=1,xminor=2,yticklen=1.0,$
  pos=[0,0.1,1,0.9]
device,/close
set_plot,'x'
next3:

plot,stinky,thefit,yrange=[0,rangeofy],ystyle=1,xstyle=1,$
 xticklen=1.0,xtitle=fllgssxtitle,xticks=xitchy,$
 xtickname=vplotarray,title=gssplttitle,$
 thick=2.0,pos=[0.1,0.2,0.9,0.9],yminor=2,ytitle=yplttitl,$
 xgridstyle=1,xminor=2
decision=''
print,''
print, "here's the gaussian by itself again.  postscript?  y/n"
print,''
read,decision
if (decision ne 'y') then goto, next4
set_plot,'ps'
device,filename=gsspsfile,/helvetica,/bold,/inches,xoffset=1.125,$
  xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
plot,stinky,thefit,yrange=[0,rangeofy],ystyle=1,xstyle=1,$
 xticklen=1.0,xtitle=fllgssxtitle,xticks=xitchy,$
 xtickname=vplotarray,title=gssplttitle,$
 thick=2.0,pos=[0,0.1,1,0.9],yminor=2,ytitle=yplttitl,$
 xgridstyle=1,xminor=2
device,/close
set_plot,'x'
next4:

plot,stinky,rndedhisttotal,yrange=[0,rangeofy],psym=10,$
  ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
  xtitle=xhstplttitl,xticks=xitchy,subtitle=hst2gsssbtitl,$
  xtickname=vplotarray,thick=2.0,xgridstyle=1,xminor=2,$
  title=hstplttitle+'!Cwith Two-Gaussian Fit',$
  yticklen=1.0,ygridstyle=1,pos=[0.1,0.2,0.9,0.85]
oplot,stinky,twofit
decision=''
print,''
print, "here's the histogram with the two-gaussian fit again."
print, "postscript?  y/n"
print,''
read,decision
if (decision ne 'y') then goto, next5
set_plot,'ps'
device,filename=hstpsfletwgss,/helvetica,/bold,/inches,xoffset=1.125,$
  xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
plot,stinky,rndedhisttotal,yrange=[0,rangeofy],psym=10,$
  ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
  xtitle=xhstplttitl,xticks=xitchy,subtitle=hst2gsssbtitl,$
  xtickname=vplotarray,thick=2.0,xgridstyle=1,xminor=2,$
  title=hstplttitle+'!Cwith Two-Gaussian Fit',$
  yticklen=1.0,ygridstyle=1,pos=[0,0.1,1,0.9]
oplot,stinky,twofit
device,/close
set_plot,'x'
next5:

plot,stinky,twofit,yrange=[0,rangeofy],ystyle=1,xstyle=1,$
 xticklen=1.0,xtitle=fllpgss1xttl+pcofgss2xttl,xticks=xitchy,$
 xtickname=vplotarray,thick=2.0,pos=[0.1,0.2,0.9,0.85],yminor=2,$
 ytitle=yplttitl,xgridstyle=1,xminor=2,title=septwogsspltttl
oplot,stinky,pf1
oplot,stinky,pf2
decision=''
print,''
print, "here's the two-gaussian fit, and its components again."
print, "postscript?  y/n"
print,''
read,decision
if (decision ne 'y') then goto, next6
set_plot,'ps'
device,filename=twgsspsfile,/helvetica,/bold,/inches,xoffset=1.125,$
  xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
plot,stinky,twofit,yrange=[0,rangeofy],ystyle=1,xstyle=1,$
 xticklen=1.0,xtitle=fllpgss1xttl+pcofgss2xttl,xticks=xitchy,$
 xtickname=vplotarray,thick=2.0,pos=[0,0.1,1,0.9],yminor=2,$
 ytitle=yplttitl,xgridstyle=1,xminor=2,title=septwogsspltttl
oplot,stinky,pf1
oplot,stinky,pf2
device,/close
set_plot,'x'
next6:

plot,stinky,pf1,yrange=[0,rangeofy],ystyle=1,xstyle=1,$
 xticklen=1.0,xtitle=fllpgss1xttl+pcofgss2xttl,xticks=xitchy,$
 xtickname=vplotarray,thick=2.0,pos=[0.1,0.2,0.9,0.85],yminor=2,$
 ytitle=yplttitl,xgridstyle=1,xminor=2,title=twsepgssplttitl
oplot,stinky,pf2
decision=''
print,''
print, "here's the two components again, by themselves."
print, "postscript?  y/n"
print,''
read,decision
if (decision ne 'y') then goto,next7 
set_plot,'ps'
device,filename=twsepgsspsfle,/helvetica,/bold,/inches,xoffset=1.125,$
  xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
plot,stinky,pf1,yrange=[0,rangeofy],ystyle=1,xstyle=1,$
 xticklen=1.0,xtitle=fllpgss1xttl+pcofgss2xttl,xticks=xitchy,$
 xtickname=vplotarray,thick=2.0,pos=[0,0.1,1,0.9],yminor=2,$
 ytitle=yplttitl,xgridstyle=1,xminor=2,title=twsepgssplttitl
oplot,stinky,pf2
device,/close
set_plot,'x'
next7:

plot,stinky,rndduallftovrs,yrange=[dambdeatin,damgdeatin],$
 psym=10,ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
 xtitle=xhstplttitl,xticks=xitchy,xtickname=vplotarray,$
 title=hstplttitle+'!CHistory minus Two-Gaussian Fit',thick=2.0,$
 xgridstyle=1,xminor=2,yticklen=1.0,ygridstyle=1,$
 pos=[0.1,0.2,0.9,0.85]
decision=''
print,''
print, "here's the residuals from the two-gaussian fit again."
print, "postscript?  y/n"
print,''
read,decision
if (decision ne 'y') then goto,next8
set_plot,'ps'
device,filename=hstpsfletwgres,/helvetica,/bold,/inches,xoffset=1.125,$
  xsize=6.25,yoffset=1.25,ysize=8.5,font_size=12
plot,stinky,rndduallftovrs,yrange=[dambdeatin,damgdeatin],$
 psym=10,ystyle=1,ytitle=yplttitl,xstyle=1,xticklen=1.0,$
 xtitle=xhstplttitl,xticks=xitchy,xtickname=vplotarray,$
 title=hstplttitle+'!CHistory minus Two-Gaussian Fit',thick=2.0,$
 xgridstyle=1,xminor=2,yticklen=1.0,ygridstyle=1,$
 pos=[0,0.1,1,0.9]
device,/close
set_plot,'x'
next8:

if (trigger1 ne 'y') then goto,storefirstone

call_procedure,'pltoldhstofits',stinky,thefit,rangeofy,fllgssxtitle,$
  xitchy,vplotarray,gssplttitle,nrmalzedfit,nrmrngeofy,butt,$
  strdgssdtetitl,strdteinfo,yitchy,yplotarray,trigger1,trigger2,$
  gsspsfiletmp,yplttitl

if (trigger1 eq 'y') and (trigger2 ne 'y') then begin
 trigger2='y'
 oldstinky2=oldstinky1 & oldfit2=oldfit1 & oldrngofy2=oldrngofy1 & $
 oldfllgssxttl2=oldfllgssxttl1 & oldxitchy2=oldxitchy1 & $
 oldvpltrray2=oldvpltrray1 & oldgssplttitl2=oldgssplttitl1 & $
 oldnrmlzedft2=oldnrmlzedft1 & oldnrmrngofy2=oldnrmrngofy1 & $
 oldbutt2=oldbutt1 & oldgssdtetitl2=oldgssdtetitl1 & $
 olddteinfo2=olddteinfo1 & oldyitchy2=oldyitchy1 & $
 oldypltrray2=oldypltrray1
 oldstinky1=stinky & oldfit1=thefit & oldrngofy1=rangeofy & $
 oldfllgssxttl1=fllgssxtitle & oldxitchy1=xitchy & $
 oldvpltrray1=vplotarray & oldgssplttitl1=gssplttitle & $
 oldnrmlzedft1=nrmalzedfit & oldnrmrngofy1=nrmrngeofy & $
 oldbutt1=butt & oldgssdtetitl1=strdgssdtetitl & $
 olddteinfo1=strdteinfo & oldyitchy1=yitchy & $
 oldypltrray1=yplotarray
endif
goto,alldone
storefirstone:
 trigger1='y'
 oldstinky1=stinky & oldfit1=thefit & oldrngofy1=rangeofy & $
 oldfllgssxttl1=fllgssxtitle & oldxitchy1=xitchy & $
 oldvpltrray1=vplotarray & oldgssplttitl1=gssplttitle & $
 oldnrmlzedft1=nrmalzedfit & oldnrmrngofy1=nrmrngeofy & $
 oldbutt1=butt & oldgssdtetitl1=strdgssdtetitl & $
 olddteinfo1=strdteinfo & oldyitchy1=yitchy & $
 oldypltrray1=yplotarray

alldone:
steppinstone=0
lasttrigger='boo'

return

end


;   the main program.  "i..feel..something..."
;   "and i say unto thee..."

what=''
lasttrigger=''
trigger1=''
trigger2=''
trig1=''
trig2=''
trig3=''

print,''
print,''
print,''
print,''
print,''
print, "This program will generate time series graphs,"
print, "histogram plots, temperature plots, and intensity"
print, "plots of Fabry-Perot data...for no mankind..."
print,''
print,''

start:

print,''
print,''
print, "Pick your form of analysis."
print,''
print,''
print, "a.  Time Series"
print, "b.  Histograms"
print, "c.  Temperatures"
print, "d.  Intensitys"
print, "e.  Quit"
print,''
read, what
print,''
print,''
if (what ne 'a') and (what ne 'b') and (what ne 'c') $
 and (what ne 'd') then goto,stop

if (what eq 'a') then call_procedure,'starttimeseries',trig1,trig2,trig3
if (what eq 'a') then goto,start
if (what eq 'b') then call_procedure,'starthistogram',lasttrigger,$
                                      trigger1,trigger2
if (what eq 'b') then goto,start

; if (what eq 'c') then goto,starttemp
; if (what eq 'd') then goto,startint

stop:

print,''
print, "see ya'.  have fun."

end





