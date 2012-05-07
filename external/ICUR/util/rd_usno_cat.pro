;*************************************************************
function rd_usno_cat,spd0,minra,maxra,mindec,maxdec,stp=stp,debug=debug,minimal=minimal
;common usno,ra,dec,bmag,rmag,zone,cl0,igsc,iprob
common usnocat,usno,usno1,cl0
usno={usno,ra:0.0,dec:0.0,bmag:0.0,rmag:0.0}
usno1={usno1,zone:0L,igsc:0,iprob:0}
spd='0000'+strtrim(spd0,2)
sl=strlen(spd)
spd=strmid(spd,sl-4,4)
case 1 of
   !version.os eq 'vms': cdroot='cdr:[000000]'
   else: cdroot=getenv('CDR')     ;/mnt/cdrom/'                   ;unix
   endcase
cdrfile=cdroot+'zone'+spd+'.acc'
print,cdrfile
openr,lu,cdrfile,/get_lun
s=fstat(lu)
nb=s.size
nr=nb/30
z=bytarr(30,nr)
readu,lu,z
close,lu & free_lun,lu
zs=string(z)
a=dblarr(3,nr)
reads,zs,a
ra1=float(a(0,*))   ;RA at start of segment
ns1=long(a(1,*))    ;first star in segment
ns2=long(a(2,*))    ;stars in segment
;
raband1=fix(minra*100.)/25>0
d1=fix(((minra-ra1(raband1))/0.025)-3)/10. > 0.
ins1=ns1(raband1)+long(d1*ns2(raband1))  ;first star
raband2=fix(maxra*100.)/25+1
if raband2 lt raband1 then swap=1 else swap=0
case 1 of
   raband2 eq 96: ins2=ns1(95)+ns2(95)     ;last star
   else: begin
      d1=(fix((maxra-ra1(raband2-1))/0.025)+3)/10. < 1.
      ins2=ns1(raband2-1)+long(d1*ns2(raband2-1))
;      ins2=ns1(raband2)
      end
   endcase
;
openr,lu,cdroot+'zone'+spd+'.cat',/get_lun
s=fstat(lu)
bps=12     ;bits per star
nbytes=s.size
nstars=nbytes/bps   ;number of stars in band
if swap then number=(nstars-ins1-1)<nstars else number=(ins2-ins1-1)<nstars
print,number,' stars to be read in starting at ',ins1
usno=replicate(usno,number)
a=lonarr(3,number)
point_lun,lu,ins1*bps
readu,lu,a
if swap then begin
   b=lonarr(3,ins2-1)
   point_lun,lu,0
   readu,lu,b
   a=[[a],[b]]
   endif
;help,a
close,lu & free_lun,lu
;
if not is_ieee_big() then ieee_to_host,a
usno.ra=transpose(a(0,*))/100.D0/3600.D0/15.D0
usno.dec=transpose(a(1,*))/100.D0/3600.D0-90.D0
l=transpose(a(2,*))
a=abs(l-(l/1000000000)*1000000000)
b=abs(a-(a/1000000)*1000000)
r=abs(b-(b/1000)*1000)
b=(b-r)/1000
if not keyword_set(minimal) then begin
   usno1=replicate(usno1,number)
   usno1.zone=(a-b*1000-r)/1000000
   usno1.igsc=fix(l/abs(l))      ;-1 if gsc star
   usno1.iprob=fix(abs(l)/1000000000L)   ;1 if problem with magnitudes
   endif else begin
   usno1.zone=0 & usno1.igsc=0 & usno1.iprob=0
   endelse
usno.bmag=b/10. & usno.rmag=r/10.
a=0 & b=0 & r=0
;
if (n_elements(mindec) eq 1) and (n_elements(maxdec) eq 1) then begin
   k=where((usno.dec ge mindec) and (usno.dec le maxdec),nst)
   if nst gt 0 then begin
      usno=usno(k)
      if not keyword_set(minimal) then usno1=usno1(k)
      endif else print,' RD_USNO_CAT: no stars within limits ',mindec,maxdec
   endif
;
if keyword_set(debug) then begin
   degtohms,usno.ra
   degtodms,usno.dec
   print,usno.zone,usno.rmag,usno.bmag
   endif
if keyword_set(stp) then stop,'RD_USNO_CAT>>>'
return,n_elements(usno)
end
