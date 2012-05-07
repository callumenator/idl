;show w96 potentials for specific IMF conditions
;***********************************************************************
PRO CIRCLE,RADIUS,LS
IF N_ELEMENTS(THETA) EQ 0 THEN THETA=FINDGEN(181)*!PI/90.
IF(N_PARAMS() EQ 1)THEN LS=0
OPLOT,REPLICATE(Radius,181),Theta,/POLAR,LINESTYLE=LS,/NOCLIP
RETURN
END
;***********************************************************************
PRO CIRCLEFILL,RADIUS,CINDEX
IF N_ELEMENTS(THETA) EQ 0 THEN THETA=FINDGEN(181)*!PI/90.
X=RADIUS*COS(THETA)
Y=RADIUS*SIN(THETA)
POLYFILL,X,Y,COLOR=CINDEX
RETURN
END
;***********************************************************************
FUNCTION CHAR_HT,normal=normal
; return character size in data (default) or normal coordinates
IF !P.FONT EQ 0 THEN fact=.9 ELSE fact=.6
; Get character height in normal coordinates
cht=fact*(FLOAT(!D.Y_CH_SIZE)/FLOAT(!D.Y_SIZE))
IF NOT KEYWORD_SET(normal) THEN cht=cht*(!Y.CRANGE(1)-!Y.CRANGE(0))$
     / (!Y.WINDOW(1)-!Y.WINDOW(0))
RETURN,cht
END
;*****************************************************************************
PRO TIMES_FONT,size,bold=bold
;set hardware font to Times style, of specified size

IF !D.NAME EQ 'PS' THEN BEGIN
    IF KEYWORD_SET(bold) THEN DEVICE,/TIMES,FONT_SIZE=size,/BOLD ELSE $
		DEVICE,/TIMES,FONT_SIZE=size
  RETURN
ENDIF

IF !D.NAME EQ 'X' THEN BEGIN
  sizestr=['8','10','11','12','14','17','18','24','25','34']
  sizes=FIX(sizestr)
;find a font of size GE the specified size
  xsize=FIX(size)
  IF xsize GT 34 THEN xsize=34
  select=WHERE(sizes GE xsize)
  sizestr=sizestr(select(0))
  IF KEYWORD_SET(bold) THEN weight='bold' ELSE weight='medium'
  name='-adobe-times-' +weight+ '-r-normal--' +sizestr+ '-*'
  DEVICE,FONT=name,GET_FONTNAMES=names,GET_FONTNUM=num
  IF num LT 1 THEN BEGIN
    PRINT,'Could not set X-Window font to Times size ',size
    PRINT,'Could not find font named ',name
    RETURN
  ENDIF
  DEVICE,FONT=names(0)
ENDIF

RETURN
END
;*****************************************************************************
PRO LAT_MLT_LBL,latmin,Pmin,Pmax
  radmax=90.-latmin
; mark latitude circles
  times_font,18,bold=0
  cht=CHAR_HT()
  a=-!PI/4.
  ls=0
  IF latmin MOD 10. NE 0. THEN BEGIN
    radius=90.-latmin
    CIRCLE,radius,ls
    ls=2
  ENDIF
  FOR deg=50.,80.,10. DO BEGIN
    IF deg GE latmin THEN BEGIN
    radius=90.-deg
    CIRCLE,radius,ls
    radius=radius-0.5
    x=radius*COS(a)
    y=radius*SIN(a)
    lbl=STRING(FIX(deg),'(I2.2)')
    XYOUTS,x,y,lbl,ALIGNMENT=1.
    ls=2
    ENDIF
  ENDFOR
