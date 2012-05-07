;---------------------------------------------------------------------
	pro restore_sys, quiet=quiet
;+
; NAME:			restore_sys
;
; PURPOSE:		Restore the previously saved (save_sys) system plot
;			variables. Since these routines use a stack system 
;			they should always be used in pairs to ensure correct 
;			restoration. RESTORE_SYS pops the last set of 
;			variables off the stack
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	restore_sys
;			restore_sys, /quiet
;
; INPUTS:
;	KEYWORDS:
;			QUIET	= if set then dont write restoration message
;
; OUTPUTS:		no explicit outputs, but redefines the system plot 
;			variables, !p, !x, !y, !z
;
; COMMON BLOCKS:	sys_vars
;
; SIDE EFFECTS:
;			redefines the system plot variables, !p, !x, !y, !z
;
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-

	common sys_vars, save_p,save_z,save_y,save_x

	if (not keyword_set(quiet)) then print,'% RESTORING system plot variables '

	num = (n_elements(save_p)-1) > 0
	!p = save_p(num)
	!z = save_z(num)
	!y = save_y(num)
	!x = save_x(num)

	num = num > 1
	save_p = save_p(0:num-1)
	save_z = save_z(0:num-1)
	save_y = save_y(0:num-1)
	save_x = save_x(0:num-1)

	return
	end
;---------------------------------------------------------------------
	pro save_sys,x=sav_x,y=sav_y,z=sav_z,p=sav_p, quiet=quiet
;+
; NAME:			save_sys
;
; PURPOSE:		Save the previously saved (save_sys) system plot
;			variables. Since these routines use a stack system 
;			they should always be used in pairs to ensure correct 
;			restoration. SAVE_SYS pops the last set of 
;			variables off the stack
;
; CATEGORY:		Utility
;
; CALLING SEQUENCE:	save_sys
;			save_sys, /quiet
;			save_sys, x=sav_x,y=sav_y,z=sav_z,p=sav_p, /quiet
;
; INPUTS:
;	KEYWORDS:
;			X,Y,Z,P = current system variable is written into these
;			QUIET	= if set then dont write restoration message
;
; OUTPUTS:		no explicit outputs, but redefines the system plot 
;			variables, !p, !x, !y, !z
;
; COMMON BLOCKS:	sys_vars
;
; SIDE EFFECTS:
;			Saves the system plot variables, !p, !x, !y, !z
;
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;
;-
	common sys_vars, save_p,save_z,save_y,save_x

	if (not keyword_set(quiet)) then print,'% SAVING system plot variables '
	if (n_elements(save_x) le 0) then begin
		save_x = !x
		save_y = !y
		save_z = !z
		save_p = !p
	endif else begin
		save_x = [save_x,!x]
		save_y = [save_y,!y]
		save_z = [save_z,!z]
		save_p = [save_p,!p]
	endelse

	sav_x = !x
	sav_y = !y
	sav_z = !z
	sav_p = !p

	return
	end



