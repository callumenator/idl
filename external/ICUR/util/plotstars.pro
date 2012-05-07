;******************************************************************
pro plotstars,ra0,dec0,mag0,sf=sf,o=o,helpme=helpme,stp=stp,queue=queue, $
    notitle=notitle,maglimit=maglimit,recenter=recenter,size_leg=size_leg, $
    hcpy=hcpy,small=small,markcen=markcen,noprint=noprint,title=title, $
    noclose=noclose,redmag=redmag,gsc=gsc,usnoc=usnoc,radius=radius,ybs=ybs
   
common grid,sc,at,dt,ddec,dr,epoch,acen,dcen,atnp,dtnp,xfudge,yfudge,dssastr
common gsc,ras,decs,mags,cls,pe,me,rec,id,b,plate,mult,filename
common usnocat,usno,usno1,cd0
if keyword_set(helpme) then begin
   print,' '
   print,'* PLOTSTARS - plot stars from HST guide star or USNO catalog '
   print,'*    calling sequence: PLOTSTARS,[ra,dec,mag]'
   print,'*       RA,DEC: list of star coordinates'
   print,'*       MAG:    vector containing corresponding stellar magnitudes'
   print,'*       ** ra,dec,mag may also be passed in common from READGSCLST'
   print,'*'
   print,'*   KEYWORDS:'
   print,'*     SF: scale factor relative to POSS; default scales to star coordinates'
   print,'*      O: use blue mag/dia relation; default uses King and Raff E relation.'
   print,'*     QUEUE: name of queue for hardcopy printout, default="MYLP".'
   print,'*     MAGLIMIT: limiting magnitude'
   print,'*     MARKCEN: =[ra,dec] place cross at [ra,dec]
   print,'*     NOCLOSE: set to leave plot device open'
   print,'*     NOTITLE: set to supress title on plot'
   print,'*     RECENTER: 2 or 6 element vector containing new plot center (RA,DEC)'
   print,'*               use /RECENTER to use the cursor to set the center'
   print,'*               use RECENTER=-1 to use the last plotted center'
   print,'*     REDMAG: use rmag in USNO, def=bmag'
   print,'*     SIZE_LEG: size of characters on plot label, def=1.4'
   print,'*     SMALL: set to plot all stars as points; def=0.5'
   print,'*     TITLE: optional title for plot'
   print,'*     YBS:   plot stars from Yale Bright Star Catalog'
   print,' '
   return
   endif
dr=0.0174532935D0
dia=[3,4,5,6,7,8,9,10,12,14,16,18,20,25,30,35,40,45,50,60,70,80,90,100]
dia=dia*10     ;microns
mb=[21.1,20.2,19.4,18.7,18.1,17.6,17.2,16.7,15.9,15.2,14.6,13.8,13.0,11.6]
mb=[mb,10.4,9.6,9.0,8.5,8.2,7.6,7.2,6.9,6.7,6.5]
mr=[20.5,19.6,18.7,18.0,17.3,16.8,16.3,15.9,15.1,14.2,13.5,12.8,12.2,10.8]
mr=[mr,9.7,8.8,8.1,7.6,7.3,6.8,6.4,6.1,5.9,5.7]
tm=21.1-0.1*indgen(212)                 ;0.1 in magnitude
if keyword_set(queue) then hcpy=1
if keyword_set(noclose) then noprint=1
dev=!d.name
if keyword_set(hcpy) then begin
   sp,'ps'
   if dev eq 'PS' then dev='X'
   endif
if not keyword_set(sf) then sf=0
case 1 of
   keyword_set(ybs): begin
      dbopen,'yale_bs'
      if n_elements(radius) eq 1 then begin
         yrad=600.>radius*60.
         endif else yrad=600.
      list=dbcircle(ra0/15.,dec0,yrad)   ;10 deg default
      dbext,list,'ra,dec,vmag,hr,bv',ra,dec,mag,id,bmv
      ra=ra*15.     ;convert to degrees
      ram=ra & decm=dec & rmag=mag & bmag=rmag+bmv & zone=id  ;for FINDP
      usnoc=0 & gsc=1
      dbclose
      end
   (n_params(0) eq 0) and not keyword_set(ybs): begin
      if (n_elements(ras) eq 0) and (n_elements(usno) eq 0) then begin
         print,' You must supply coordinates'
         return
         endif
      if (n_elements(ras) eq 0) then usnoc=1
      if (n_elements(usno) eq 0) then gsc=1
      if (n_elements(usno) eq 1) and keyword_set(usnoc) then gsc=0
      if keyword_set(ybs) then gsc=0
      case 1 of
         keyword_set(gsc): begin
            ra=ras & dec=decs & mag=mags         ;read from common
            end 
         else: begin           ;usnoc
            ra=usno.ra & dec=usno.dec & mag=usno.bmag         ;read from common
            if keyword_set(redmag) then mag=usno.rmag
            end
         endcase
      end
   else: begin
      if n_elements(mag0) eq 0 then mag0=ra0*0.+10.
      ra=ra0 & dec=dec0 & mag=mag0         ;passed
      end
   endcase