; draw MLT tics and labels
  tr=[.96*radmax,radmax]
  r=radmax+.3*cht
  FOR mlt=0,22,2 DO BEGIN
    a= -!PI/2. + !PI*mlt/12
    IF a LT 0. THEN a=a+2.*!PI
    tx=tr*COS(a)
    ty=tr*SIN(a)
    OPLOT,tx,ty
    xx=r*COS(a)
    yy=r*SIN(a) - cht*SIN(a/2 - !PI/4)^2
    align=0.5
    IF a GT !PI/2. AND a LT 3.*!PI/2. THEN align=1.
    IF a GT 3.*!PI/2. OR a LT !PI/2. THEN align=0.
    IF mlt LT 10 THEN fmt='(I1)' ELSE fmt='(I2)'
    lbl=STRING(mlt,fmt)
    XYOUTS,xx,yy,lbl,ALIGNMENT=align
  ENDFOR

xx=1.5*cht
yy=-radmax-1.3*cht
XYOUTS,xx,yy,'MLT',ALIGNMENT=0.

FMT='(I4)'
times_font,25,/bold
cht=CHAR_HT()
xx=radmax+cht
XYOUTS,-xx,yy,STRING(FIX(Pmin),FMT),ALIGNMENT=0.0
XYOUTS, xx,yy,STRING(FIX(Pmax),FMT),ALIGNMENT=1.0

RETURN
END
;*****************************************************************************
PRO TO_CART,R,PHI,X,Y
X=R*COS(PHI)
Y=R*SIN(PHI)
RETURN
END
;*****************************************************************************
PRO POLAR_CONTOUR,POTC,Xgrid,Ygrid,pmin,pmax
; Draw polar contour graph of data in two-dimensional array Z, given
; coordinates X. (Y coordinates assumed idential to X)
;returns pmin and pmax

COMMON CBARSCALE,N_LEVELS,LEVELS,CCOLOR,LStyle

; Need to establish the data axis' scales first
latmin=45.
radmax=90.-latmin
PLOT,[0,0],/NODATA,XRANGE=[-radmax,radmax],XSTYLE=5,$
    YRANGE=[-radmax,radmax],YSTYLE=5,/NOERASE

; Find the highest level that is less than zero
FOR i=0,N_LEVELS-1 DO IF LEVELS(i) LT 0. THEN INDEX=i
CIRCLEFILL,radmax,CCOLOR(INDEX)

CONTOUR,POTC,Xgrid,Ygrid,LEVELS=LEVELS,/FILL,C_COLORS=CCOLOR,MAX_VALUE=900.,$
/OVERPLOT

; now overplot the lines
CONTOUR,POTC,Xgrid,Ygrid,LEVELS=LEVELS,/FOLLOW,C_LABELS=0,MAX_VALUE=900.,$
/OVERPLOT,C_LINESTYLE=LStyle

good=WHERE(POTC LT 900.)
PMAX=MAX(POTC(good),Imax)
PMIN=MIN(POTC(good),Imin)
Imm=[Imax,Imin]
OPLOT,XGRID(good(Imm)),YGRID(good(Imm)),PSYM=1,SYMSIZE=.75

; now put on the latitude and MLT labels
LAT_MLT_LBL,latmin,pmin,pmax

RETURN
END
;*****************************************************************************
PRO DRAW_IMF_ANGLE,angle,Bt,Btmax
PLOT,[0,0],/NODATA,XRANGE=[-1,1],XSTYLE=5,YRANGE=[-1,1],YSTYLE=5,/NOERASE
rmax=.95
CIRCLE,rmax
phi=!PI/2.-angle*!PI/180.
x=cos(phi)*rmax*Bt/Btmax
y=sin(phi)*rmax*Bt/Btmax
ARROW,0.,0.,x,y,/DATA,THICK=1.,HTHICK=3,HSIZE=-.15
times_font,18,/bold
cht=CHAR_HT()
XYOUTS, 1.,0.,'+Y',/DATA,ALIGN=0.
XYOUTS,-1.,0.,'-Y',/DATA,ALIGN=1.
XYOUTS,0., 1.,'+Z',/DATA,ALIGN=.5
y=-1.-1.25*cht
XYOUTS,0.,y,'-Z',/DATA,ALIGN=.5
RETURN
END
;*****************************************************************************
PRO VCOLORBAR,X0,Y0,HT,WIDTH,TITLE,CHARSIZE
; draw a VERTICAL color bar with labels
; lower-left corner is at X0,Y0, in /NORMAL coordinates
; and bar has overall HT and WIDTH, also in /NORMAL coordinates
; TITLE is a character string to go over the bar,
; and CHARSIZE is the size of the annotation

