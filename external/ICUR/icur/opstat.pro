;***************************************************************************
pro opstat,status
if strupcase(!d.name) ne 'X' then return
if n_params(0) lt 1 then status=' '
xera=!d.x_ch_size*12
eras=intarr(!d.x_size,!d.y_ch_size+2)                  ;entire bottom of inage
tv,eras,xera,0 & xyouts,xera,2,string(status),/dev
return
end
