pro sec2hhmm, secin, hhmm, colon=colon

    s = long(secin)
    hours = string(s/3600l, format='(i2.2)')
    min   = string((s - 3600l*hours)/60l, format='(i2.2)')
    if keyword_set(colon) then hhmm  = string(hours, ':', min, format='(a,a,a)') $
                          else hhmm  = string(hours,      min, format='(a,a)')
end