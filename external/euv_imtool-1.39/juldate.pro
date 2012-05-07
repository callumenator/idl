PRO JULDATE, DATE, JD, PROMPT = prompt
;+                                                                  
; NAME:
;     JULDATE
; PURPOSE:                                   
;     Convert from calendar to Reduced Julian Date
;
; CALLING SEQUENCE:
;     JULDATE, /PROMPT           ;Prompt for calendar Date, print Julian Date
;               or
;     JULDATE, date, jd      
;
; INPUT:
;     DATE -  3 to 6-element vector containing year,month (1-12),day, and 
;              optionally hour, minute, and second all specified as numbers
;              (Universal Time). Year after 1900 can be specified 2 ways, 
;              either for example, as 83 or 1983.
;              Years B.C should be entered as negative numbers.  If Hour,
;              minute or seconds are not supplied, they will default to 0. 
;
;  OUTPUT:
;       JD - Reduced Julian date, double precision scalar.  To convert to
;               Julian Date, add 2400000.   JULDATE will print the value of
;               JD at the terminal if less than 2 parameters are supplied, or 
;               if the /PROMPT keyword is set
;      
;  OPTIONAL INPUT KEYWORD:
;       /PROMPT - If this keyword is set and non-zero, then JULDATE will prompt
;               for the calendar date at the terminal.
;
;  RESTRICTIONS:
;       Will not work for years between 0 and 99 A.D.  (since these are
;       interpreted as years 1900 - 1999).  Will not work for year 1582.
;
;       The procedure HELIO_JD can be used after JULDATE, if a heliocentric
;       Julian date is required.
;
;  EXAMPLE:
;       A date of 25-DEC-1981 06:25 UT may be expressed as either
;
;       IDL> juldate, [81,12,25,6,25], jd       
;       IDL> juldate, [1981,12,25.2673611], jd 
;
;       In either case, one should obtain a Reduced Julian date of 
;       JD = 44963.7673611
;
;  PROCEDURE USED:
;       GETOPT()
;  REVISION HISTORY
;       Adapted from IUE RDAF (S. Parsons)                      8-31-87
;       Algorithm from Sky and Telescope April 1981   
;       Added /PROMPT keyword, W. Landsman    September 1992
;       Converted to IDL V5.0   W. Landsman   September 1997
;-
 On_error,2 

 if ( N_params() EQ 0 ) and (not keyword_set( PROMPT ) ) then begin
     print,'Syntax - JULDATE, date, jd          or JULDATE, /PROMPT'
     print, $
     '  date - 3-6 element vector containing [year,month,day,hour,minute,sec]'
     print,'  jd - output reduced julian date (double precision)'
     return
 endif

 if ( N_elements(date) EQ 0 ) then begin   

    opt = ''                                                          
    rd: read,' Enter Year,Month,Day,Hour, Minute, Seconds (All Numeric): ',opt
    date = getopt( opt, 'F' )

 endif

 case N_elements(date) of      

    6: 
    5: date = [ date, 0.0d]
    4: date = [ date, 0.0d,0.0d]    
    3: date = [ date, 0.0d, 0.0d,0.0d]
    else: message,'Illegal DATE Vector - must have a least 3 elements'

  endcase   

 iy = fix( date[0] )                     
 im = fix( date[1] )
 date = double(date)
 day = date[2] + ( date[3] + date[4]/60.0d + date[5]/3600.0d) / 24.0d
 if iy LT 100 then iy = iy + 1900    
;
 if ( im LT 3 ) then begin   ;If month is Jan or Feb, don't include leap day

     iy= iy-1 & im = im+12 

 end

 a = fix(iy/100)
 ry = float(iy)
 if ( iy LT 1582 ) then b = 0 else b = 2 - a + fix(a/4)     

 if ( iy EQ 1582 ) then $
   message,'ERROR: Year 1582 not covered'   

 jd = fix(ry*0.25d) + 365.0d*(ry -1860.d) + fix(30.6001d*(im+1.)) + b + $
      day  - 105.5d

 if N_params() LT 2 or keyword_set( PROMPT) then begin      
    yr = fix( date[0] )
    if yr LT 100 then yr = yr+1900
    print, FORM='(A,I4,A,I3,A,F9.5)',$ 
       ' Year ',yr,'    Month', fix(date[1] ),'    Day', day 
    print, FORM='(A,F15.5)',' Reduced Julian Date:',JD                       
 endif
 
 return                               
 end                                  ; juldate
