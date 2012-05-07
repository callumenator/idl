; Draw contour map plots of the electric potentials at 8 IMF angles
; using the Weimer '96 model routines in w96.pro
; Fill in contours with color or black & white
;***********************************************************************
PRO CIRCLE,RADIUS,LS,thick=thk
if not keyword_set(thk) then thk=1
IF N_ELEMENTS(THETA) EQ 0 THEN THETA=FINDGEN(181)*!PI/90.
IF(N_PARAMS() EQ 1)THEN LS=0
OPLOT,REPLICATE(Radius,181),Theta,/POLAR,LINESTYLE=LS,thick=thk,/NOCLIP
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
FUNCTION CHAR_HT
IF !P.FONT EQ 0 THEN fact=.9 ELSE fact=.6
  cht=fact*(FLOAT(!D.Y_CH_SIZE)/FLOAT(!D.Y_SIZE))*(!Y.CRANGE(1)-!Y.CRANGE(0))$
     / (!Y.WINDOW(1)-!Y.WINDOW(0))
RETURN,cht
END
;*****************************************************************************
PRO LAT_MLT_LBL,latmin,Pmin,Pmax
  radmax=90.-latmin
; mark latitude circles
  csize=0.75
  cht=csize*CHAR_HT()
  a=-!PI/4.
  ls=0
  FOR deg=latmin,80.,10. DO BEGIN
    radius=90.-deg
    CIRCLE,radius,ls
    radius=radius-0.5
    x=radius*COS(a)
    y=radius*SIN(a)
    lbl=STRING(FIX(deg),'(I2)')
    XYOUTS,x,y,lbl,CHARSIZE=csize,ALIGNMENT=1.
    ls=1
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
    XYOUTS,xx,yy,lbl,CHARSIZE=csize,ALIGNMENT=align
  ENDFOR

xx=1.5*cht
yy=-radmax-1.3*cht
XYOUTS,xx,yy,'MLT',CHARSIZE=csize,ALIGNMENT=0.

FMT='(I3)'
xx=radmax
mmsize=1.25*csize
XYOUTS,-xx,yy,STRING(FIX(Pmin),FMT),CHARSIZE=mmsize,ALIGNMENT=0.0
XYOUTS, xx,yy,STRING(FIX(Pmax),FMT),CHARSIZE=mmsize,ALIGNMENT=1.0

RETURN
END
;*****************************************************************************
PRO TO_CART,R,PHI,X,Y
X=R*COS(PHI)
Y=R*SIN(PHI)
RETURN
END
;*****************************************************************************
PRO POLAR_CONTOUR,POTC,Xgrid,Ygrid
; Draw polar contour graph of data in two-dimensional array Z, given
; coordinates X. (Y coordinates assumed idential to X)

COMMON CBARSCALE,N_LEVELS,LEVELS,CCOLOR,LStyle

; Need to establish the data axis' scales first
latmin=50.
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
PRO DRAW_IMF_ANGLES,offset
PLOT,[0,0],/NODATA,XRANGE=[-1,1],XSTYLE=5,YRANGE=[-1,1],YSTYLE=5,/NOERASE
phi=findgen(8)*!PI/4. + offset*!PI/8.
x=.95*cos(phi)
y=.95*sin(phi)
zero=replicate(0,8)
ARROW,zero,zero,x,y,/DATA,THICK=1.,HTHICK=3,HSIZE=-.15
csize=1.
cht=csize*CHAR_HT()
XYOUTS, 1.,0.,'+Y',/DATA,CHARSIZE=csize,ALIGN=0.
XYOUTS,-1.,0.,'-Y',/DATA,CHARSIZE=csize,ALIGN=1.
XYOUTS,0., 1.,'+Z',/DATA,CHARSIZE=csize,ALIGN=.5
y=-1.-cht
XYOUTS,0.,y,'-Z',/DATA,CHARSIZE=csize,ALIGN=.5
x=-1.-cht
XYOUTS,x,y,'ANGLE',/DATA,CHARSIZE=csize,ALIGN=0.
y=y+1.5*cht
XYOUTS,x,y,'IMF',/DATA,CHARSIZE=csize,ALIGN=0.
RETURN
END
;*****************************************************************************
PRO HCOLORBAR,X0,Y0,HT,WIDTH,TITLE,CHARSIZE
; draw a HORIZONTAL color bar with labels
; lower-left corner is at X0,Y0, in /NORMAL coordinates
; and bar has overall HT and WIDTH, also in /NORMAL coordinates
; TITLE is a character string to go at the end of the bar
; LFMT is string with label format,
; and CHARSIZE is the size of the annotation

COMMON CBARSCALE,N_LEVELS,LEVELS,CCOLOR,LStyle

N_COLORS=N_LEVELS
DelX=Width/N_LEVELS
BOXX=[0.,DelX,DelX,0.] + X0
BOXY=[0.,0.,Ht,Ht] + Y0
FOR I=0,N_LEVELS-1 DO POLYFILL,BOXX+I*DelX,BOXY,/NORMAL,COLOR=CCOLOR(I)
BOXX=[0.,WIDTH,WIDTH,0.,0.] + X0
BOXY=[0.,0.,HT,HT,0.] + Y0
PLOTS,BOXX,BOXY,/NORMAL
IF !P.FONT EQ 0 THEN fact=.9 ELSE fact=.6
cht=charsize*fact*FLOAT(!D.Y_CH_SIZE)/FLOAT(!D.Y_SIZE)
X=X0+DelX
Y=Y0-1.5*cht
LineY=[0.,Ht]+Y0
LFMT='(I4)'
FOR I=1,N_LEVELS-1 DO BEGIN
  PLOTS,[X,X],LineY,/NORMAL,LINESTYLE=LStyle(I)
  LBL=STRING(FIX(LEVELS(I)),LFMT)
  LBL=STRTRIM(LBL,1)
  XYOUTS,X,Y,LBL,/NORMAL,CHARSIZE=CHARSIZE,ALIGN=.5
  X=X+DelX