COMMON CBARSCALE,N_LEVELS,LEVELS,CCOLOR,LStyle

; LFMT is string with label format,
LFMT='(I4)'

N_COLORS=N_LEVELS
DELY=HT/(N_COLORS)
BOXX=[0.,WIDTH,WIDTH,0.] + X0
BOXY=[0.,0.,DELY,DELY] + Y0
FOR I=0,N_LEVELS-1 DO POLYFILL,BOXX,BOXY+I*DELY,/NORMAL,COLOR=CCOLOR(I)
BOXX=[0.,WIDTH,WIDTH,0.,0.] + X0
BOXY=[0.,0.,HT,HT,0.] + Y0
PLOTS,BOXX,BOXY,/NORMAL
times_font,charsize,bold=0
cht=CHAR_HT(/Normal)
SX=X0+WIDTH+0.25*CHT
Y=Y0+DELY
LINEX=[0.,WIDTH]+X0
FOR I=1,N_LEVELS-1 DO BEGIN
  PLOTS,LINEX,[Y,Y],/NORMAL,LINESTYLE=LStyle(I)
  SY=Y - 0.5*CHT
  LBL=STRING(FIX(LEVELS(I)),LFMT)
  XYOUTS,SX,SY,LBL,/NORMAL,ALIGN=0.
  Y=Y+DELY
ENDFOR
SX=X0+WIDTH
SY=Y+0.5*CHT
XYOUTS,SX,SY,TITLE,/NORMAL,ALIGN=0.5

RETURN
END
;*****************************************************************************
PRO RGB3_CT,rgblo,rgbmd,rgbhi
; Create and load a color table that goes from one given red-green-blue color
; (lo) to white to another given color (hi)
; One Middle level is set to another color of its own.

common colors,r_orig,g_orig,b_orig,r_curr,g_curr,b_curr

cfact=255./100.

rlo=rgblo(0)*cfact
glo=rgblo(1)*cfact
blo=rgblo(2)*cfact

rhi=rgbhi(0)*cfact
ghi=rgbhi(1)*cfact
bhi=rgbhi(2)*cfact

rmd=BYTE(rgbmd(0)*cfact)
gmd=BYTE(rgbmd(1)*cfact)
bmd=BYTE(rgbmd(2)*cfact)

len1=fix( (!D.TABLE_SIZE-2) / 2)
len2=(!D.TABLE_SIZE-2) - len1

upramp=findgen(len1)/(len1-1)

dnramp=1.- findgen(len2)/(len2-1)

red1=  BYTE(rlo + (255.-rlo)*upramp)
green1=BYTE(glo + (255.-glo)*upramp)
blue1= BYTE(blo + (255.-blo)*upramp)

red1(len1-1)=rmd
green1(len1-1)=gmd
blue1(len1-1)=bmd

red2=  BYTE(rhi + (255.-rhi)*dnramp)
green2=BYTE(ghi + (255.-ghi)*dnramp)
blue2= BYTE(bhi + (255.-bhi)*dnramp)

red2(0)=rmd
green2(0)=gmd
blue2(0)=bmd

red=[0B,red1,red2,255B]
green=[0B,green1,green2,255B]
blue=[0B,blue1,blue2,255B]

TVLCT,red,green,blue
r_curr=red
g_curr=green
b_curr=blue
r_orig=red
g_orig=green
b_orig=blue

RETURN
END
;*****************************************************************************

@translib.pro
@w96.pro

