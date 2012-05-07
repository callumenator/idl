spawn, 'at /delete'
print, 'Deleted all current AT jobs!'
for hour=0,23 do begin
    for minute=0,50,10 do begin
        timestring = string(hour, format='(i2.2)') + ':' + string(minute, format='(i2.2)')
        cmd = 'at \\sdi2000 ' + timestring + $
               ' /interactive /every:m,t,w,th,f,s,su d:\users\sdi2000\sdi_watchdog\watchdog.bat'
        spawn, cmd
    endfor
endfor
print, 'SDI watchdog checking is now installed.'
end