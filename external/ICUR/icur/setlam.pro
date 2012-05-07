;***************************************************************
pro setlam,wave     ;specify lambda manually for IRPLOT
READ,'  Enter central wavelength: ', LC
ic=xindex(wave,lc)                ;TABINV,WAVE,LC,IC
IL=(FIX(IC+0.5)-50)>0
IU=(FIX(IC+0.5)+50)<(n_elements(wave)-1)
SETXY,WAVE(IL),WAVE(IU)
return
end