; Begin MAIN program
;*****************************************************************************
COMMON TRANSDAT,CX,ST,CT,AM
COMMON CBARSCALE,N_LEVELS,LEVELS,CCOLOR,LStyle


N_LEVELS=19
N_COLORS=N_LEVELS
;LEVELS=[-999,-120,-105,-90,-75,-60,-45,-30,-15,-5,5,15,30,45,60,75,90,105,120]
LEVELS=[-999,-80,-70,-60,-50,-40,-30,-20,-10,-3,$
3,10,20,30,40,50,60,70,80]

ReadCoef

;Set up arrays to hold calculated potentials:

dr=1.
Rmax=45.
numx=FIX(Rmax/Dr)*2 + 1
Xsteps=FINDGEN(numx)*dr - Rmax
XGRID=Xsteps # REPLICATE(1.,numx)
YGRID=TRANSPOSE(XGRID)
POTC=FLTARR(numx,numx)

r=SQRT(XGRID^2 + YGRID^2)

alat=90.-r
amlt=ATAN(YGRID,XGRID)*12./!PI + 6.


;Set all points outside of Rmax circle equal to 999., to be ignored by
;contour routine.
badpts=WHERE(r GT Rmax+2*dr,numbad)
POTC(badpts)=REPLICATE(999.,numbad)

;Determine which points are within Rmax circle.
;Leave a small band where POTC will remain fixed at zero.
goodpts=WHERE(r LT Rmax)
alat=alat(goodpts)
amlt=amlt(goodpts)

;Set up page format:

winlen=10.
lmarg=3.
rmarg=5.
xlen=winlen+lmarg+rmarg
topmarg=2.
botmarg=1.5
ylen=winlen+topmarg+botmarg

; Calculate the corner locations of the plot "window" region
x0=lmarg
x1=xlen - rmarg
y0=botmarg
y1=ylen-topmarg
;normalize
x0=x0/xlen
x1=x1/xlen
y0=y0/ylen
y1=y1/ylen

; Calculate the corner locations of the plot window for IMF angle vector
IMFsize=2.
xa0=xlen - IMFsize - 2.
xa1=xlen - 2.
ya0=ylen - IMFsize - 1.
ya1=ylen - 1.
;normalize
xa0=xa0/xlen
xa1=xa1/xlen
ya0=ya0/ylen
ya1=ya1/ylen


ytitle=(ylen-1.)/ylen
xtitle=(lmarg+winlen/2.)/xlen
maintitle='Electric Potential'

FmtI2='(I2.2)'

Btmax=12.

by=-5.2
bz=-13.9
vel=340.
year=95
month=9
day=5
hour=12.3
TRANS,year,month,day,hour
Tilt=CX(5)
print, 'TILT', tilt
pltknt=0

REPEAT BEGIN
    PRINT,'By, Bz, and Vel=',by,bz,vel
    PRINT,'Use these values?'
    ans=GET_KBRD(1)
    IF STRUPCASE(ans) NE 'Y' THEN READ,By,Bz,vel

    PRINT,'Year, month, day, and hour=',year,month,day,hour
    PRINT,'Use these values?'
    ans=GET_KBRD(1)
    IF STRUPCASE(ans) NE 'Y' THEN BEGIN
      READ,year,month,day,hour
      TRANS,year,month,day,hour
      Tilt=CX(5)
    ENDIF

    PRINT,'Color version?'
    ans=GET_KBRD(1)
    IF STRUPCASE(ans) EQ 'Y' THEN docolor=1 ELSE docolor=0

    Print,'Working...'

    pagename='W96EPOT'+STRING(pltknt,FORMAT=fmti2)
    NEWPAGE,pagename,xlen,ylen

    !P.FONT=0

    IF docolor THEN BEGIN
;Set up the color table now, after the output device is known.
;; create color table index, of size N_COLORS
;; lowest value is 1 and highest value is !D.TABLE_SIZE-2
      CCOLOR=BYTSCL(INDGEN(N_COLORS),TOP=!D.TABLE_SIZE-3) + 1B
      IF !D.NAME EQ 'PS' THEN DEVICE,/COLOR
      RGB3_CT,[0,85,85],[50,100,50],[90,70,0]
