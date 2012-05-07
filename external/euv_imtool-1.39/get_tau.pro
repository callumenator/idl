
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; get_tau - determine tau (number of spins in the integration)
; =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 18-Dec-2003

pro get_tau,s0,s1,s2,mask

@euv_imtool-commons

if ((mask mod 2) ne 0) then begin ; skymap 0 present, use it

    tau = s0.integration_time

endif else if (mask eq 4) then begin ; skymap 2 only, use it

    tau = s2.integration_time

endif else begin                ; otherwise, use skymap 1

    tau = s1.integration_time

endelse


end
