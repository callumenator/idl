;-------------------------------------------------------------------------
FUNCTION Th_choice, choice_array, NOCHOICE=nochoice, FINDFL=findfl, $
                    INDEX=index, TITLE=title, QUESTION=question, $
                    DEF_SELECTION=def_selection, NOPOPUP=nopopup, LIST=list
;+
; NAME:		TH_CHOICE
;
; PURPOSE:	Allow the user to select (with mouse on a window device) from 
;		a number of choices
;
; CATEGORY:	Utilities
;
; CALLING SEQUENCE:
;	selection = TH_CHOICE ( choice_array, TITLE=title, $
;			QUESTION=question, DEF_SELECTION=def_selection, $
;			/NOCHOICE, /FINDFL, /INDEX, /NOPOPUP, /LIST)
;
; INPUTS:
;
;	choice_array 	= input string array of choices
;
;   OPTIONAL KEYWORD PARAMETERS:
;	TITLE		= title of the created widget
;	QUESTION	= the question to be asked of the user
;	DEF_SELECTION	= initial/default selection  
;	NOCHOICE	= if set then dont offer the user a choice
;	FINDFL		= if set then choice_array is a filter,
;			  and FIND_FILE is used to obtain the file choices
;	INDEX		= if set then return the index chosen rather than the
;			  actual choice string
;	NOPOPUP		= if set then dont use the widget popup facility
;	LIST   		= if set then use a list widget rather than button menu
;
;
; OUTPUTS:
;
;	selection	= the chosen string, or if INDEX is set then the index
;			  into the choice_array is output.
;
; COMMON BLOCKS:
;	none.
; SIDE EFFECTS:
;	none.
; MODIFICATION HISTORY:
;	Written by: Trevor Harris, Physics Dept., University of Adelaide,
;		July, 1990.
;	Ammended to handle VMS filename expansion syntax 
;	(in otherwords, limit the filename expansion capabilities !!)
;		TJH July 1992 
;
;	Ammended to use widgets if available. Calls TH_WMENU instead of WMENU
;		TJH February 1994, IE, HFRD, DSTO
;
;	Ammended to use a list widget if requested.
;		TJH January 1995, IE, HFRD, DSTO
;
;-
  
  IF (KEYWORD_SET(findfl) ) THEN BEGIN
    IF (N_ELEMENTS(choice_array) LE 0) THEN choice_array  = '*'
    IF (strlen(choice_array) LE 0) THEN choice_array  = '*'
                                ;if on a VMS system then change the filename syntax
    IF (strlowcase(!Version.os) EQ 'vms') THEN $
      FOR i = 0, N_ELEMENTS(choice_array) -1 DO BEGIN
      tmp = choice_array(i) 
      choice_array(i) = unix2vms(tmp) 
    ENDFOR
    files = findfile(choice_array, COUNT=count) 
                                ;if on a VMS system then trim off the version numbers
    IF (strlowcase(!Version.os) EQ 'vms') THEN $
      FOR i = 0, N_ELEMENTS(files) -1 DO BEGIN
      tmp = strpos(files(i), ';') 
      IF (tmp GT 0) THEN files(i) = strmid(files(i), 0, tmp) 
    ENDFOR
  ENDIF ELSE BEGIN
    files = choice_array
    count = N_ELEMENTS(choice_array) 
  ENDELSE
                                ;ensure text in array "files" is not too large to display
  files = strmid(files, 0, 80) 

  IF (NOT KEYWORD_SET(title) ) THEN title = ' CHOICES :'
  IF (N_ELEMENTS(def_selection) LE 0) THEN def_selection = N_ELEMENTS(files) 

  what = strupcase(!D.name) 

  which_one = 0

  IF (count LE 0) THEN BEGIN
    
    IF (NOT KEYWORD_SET(nochoice) ) AND (KEYWORD_SET(question) ) THEN $
      BEGIN
      outfile = ' '
      print, question 
      read, outfile
      outfile = strtrim(outfile, 2) 
      IF ((strpos('-1234567890', strmid(outfile, 0, 1) ) LT 0) $
          AND ( outfile NE  ' ') ) THEN which_one = -10
      
    ENDIF ELSE print, $
      ' There are no files fitting the file specification ', $
      choice_array

  ENDIF ELSE BEGIN
    
    IF (fix(!D.flags /2.^8 MOD 2) $
        AND (NOT KEYWORD_SET(nochoice) ) $
        AND (NOT KEYWORD_SET(nopopup) ) ) THEN BEGIN
      
      which_one = th_wmenu([ title, files, 'EXIT'], $
                           TITLE=0, INIT=def_selection +1, LIST=list) 
      IF (which_one GT N_ELEMENTS(files) ) THEN which_one = 0
    ENDIF ELSE BEGIN  
      which_one = -1
      WHILE (which_one GT N_ELEMENTS(files) ) OR $
        (which_one LT 0 AND which_one NE -10) DO BEGIN
        
        print, ' '
        print, title
        print, ' '
        i = indgen(N_ELEMENTS(files) ) +1
        menutxt = string(i, FORMAT="(i3,': ')") +files(i -1) 
        menutxt = [ menutxt, '  0:  EXIT ']
        num = N_ELEMENTS(menutxt) 
        maxlen = max(strlen(menutxt) ) < 76
        maxlen = fix(76 /fix(76 /maxlen) ) 
        prntxt = strarr(num) 
        lstr = ' '
        FOR i = 1, maxlen -1 DO lstr = lstr +' '
        FOR i = 0, num -1 DO BEGIN
          tmpstr = lstr
          strput, tmpstr, menutxt(i) 
          prntxt(i) = tmpstr
        ENDFOR
        prntxt(0) = ' ' +prntxt(0) 
        print, prntxt
        print, ' '
        IF (NOT KEYWORD_SET(nochoice) ) THEN BEGIN
          outfile = ' '
          IF (KEYWORD_SET(question) ) THEN print, question $
          ELSE print, '   Choose a Number :'
          read, outfile
          outfile = strtrim(outfile, 2) 
          IF (strpos('-1234567890', strmid(outfile, 0, 1) ) $
              GE 0) THEN which_one = fix(outfile) $
          ELSE IF ( outfile EQ  ' ') THEN $
            which_one = def_selection ELSE which_one = -10
        ENDIF ELSE which_one = 0
      ENDWHILE
      
    ENDELSE
    
  ENDELSE
  
  

  IF (which_one GT -10) THEN $
    IF (which_one LE 0) THEN outfile = ' No File Chosen ' $
  ELSE	outfile = files(which_one -1) 

  IF (KEYWORD_SET(index) ) THEN RETURN, which_one -1 ELSE RETURN, outfile
END


