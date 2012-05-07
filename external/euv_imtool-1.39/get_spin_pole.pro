
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; get_spin_pole - return the spin axis unit vector from one of
;                 the skymaps
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 24-Feb-2003

pro get_spin_pole,s0,s1,s2,mask

@euv_imtool-commons

if ((mask mod 2) ne 0) then begin ; skymap 0 present, use it

    spin_axis_x = s0.gci_s_c_spin_axis_x
    spin_axis_y = s0.gci_s_c_spin_axis_y
    spin_axis_z = s0.gci_s_c_spin_axis_z

endif else if (mask eq 4) then begin ; skymap 2 only, use it

    spin_axis_x = s2.gci_s_c_spin_axis_x
    spin_axis_y = s2.gci_s_c_spin_axis_y
    spin_axis_z = s2.gci_s_c_spin_axis_z

endif else begin                ; otherwise, use skymap 1

    spin_axis_x = s1.gci_s_c_spin_axis_x
    spin_axis_y = s1.gci_s_c_spin_axis_y
    spin_axis_z = s1.gci_s_c_spin_axis_z

endelse


end
