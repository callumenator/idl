;*********************************************************************
function ytit,i,factor,helpme=helpme
if n_params(0) eq 0 then i=0
if keyword_set(helpme) then begin
   print,' '
   print,'* YTIT - generate standard axis labels'
   print,'* calling sequence: title=YTIT(i,p)'
   print,'*    I=0: F-lambda    I=1: ct/s/A     I=2: ADU/s/A'
   print,'*    I=3: F-nu        I=4: -mag       I=5: lam F-lambda'
   print,'*    I=6: cts/s/d     I=7: F-lambda   I=8: cts/s/A'
   print,'*    I=9: cts/bin     I=10: ph/cm/cm/s/A I=11: erg/cm^2/s'
   print,'*    I=12: cts/A     13=ph/cm/cm/s/keV'
   print,'*    I=-1: A          I=-2: Angstroms I=-3: microns'
   print,'*    P: power of 10, applies to I=0,3
   print,' '
   return,''
   endif
ang='!3'+string(byte("305))
if n_elements(factor) eq 1 then $
   pwr='10!U'+strtrim(fix(factor),2)+' !N' else pwr=''
case i of
   0: begin
      z='!17F!D!7k!N!5 ('+pwr+'ergs cm!S!E-2!N s!E-1!N '+ang+'!5!E-1!N)'
      end
   1: z='!5ct s!E-1!N '+ang+'!5!E-1!N'
   2: z='!5ADU s!5!E-1!N '+ang+'!5!E-1!N'
   3: begin
      z='!17F!D!7m!N!5 ('+pwr+'ergs cm!S!E-2!N s!E-1!N!5 hz!E-1!N)'
      end
   4: z='-Mag A!DB!N'
   5: z='!7k!17F!D!7k!N!5 (ergs cm!S!E-2!N s!E-1!N)'
   6: z='!6Counts s!U-1!N d!U-1!N'
   7: z='!6F!D!7k!N!6'
   8: z='!5 counts s!E-1!N '+ang+'!5!E-1!N'
   9: z='!5 counts bin!E-1!N'
  10: z='!5 ph cm!S!E-2!N s!E-1!N'+ang+'!5!E-1!N'
  11: z='!17F!5 (ergs cm!S!E-2!N s!E-1!N)'
  12: z='!5Counts '+ang+'!5!E-1!N'
  13: z='!5 ph cm!S!E-2!N s!E-1!N keV!5!E-1!N'
;
   -1: z=ang           ;Angstrom symbol
   -2: z=ang+'!6ngstroms'      ;Angstroms
   -3: z='!7l!6m'
   else: z='ytitle'
   endcase
return,z
end
