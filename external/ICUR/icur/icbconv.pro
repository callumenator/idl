;******************************************************************************
function icbconv,orig
if n_elements(orig) eq 0 then return,0
; orig=0: vax
; orig=1: alpha, sun
; orig=2: mipsel, 3.1
case 1 of
   (orig eq 0b) and (!version.arch eq 'mipsel'): machine=1     ;vms to DEC
   (orig eq 0b) and (!version.arch eq '3.1'): machine=1        ;vms to PC
   (orig eq 0b) and (!version.arch eq 'sparc'): machine=3      ;vms to sun
   (orig eq 0b) and (!version.arch eq 'alpha'): machine=1      ;vax to alpha
   (orig eq 2b) and (!version.arch eq 'vax'): machine=2        ;DEC to vms
   (orig eq 2b) and (!version.arch eq 'alpha'): machine=2      ;dec to alpha
   (orig eq 2b) and (!version.arch eq 'sparc'): machine=5      ;DEC to sparc
   (orig eq 1b) and (!version.arch eq 'vax'): machine=4        ;sun to vms
   (orig eq 1b) and (!version.arch eq 'mipsel'): machine=6     ;sun to DECs
   (orig eq 1b) and (!version.arch eq '3.1'): machine=6        ;sun to PC
   (orig eq 1b) and (!version.arch eq 'alpha'): machine=0      ;sun to alpha/osf
   else: machine=0
   endcase
return,machine
end
