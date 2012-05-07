
function doy, year, month, day


offs=[0,31,59,90,120,151,181,212,243,273,304,334]

dyear = offs[month-1] + day

if (((year mod 4) eq 0) and (month gt 2)) then dyear = dyear + 1

return, dyear

end