ENDFOR
XYOUTS,X,Y,TITLE,/NORMAL,CHARSIZE=CHARSIZE,ALIGN=0.

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

@w96.pro

; Begin MAIN program
;*****************************************************************************
COMMON CBARSCALE,N_LEVELS,LEVELS,CCOLOR,LStyle

N_LEVELS=15
N_COLORS=N_LEVELS
LEVELS=[-999,-60,-50,-40,-30,-20,-10,-3,3,10,20,30,40,50,60]

ReadCoef

;Set up arrays to hold calculated potentials:

dr=1.
Rmax=80.
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
FmtI1='(I1)'
;xlen=19.8
xlen=600
topmarg=1.5
botmarg=2.25
ylen=xlen+topmarg+botmarg

; Calculate the corner locations of each plot "window" region
winlen=xlen/3.
marg=0.4
x0=[winlen,REPLICATE(2*winlen,3),winlen,0.,0.,0.] + marg
x1=[2*winlen,REPLICATE(xlen,3),2*winlen,REPLICATE(winlen,3)] - marg
y0=[2*winlen,2*winlen,winlen,0.,0.,0.,winlen,2*winlen] + marg + botmarg
y1=[xlen,xlen,2*winlen,REPLICATE(winlen,3),2*winlen,xlen] - marg + botmarg

;normalize
x0=x0/xlen
x1=x1/xlen
y0=y0/ylen
y1=y1/ylen

center=xlen/2.
centerpos=[ (center-2.)/xlen , (center-2.+botmarg)/ylen ,$
            (center+2.)/xlen , (center+2.+botmarg)/ylen ]

ytitle=(ylen-.5)/ylen
ysubtitle=(ylen-1.2)/ylen
maintitle='Electric Potential'

pltknt=0
Bt=5.
tilt=0.
vel=450.

REPEAT BEGIN
Print,'Enter values for Bt, tilt, and SW velocity (0 to quit)'
READ,Bt,tilt,vel
done=Bt LE 0.


  IF NOT done THEN BEGIN

    PRINT,'Color version?'
    ans=GET_KBRD(1)
    IF STRUPCASE(ans) EQ 'Y' THEN docolor=1 ELSE docolor=0

    pagename='W96'+STRING(pltknt,FORMAT=FmtI1)
    NEWPAGE,pagename,xlen,ylen

;Set up the color table now, after the output device (X or PS) is established.
    IF docolor THEN BEGIN
;; create color table index, of size N_COLORS
;; lowest value is 1 and highest value is !D.TABLE_SIZE-2
      CCOLOR=BYTSCL(INDGEN(N_COLORS),TOP=!D.TABLE_SIZE-3) + 1B
      IF !D.NAME EQ 'PS' THEN DEVICE,/COLOR
;; one version of the color scheme looks better on video, the other version
;; looks better on color prints.
 ;   RGB3_CT,[0,85,85],[50,100,50],[90,70,0]
 ;     RGB3_CT,[0,85,85],[70,100,70],[90,70,0]
 RGB3_CT,[0,85,85],[50,100,50],[90,70,0]
      LStyle=REPLICATE(0,N_LEVELS)
    ENDIF ELSE BEGIN
      LOADCT,0
;Lower part of color scale goes from black to white
      n2=(N_COLORS+1)/2
      Lobar=BYTSCL(INDGEN(n2),TOP=!D.TABLE_SIZE-1)
;Upper part is in reverse order
      Hibar=ROTATE(Lobar,2)
;But with the lowest index cut off
      Hibar=Hibar(1:*)
      CCOLOR=[Lobar,Hibar]
      LStyle=(2*(levels LT 0.))
    ENDELSE

;Now draw the color bar
    Ht=.75/ylen
    Width=13.2/xlen
    x=.5 - Width/2.
    y=.75/ylen
    HCOLORBAR,x,y,Ht,Width,' kV',1.

    XYOUTS,.5,ytitle,maintitle,/NORMAL,CHARSIZE=1.25,ALIGNMENT=.5

    subtitle=STRING(Bt,FORMAT='(F5.1)')+STRING(Tilt,FORMAT='(F8.1)')+$
	STRING(Vel,FORMAT='(F8.0)')
    XYOUTS,.5,ysubtitle,subtitle,/NORMAL,CHARSIZE=1.,ALIGNMENT=.5

offset=0
;set offset=0 to show patterns at IMF angles of even 45 degree increments
;set offset=1 to show the patterns at angles in between, i.e., 22.5, 67.5,etc

set_plot, 'ps'

DEVICE, FILE = 'c:\rsi\idl60\code\potentials\pot2.ps', /COLOR, BITS=8, xsize=18, ysize=26, xoffset=1, yoffset=1

erase, 255

    FOR ii=4,4 DO BEGIN
        angle=ii*45.+offset*22.5
        SetModel,angle,Bt,Tilt,Vel
        ;!P.POSITION=[x0(ii),y0(ii),x1(ii),y1(ii)]
        !P.POSITION=[0.1,0.2,0.9,0.7]
	POTC(goodpts)=EpotVal(alat,amlt)
        POLAR_CONTOUR,POTC,Xgrid,Ygrid
        circle, 25, 2, thick=3  ;; ###MC mod, poker circle
    ENDFOR

;;Put illustration of IMF angles in center
;    !P.POSITION=centerpos
;    DRAW_IMF_ANGLES,offset

device, /close_file
set_plot, 'win'

    ENDPAGE
    pltknt=pltknt+1
  ENDIF

ENDREP UNTIL done
END
