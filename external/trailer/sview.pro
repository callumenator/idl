
;restore, 'd:\users\conde\main\idl\trailer\020131arrays.dat'
set_plot, 'win'

for j=0,100 do begin
    thelas_specs(j,*) = thelas_specs(j,*) - min(thelas_specs(j,*))
    thelas_specs(j,*) = thelas_specs(j,*)/max(thelas_specs(j,*))
    plot, shift(thelas_specs(j,*), 32)
    wait, 0.4
endfor
end
