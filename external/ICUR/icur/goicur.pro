;*******************************************************************
pro goicur,dum,smallw=smallw,file=file,stp=stp  ;IDL version 3 version of ICUR
COMMON VARS,VAR1,VAR2,VAR3,vrot,bdf,psdel,prffit,vrot2
COMMON COM1,H,IK,IFT,NSM,C,NDAT,IFSM,KBLO,H2,ipdv,ihcdev
COMMON COMXY,XCUR,YCUR,ZERR,RESETSCALE,lu3,zzz
COMMON ICDISK,ICURDISK,ICURDATA,ISMDATA,objfile,stdfile,USERDATA,recno,linfile
common icurunits,xunits,yunits,title,c1,c2,c3,ch,c4,c5,c6,c7,c8,c9
common custompars,dw,lp,x2,x3,x4,x5,ldp
;
COLOR=!P.COLOR
!quiet=1
icurdisk=getenv('ICURDISK')
;if ffile('userpro.pro') then begin
;   @USERPRO
;   endif
print,'   '
bell,3
PRINT,' IIIIIII  CCCCCCC   UUU  UUU   RRRRRRR       VVV    VVV   33333 '
PRINT,'   III    CCC       UUU  UUU   RRR  RRR      VVV    VVV      333 '
PRINT,'   III    CCC       UUU  UUU   RRRRRR          VVV VVV    33333  '
PRINT,'   III    CCC       UUU  UUU   RRR RRR   ::     VVVVV        333 '
PRINT,' IIIIIII  CCCCCCC    UUUUUU    RRR  RRR  ::      VVV      33333 '
print,'   '
;
if !version.os eq 'vms' then z='type ' else z='cat '
z=z+icurdisk+'icur.msg'
if ffile(icurdisk+'icur.msg') then SPAWN,z else print,' No ICUR.MSG file found'
;
icursetup,/goicur
;
print,' '
idf=''
idat=0
if ifstring(file) then idf=file else $
   READ,'Enter filename, (-1 TO EXIT, ? to query): ',idf
idf=strtrim(idf,2)
if strlen(idf) eq 0 then idf='?'
case 1 of
   strlen(idf) eq 0: 
   idf eq '-1': idat=-1
   idf eq '?': begin
      print,' .ICD files in current directory:'
      print,getfilelist('*.icd',/noext)
      print,' .ICD files in USERDATA directory:'
      print,getfilelist(userdata+'*.icd',/noext)
      print,' .ICD files in ICURDATA directory:'
      print,getfilelist(icurdata+'*.icd',/noext)
      read,' Enter file name: ',objfile
      searchdir,objfile,'.icd'
      if objfile eq 'nofile' then idat=-1
      end
   else: begin
      objfile=idf
      searchdir,objfile,'.icd'
      if objfile eq 'nofile' then idat=-1
      end
   endcase
;
stdfile='nofile'
ifan=bdf
bdf=0
;
!p.position=[.2,.2,.9,.9]
;
icurmessage=' Welcome to the world of ICUR'
IF (IDAT LT 0) OR (objfile eq 'nofile') THEN goto,ret
H=INTARR(2)-9997
recno=-9
GDAT,objfile,H,W,F,E,recno
IF N_ELEMENTS(H) LT 2 THEN goto,ret
IF (H(0) EQ -9997) and (recno ne -1) THEN goto,ret
IF (H(0) EQ -9997) and (recno eq -1) THEN begin
   print,' Enter record number, -2 to quit'
   recno=-9
   gdat,objfile,h,w,f,e,recno
   endif
;
IF N_ELEMENTS(H) GT 33 THEN BEGIN
   IF H(33) EQ 30 then begin            ;correct S/N vector - force positive
      k=where((e lt 0.) and (e gt -1000.),nk)   ;retain very negative as flags
      if nk gt 0 then e(k)=abs(e(k))
      endif
   ENDIF
;
IF IFAN EQ 1 THEN BEGIN
   case 1 of
      h(3)/10 eq 6: begin           ;MMT
         !Y.TITLE=YTIT(1) & yunits='Cts/S/A'
         end
      h(3)/10 EQ 3: begin
         !Y.TITLE=YTIT(2) & yunits='ADU/S/A'
         end
      h(3) eq 80: begin
         !y.title=ytit(9) & yunits='ph/bin'
         end
      h(3) eq 81: begin
         !y.title=ytit(10) & yunits='ph/cm/cm/S/A'
         end
      h(3) eq 82: !y.title=ytit(0)
      h(3)/10 eq 20: begin    ;IRTF-SPEX
         !y.title='!6 DN/s' & yunits='DN/s'
         !x.title='!7l!6m'  & xunits='microns'
         linfile='ir'
         end
      else: !y.title=ytit(0)
      endcase
   ENDIF ELSE BEGIN
   IF h(3)/10 eq 5 THEN !Y.TITLE='Cts/S/A'
   IF h(3)/10 EQ 3 THEN !Y.TITLE='ADU/S/A'
   yunits=!y.title
   endelse
;
icurmessage='Goodbye'
if n_elements(stp) eq 0 then stp=0
if stp eq 2 then stop,'GOICUR(2)>>>'
ICUR,H,W,F,E,smallw=smallw
!p.color=color
ret:
if keyword_set(stp) then stop,'GOICUR>>>'
print,icurmessage
return
END
