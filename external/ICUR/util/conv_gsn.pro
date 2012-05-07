;******************************************************
function conv_gsn,y,fwhm,stp=stp
; FWHM in pixels
x=-fwhm*4.+findgen(fwhm*8.+1)
z=x/fwhm
yy=exp(-z*z/2.)
yy=yy/total(yy)
s=convol(y,yy)
if keyword_set(stp) then stop,'CONV_GSN>>>'
return,s
end
