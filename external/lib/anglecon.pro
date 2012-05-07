function anglecon, angles, units=units, output=output
    
    if not(keyword_set(units))  then units ='radians'
    if not(keyword_set(output)) then output='radians'
    
    factor = 1
    if strpos('DEGREES', strupcase(units))  ge 0 and $
       strpos('RADIANS', strupcase(output)) ge 0 then factor = !dtor
    if strpos('RADIANS', strupcase(units))  ge 0 and $
       strpos('DEGREES', strupcase(output)) ge 0 then factor = 1./!dtor
    return, angles*factor
end