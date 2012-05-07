;**************************************************************************
pro shlp,dum
if !version.os eq 'vms' then z='show queue/all sys$print' else z='lpq'
spawn,z
return
end
