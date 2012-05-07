;*******************************************************************
pro icursetup,goicur=goicur,nowindow=nowindow   ;set up commons for ICUR
;icur_go.pro   IDL version 2 version of ICUR
COMMON VARS,VAR1,VAR2,VAR3,Vrot,VAR5,psdel,prffit,vrot2
COMMON COM1,H,IK,IFT,NSM,C,NDAT,IFSM,KBLO,H2,ipdv,ihcdev
COMMON COMXY,XCUR,YCUR,ZERR,resetscale,LU3,zzz
COMMON ICDISK,ICURDISK,ICURDATA,ISMDATA,objfile,stdfile,userdata,recno,linfile
common icurunits,xunits,yunits,title,c1,c2,c3,ch,c4,c5,c6,c7,c8,c9
common custompars,dw,lp,flatback,autofft,EAFUDGE,x5,ldp
;
!QUIET=1
XCUR=1. & YCUR=1. & ZERR=32
;
icurdisk=getenv('ICURDISK')
icurdata=getenv('ICURDATA')
userdata=getenv('USERDATA')
ismdata=getenv('ISMDATA')
;
if keyword_set(goicur) then !prompt='IDL:icur>'
;
ipdv=!d.name           ;plot device
sp,ipdv
;
defsysv,'!verbose',0
!X.TYPE=0
!X.style=0
!y.TYPE=0
!y.style=0
!X.TITLE='Angstroms'
IF N_ELEMENTS(XUNITS) EQ 0 THEN xunits='Angstroms'
!X.TITLE='!6'+xunits
if n_elements(yunits) eq 0 then yunits='Flambda'
var2=0
IFAN=1 ;ELSE IFAN=VAR2/ABS(VAR2)    ;SIGN OF VAR2
nsm=1
;
IF IFAN EQ 1 THEN begin
   !p.font=-1
   !p.charsize=7./5.
   !Y.TITLE=YTIT(0) 
   if strupcase(yunits) eq 'COUNTS' then !y.title=ytit(9)
   endif else begin            ;var2 negative
   !p.font=0
   !p.charsize=0.
   !Y.TITLE='erg/cm/cm/S/A'
   yunits=!y.title
   endelse
;
!P.NOCLIP=0
var2=abs(var2)
IF VAR2 NE 1 THEN VAR2=0
VAR3=2*256             ;ADDRED TABLE
VAR1=0  
VAR5=ifan
eafudge=1.
;
vrot=0. & vrot2=0.
psdel=0                            ;delete plots after printing
;          psdel bit 0: delete if 0, save if 1
;                bit 1: print if 0, noplot if 1
prffit=0                           ;do not automatically print out fits
resetscale=1
objfile='nofile'
linfile='nofile'
if n_elements(stdfile) eq 0 then stdfile='nofile'
C=FLTARR(1)+1.
ihcdev='PS'                     ;default hard copy device
;
; set up color tables **************************
pcolor=!p.color<255                           ;*
color=pcolor                                  ;*
c1=pcolor & c2=pcolor & c3=pcolor             ;*
ch=4                                          ;*
if strupcase(!d.name) eq 'X' then begin       ;*
   if not keyword_set(nowindow) then window,xsize=2,ysize=2  ;*
   case 1 of                                  ;*
;      !d.n_colors ge 256: begin            ;*
;         c2='7fff00'x                      ;*
;         c3='ff00ff'x                      ;*
;         c4='00ffff'x                      ;*
;         c5='00ff00'x                      ;*
;         c6='ff7f00'x                      ;*
;         c7='ff007f'x                      ;*
;         c8='ffff00'x                      ;*
;         c9='007fff'x                      ;*
;         end                               ;*
      else: begin                             ;*
         gc,13                                ;*
         c2=8                                 ;*
         c3=2                                 ;*
         c4=4                                 ;*
         c5=5                                 ;*
         c6=6                                 ;*
         c7=7                                 ;*
         c8=1                                 ;*
         c9=9                                 ;*
         end                                  ;*
      endcase                                 ;*
   if not keyword_set(nowindow) then wdelete,!d.window    ;*
   endif                                      ;*
;***********************************************
;
; setups for stand-alone calling
;
h=intarr(400)
w=findgen(1024)
f=w
e=fltarr(1024)
;
;my parameters
autofft=1
eafudge=50.
;
if keyword_set(goicur) then return
;
!p.position=[.15,.15,.95,.95]
if strupcase(!d.name) eq 'TEK' then !p.position=[.2,.2,.9,.9]
;
return
END
