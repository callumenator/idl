        PRO FITSLIST,UPDATE_SWITCH
;+
;  NAME:
;       FITSLIST
;  PURPOSE:
;       Display and write FITS headers from a FITS tape
;  EXPLANATION:
;       Procedure will read FITS files from a tape on the specified
;       tape unit.  The headers are placed in file NAME, with the
;       default extension of .LIS.  Headers are also displayed at the
;       terminal.     Unix and VMS IDL only.  
;
;  CALLING SEQUENCE:
;       FITSLIST            
;       FITSLIST,UPDATE_SWITCH
;
;  OPTIONAL INPUT:
;       UPDATE_SWITCH - If passed and nonzero, then an existing file is opened,
;                       and output is appended to the end of this file.  Also,
;                       the FITS tape is not rewound prior to starting the read.
;                       This is useful if the tape contains spurious EOF marks.
;  OUTPUT:
;       None.
;
;  SIDE EFFECTS:
;       File NAME or NAME.LIS is created, or if UPDATE_SWITCH is nonzero then
;       additional information is appended to the file.
;       Headers are displayed at terminal as well as written to file.
;
;  RESTRICTIONS:
;       Tape must be mounted before calling FITSLIST.
;       FITSLIST uses the VMS IDL tape positioning command, but will also
;       run on Unix machines by using procedures which call IOCTL and 
;       which emulate the VMS IDL tape I/O functions (e.g TAPRD)
;
;  PROMPTS:
;       Program will prompt for 
;       (1)   NAME of output listing file
;       (2)   tape unit number
;
;  PROCEDURES CALLED:
;       FITSTAPE
;  HISTORY:
;       William Thompson, 15-May-1986, based on FITSREAD.
;       William Thompson, 09-Feb-1990, added file numbers.
;       Converted to IDL V5.0   W. Landsman   September 1997
;-
;
        UNIT = 0
        READ,'Enter tape unit number: ',UNIT
;
;  Open the file for output.
;
        NAME = ''
        READ,'Enter output filename: ',NAME
        IF N_PARAMS(0) EQ 0 THEN UPDATE_SWITCH = 0
        GET_LUN,IUNIT
        IF UPDATE_SWITCH EQ 0 THEN BEGIN
            IF !VERSION.OS EQ 'vms' THEN $
            OPENW,IUNIT,NAME,DEF = '.LIS' ELSE $
            OPENW,IUNIT,NAME
            REWIND,UNIT         ;Rewind tape.
        END ELSE BEGIN
            IF !VERSION.OS EQ 'vms' THEN $
            OPENU,IUNIT,NAME,DEF = '.LIS' ELSE $
            OPENU,IUNIT,NAME
            DUMMY = 'STRING'
            WHILE NOT EOF(IUNIT) DO READF,IUNIT,DUMMY  ;Skip to end of file.
        ENDELSE
;
;  Keep track of file numbers.
;
        I_FILE = 0
;
;  Read FITS header
;
START:
        I_FILE = I_FILE + 1
        STATUS = FITSTAPE('init',UNIT,10)
        READ_HEADER:
        HEADER = STRARR(100)                    ;FITS header array.
        NHEAD = 0                               ;Number of lines read in.
        NH = 100                                ;Number of lines in header.
        REC = ASSOC(7,BYTARR(2880))             ;Define record type.
        X = BYTARR(2880)                        ;All FITS records 2880 bytes.
        FOR II = 1,100 DO BEGIN
            STATUS = FITSTAPE('read',UNIT,8,X)
            IF STATUS EQ -4 THEN BEGIN
                PRINT,'EOF while reading FITS header.'
                PRINT,'Processing terminated.'
                FREE_LUN,IUNIT
                RETURN
            ENDIF
            IF STATUS LT 0 THEN BEGIN
                FREE_LUN,IUNIT
                RETURN
            ENDIF
            FOR I = 0,35 DO BEGIN               ;Process 36 header lines.
                H = EXTRAC(X,I*80,80)           ;Extract next line.
                HEADER[NHEAD] = STRING(H)       ;Add to header.
                NHEAD = NHEAD+1
                IF NHEAD EQ NH THEN BEGIN
                        HEADER = [HEADER,STRARR(100)]
                        NH = NH + 100
                ENDIF
                IF STRING(H[0:7]) EQ 'END     ' THEN GOTO,L1  ;Check for end of header
            ENDFOR
        ENDFOR
;
;  Label L1:, transfer point for END line found.
;
L1:
        HEADER = HEADER[0:NHEAD-1]
        PRINTF,IUNIT,'File number = ',I_FILE
        PRINT,       'File number = ',I_FILE
        PRINTF,IUNIT,' '
        PRINT,       ' '
        FOR I = 0,NHEAD-1 DO PRINTF,IUNIT,STRTRIM(HEADER[I])
        FOR I = 0,NHEAD-1 DO PRINT,       STRTRIM(HEADER[I])
        FOR I = 0,2 DO PRINTF,IUNIT,' '
        FOR I = 0,2 DO PRINT,       ' '
;
;  Skip to the end of the file.
;
        SKIPF,UNIT,1
        GOTO,START
;
        END
