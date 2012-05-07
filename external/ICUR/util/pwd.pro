pro pwd
;+
;
;*Name: PWD	(print working directory)
;
;*Purpose: Display the current working directory to sys$output.
;
;*Calling Sequence: pwd
;
;*History
;	 1-may-1993	jkf/acc		- version 1
;   	27-jan-1995	JKF/ACC		- documented and added to GHRS DAF.
;-

cd,current=cwd		; use cd command to get the "current working directory"
print,cwd		; display information to the user.
return
end