;
if keyword_set(recenter) then begin
   case 1 of
      ifstring(recenter):             ;last preserves center
      n_elements(recenter) eq 6: begin
         at=hmstodeg(recenter(0),recenter(1),recenter(2))*dr
         dt=dmstodeg(recenter(3),recenter(4),recenter(5))*dr
         end
      n_elements(recenter) eq 5: begin
         at=hmstodeg(recenter(0),recenter(1),recenter(2))*dr
         dt=dmstodeg(recenter(3),recenter(4))*dr
         end
      n_elements(recenter) eq 2: begin
         at=recenter(0)*dr & dt=recenter(1)*dr
         end
     (n_elements(recenter) eq 1) and (recenter(0) lt 0):
      else: begin        ;use TV
         print,' Place cursor at new center and hit any mouse key'
         cursor,x,y,1
         xytad,at1,dt1,x,y
         at=at1 & dt=dt1
         end
      endcase
   endif
if not keyword_set(recenter) then begin     ;take mean of star positions
   if n_elements(ra) eq 1 then begin
      at=ra*dr & dt=dec*dr
      endif else begin
      at=mean(ra)*dr & dt=mean(dec)*dr 
      endelse
   endif
ddec=max(dec)-min(dec)
if n_elements(dec) eq 1 then mdec=dec else mdec=mean(dec)
rarange=(max(ra)-min(ra))/cos(mdec/!radeg)
if rarange gt 180. then begin    ;crosses RA=0 
   dra=ra
   k=where(dra gt 180.)
   dra(k)=dra(k)-360.
   rarange=(max(dra)-min(dra))/cos(mdec/!radeg)
   if n_elements(dra) gt 1 then dra=mean(dra)
   if dra lt 0. then dra=dra+360.
   at=dra*dr
   endif
print,ddec,rarange,mdec
ddec=ddec>rarange
;
if keyword_set(maglimit) then begin
   kmag=where(mag le maglimit,ngood)
   if ngood gt 0 then begin
      ra=ra(kmag) & dec=dec(kmag) & mag=mag(kmag)
      zm='    plotted to magnitude '+string(maglimit,'(F6.2)')
      print,ngood,' stars plotted to magnitude ',string(maglimit,'(F6.2)')
      endif else begin
      print,' No stars found brighter than magnitude ',maglimit
      return
      endelse
   endif else zm=''
;
if n_elements(filename) eq 0 then filename=''
!p.title='!6'+filename+zm
if keyword_set(title) then !p.title=title
if keyword_set(notitle) then !p.title=''
plotsky,sf=sf,size_leg=size_leg,radius=radius
!p.title=''
poss=66.7     ;arcsec/mm
sfct=poss/sc     ;   sc is scale in arcsec/mm
adtxy,ra*dr,dec*dr,x,y               ;positions of stars
k=where((x ge !x.crange(0)) and (x le !x.crange(1)) and $
        (y ge !y.crange(0)) and (y le !y.crange(1)),nk)
d=min(dia)
if nk gt 0 then begin
   x=x(k) & y=y(k) & if n_elements(mag) gt 0 then mg=mag(k) 
   figsym,2,1
   if not keyword_set(small) then begin
      if keyword_set(o) then d=interpol(dia,mb,tm) else d=interpol(dia,mr,tm)
      endif
   if n_elements(mag) eq 0 then oplot,x,y,psym=8 else begin
      k=xindex(tm,mg)
      if keyword_set(small) then begin $
         if (abs(small-1.0) lt 0.001) then small=0.5
         sp=mag*0.+small
         endif else $
         sp=(lint(d,k)*sfct*!d.x_px_cm/1.E4/!d.x_ch_size)>.2         ;pixels
      ns=n_elements(x)
      for i=0,ns-1 do begin
         figsym,2,1,sp(i)
         opp,x(i),y(i),8
         endfor
      endelse
   endif else print,' No stars in this region'
if keyword_set(markcen) then begin
   if n_elements(markcen) gt 2 then ms=markcen(2) else ms=1.
   markp,markcen(0),markcen(1),siz=ms
   endif
print,' PLOTSTARS: plate scale=',sc,' arcsec/mm'
if !d.name eq 'X' then begin
   wshow
   print,' Use FINDP to identify stars'
   endif
if not keyword_set(queue) then queue=0
if n_elements(hcpy) ne 0 then begin
   if not keyword_set(noclose) then $
      make_hcpy,hcpy,dev,queue=queue,noprint=noprint
   endif
if keyword_set(stp) then stop,'PLOTSTARS>>>'
return
end
