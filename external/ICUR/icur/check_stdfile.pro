;**************************************************************
pro check_stdfile
common icdisk,icurdisk,icurdata,ismdata,objfile,stdfile,userdata,recno
;
if stdfile eq 'nofile' then begin
   read,' standard file is not defined. Please enter name here: ',stdfile
   endif
;
if not ffile(stdfile+'.icd') then case 1 of
   ffile(userdata+stdfile+'.icd'): stdfile=userdata+stdfile
   ffile(icurdata+stdfile+'.icd'): stdfile=icurdata+stdfile
   else: begin
      print,'File ',stdfile,' not found - returning
      stdfile='nofile'
;      return
   end
   endcase
return
end