;;    RGB3_CT,[0,85,85],[70,100,70],[90,70,0]
      LStyle=REPLICATE(0,N_LEVELS)
    ENDIF ELSE BEGIN
;Lower part of color scale goes from black to white
      LOADCT,0
      n2=(N_COLORS+1)/2
      Lobar=BYTSCL(INDGEN(n2),TOP=!D.TABLE_SIZE-1)
;Upper part is in reverse order
      Hibar=ROTATE(Lobar,2)
;But with the lowest index cut off
      Hibar=Hibar(1:*)
      CCOLOR=[Lobar,Hibar]
      LStyle=(2*(levels LT 0.))
    ENDELSE


    tilt=0.
    fi3='(I3)'
    ff4='(F4.1)'
    ff5='(F5.1)'

      Theta=ATAN(By,Bz)
;Convert to degrees
      angle=Theta*180./!PI
      IF angle LT 0. THEN angle=angle+360.
      Bt=SQRT(BY^2 + BZ^2)
      SetModel,angle,Bt,tilt,vel
      POTC(goodpts)=EpotVal(alat,amlt)
      !P.POSITION=[x0,y0,x1,y1]
      POLAR_CONTOUR,POTC,Xgrid,Ygrid,potmin,potmax

      TIMES_FONT,25,/bold
      XYOUTS,xtitle,ytitle,maintitle,/NORMAL,ALIGNMENT=.5
      !P.POSITION=[xa0,ya0,xa1,ya1]
      DRAW_IMF_ANGLE,angle,Bt,Btmax
      times_font,24,/bold
      cht=CHAR_HT(/normal)
      x=(xlen-.5)/xlen
      y=ya0-cht
      XYOUTS,x,y,'IMF',/NORMAL,ALIGN=1.
      times_font,18
      str=STRING(Angle,FORMAT=ff5)
      y=ya1
      XYOUTS,x,y,str,/NORMAL,ALIGN=1.
      y=ya0-3.*cht
      str='B!DY!N= '+STRING(By,FORMAT=ff5)+' nT'
      XYOUTS,x,y,str,/NORMAL,ALIGN=1.
      y=y-2.*cht
      str='B!DZ!N= '+STRING(Bz,FORMAT=ff5)+' nT'
      XYOUTS,x,y,str,/NORMAL,ALIGN=1.
      y=y-2.*cht
      str='B!DT!N= '+STRING(Bt,FORMAT=ff5)+' nT'
      XYOUTS,x,y,str,/NORMAL,ALIGN=1.
      y=y-2.*cht
      str='V!DSW!N= '+STRING(FIX(vel),FORMAT=fi3)+' km/s'
      XYOUTS,x,y,str,/NORMAL,ALIGN=1.
      times_font,24
      y=(botmarg+.5)/ylen
      ihour=FIX(hour)
      imin=FIX( (hour-ihour)*60. + .5)
      str=STRING(ihour,imin,FORMAT='(I2.2,":",I2.2," UT")')
      XYOUTS,x,y,str,/NORMAL,ALIGN=1.
      y=y+2.*cht
      str=STRING(month,day,year,FORMAT='(I2.2,"/",I2.2,"/",I2.2)')
      XYOUTS,x,y,str,/NORMAL,ALIGN=1.
;Now draw a vertical color bar
      Ht=(winlen+botmarg)/ylen
      Width=.5/xlen
      xc=0.5/xlen
      yc=(botmarg/2.)/ylen
      VCOLORBAR,xc,yc,Ht,Width,' kV',18

    ENDPAGE
    pltknt=pltknt+1

    PRINT,String(7B),'Do another?'
    ans=GET_KBRD(1)
    done=STRUPCASE(ans) NE 'Y'

ENDREP UNTIL done
END
