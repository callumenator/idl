;===========================================================================
; Returns 1 if any files matching 'fname' exist, otherwise returns 0:
function fexist, fname
  fcat   = findfile(fname)
  status = strlen(fcat(0)) gt 0 
  return, status
end