;****************************************************************************
;+
;*NAME:
;
;    TRANS_BYTES
;
;*PURPOSE:
;
;    To translate the byte representation of IDL variables to 
;    a format compatible with the host operating system as defined
;    by the IDL system variable !version.arch. TRANS_BYTES currently 
;    supports SPARC (Sun-4s and SPARCStations), MIPSEL (DECstation 3100
;    and IBM 386 class PCs), and VAX (VAXstation and MicroVAX).
;
;*CALLING SEQUENCE:
;
;    TRANS_BYTES, BYTE_EQ, vartyp, cpupar 
;
;*PARAMETERS:
;
;    BYTE_EQ  (REQ) (IO) (B) (012)
;        The byte representation of the data variable to be converted.
;
;    vartyp (OPT) (I)  (I)     (0)
;        Parameter to identify the type of data which BYTE_EQ represents.
;
;            byte              1
;            integer           2
;            longword integer  3
;            floating point    4
;            double precision  5
;
;        If VARTYP is not given in the call, the user will be prompted 
;        for it.
;
;    cpupar   (OPT) (I)  (I)     (0)
;        Parameter to identify data translation mode. If not present
;        in the calling statement, TRANS_BYTES will prompt the user.
;		
;            no conversion        0
;   
;            VAX     to  MIPSEL   1
;            MIPSEL  to  VAX      2
;   
;            VAX     to  SPARC    3
;            SPARC   to  VAX      4
;   
;            MIPSEL  to  SPARC    5
;            SPARC   to  MIPSEL   6
;   
;        Supported Data Types:
;   
;            VAX    - VAXstations, MicroVAX
;            MIPSEL - DECstations, IBM 386
;            SPARC  - SparcStations, Sun 4##
;   
;        No Conversion is required between like data types, such as 
;        DECstations and IBM 386s.
;
;        If CPUPAR is not given in the call, the user will be prompted 
;        for it.
;
;*SIDE EFFECTS:
;
;*SUBROUTINES CALLED:
;
;    SWAP_BYTES
;    PARCHECK
;
;*SYSTEM VARIABLES USED:
;
;*NOTES:
;
;    The internal data formats currently supported are:
;
;       SunOs data type: 
;             SUN4's and SPARCStations 
;             IEEE standard (Big Endian Configuration)
;
;       DECStation data type:
;             IEEE standard (Little Endian Configuration)
;
;       VAXStation data type:
;             VAX (not IEEE)
;             This program considers floating point to be the VMS 
;             "f-floating", and double precision to be "d-floating".
;             H-floating and g-floating are not supported.
;      
;       DOS data type:
;             IEEE standard (same as DECstation)
;
;
;    The IEEE standard data types differ only in the byte order.
;    Big Indian configuration has the most significant byte at the
;    lowest machine address. For the Little Endian configuration,
;    the least significant byte is at the lowest machine address.
;
;           Big Endian:     | 0 | 1 | 2 | 3 |
;           Little Endian:  | 3 | 2 | 1 | 0 |
;
;    The IEEE standard single precision Big Endian representation is:
;
;       |       0       |       1       | ...        
;       31                                                     0
;        S E E E E E E E E F F F F F F F ...
;
;    Here, the "S" is the sign bit, "E"'s are the exponent bits, 
;    and the "F"'s are the normalized fraction bits.
;
;    The IEEE standard floating point data types contain on sign bit,
;    an eight bit exponent field biased by 127, and a 23 bit fraction.
;    There are two reserved values, Nan (not a number), and infinity.
;
;    The VAX single precision floating point data type contains one
;    sign bit, an eight bit exponent biased by 128, and a 23 bit 
;    normalized fraction. There is only on reserved value for the VAX,
;    reserved operand fault. The sign bit is bit number 15, bits 7
;    through 14 contain the exponent, and the remaining bits contain
;    the normalized fraction. 
;
;    The IEEE standard double precision data types contain one sign
;    bit, an eleven bit exponent, biased by 1023, and a 52 bit
;    normalized fraction. The bit ordering within the bytes is 
;    similar to that of single precision.
;
;    The VAX d-floating double precision floating point representation
;    contain one sign bit, an 8 bit exponent biased by 128, and a 55
;    55 bit normalized fraction. Again, the sign bit is bit 15, and 
;    the exponent is contained in bits 7 through 14.
;
;    The same reserved values occur in double precision.
;
;    tested with IDL Version 2.1.2  (sunos sparc)     14 Oct 91
;    tested with IDL Version 2.1.2  (ultrix mipsel)   14 Oct 91
;    tested with IDL Version 2.2.0  (ultrix vax)      14 Oct 91
;    tested with IDL Version 2.1.2  (vms vax)         14 Oct 91
;
;*RESTRICTIONS:
;       
;    Converting the byte representation of a floating point or double
;    precision number to floating point or double precision type on a
;    CPU for which the byte representation was not intended may cause
;    conflicts with reserved values (i.e. NaN, infinity, or reserved
;    operand faults), resulting in corrupted data.
;
;*EXAMPLE:
;
;*MODIFICATION HISTORY:
;
;    Version 1 of vtos.pro	By John Hoegy		13-Jun-88
;    27-Oct-89 - GD:   Slightly modified program vtos.pro according
;                      to suggestions by RWT.
;    5/30/90 RWT merge vtos and vtod to create vtou
;    1/25/90 GRA Modified vtou to enable transfers between VMS, ULTRIX
;                and SunOs systems.
;    3/18/91 GRA Renamed vtou to TRANS_BYTES.
;    3/28/91 PJL added PARCHECK
;    4/24/91 RWT add support for DOS
;    6/24/91 GRA cleaned up
;    7/26/91 RWT add cpupar=0 option for no conversion
;    10/8/91 GRA globally changed all references to "syspar" to "cpupar",
;                changed cpupar to reference machine architecture as
;                defined by !version.arch; tested on sunos/sparc, 
;                ultrix/mipsel, ultrix/vax, and vms/vax. 
;-
;****************************************************************************
pro trans_bytes, byte_eq, vartyp, cpupar
;
npar = n_params()
if npar eq 0 then begin
   print,'TRANS_BYTES,BYTE_EQ,vartyp,cpupar'
   retall
endif  ; npar
parcheck,npar,[1,2,3],'TRANS_BYTES"
;
if npar lt 2 then begin
   ;
   print,'Select Output Data Type'
   print,' '
   print,'  Byte                 1'
   print,'  Integer              2'
   print,'  Long Integer         3'
   print,'  Floating Point       4'
   print,'  Double Precision     5'
   print,' '
   read,'  Data Type? ',vartyp
   ;
   vartyp = fix(vartyp)
   ;
endif  ; npar
;
if npar lt 3 then begin
   ;
   print,'Data Formats Available:'
   print,' '
   print,'  VAX    - VAXstations, MicroVAX
   print,'  MIPSEL - DECstations, IBM 386
   print,'  SPARC  - SparcStations, Sun 4##
   print,' '
   print,'Select Conversion Option'
   print,' '
   print,'  To RETURN            0'
   print,' '
   print,'  VAX     to  MIPSEL   1'
   print,'  MIPSEL  to  VAX      2'
   print,' '
   print,'  VAX     to  SPARC    3'
   print,'  SPARC   to  VAX      4'
   print,' '
   print,'  MIPSEL  to  SPARC    5'
   print,'  SPARC   to  MIPSEL   6'
   print,' '
   read,'  Option? ',cpupar
   ;
   cpupar=fix(cpupar)
endif  ; npar
if (cpupar eq 0) then return                     ;skip conversion
;
byte_elems=long(n_elements(byte_eq))
;
case vartyp of
 ;
  1: return                                                    ; byte
 ;
  2: if (cpupar gt 2) then swap_bytes,byte_eq,2 else return    ; integer
 ;
  3: if (cpupar gt 2) then swap_bytes,byte_eq,4 else return    ; longword
 ;
  4: begin                                             ; floating point
     ;
     ; define index variable
     ;
      byte_elems = byte_elems + 3L
      i1 = lindgen(byte_elems/4L)*4L
      i2 = i1 + 1L
     ;
     ; 
     ;
      case cpupar of
      ;
       1: begin   ; VAX to DEC
          ;
          ; swap adjacent bytes
          ;
           swap_bytes,byte_eq,2
          ;
          ; change exponent bias, 128 --> 127
          ;
           exponent = $
             byte((byte_eq(i1) and '7F'X) * 2) or byte(byte_eq(i2)/128)
           i = where(exponent ne 0)
           if ((size(i))(0) ne 0) then exponent(i) = byte(exponent(i) - 2)
           byte_eq(i1) = byte(byte_eq(i1) and '80'X) or byte(exponent/2)
           byte_eq(i2) = byte(byte_eq(i2) and '7F'X) or byte(exponent*128)
          ;
          ; invert byte order 
          ;
           swap_bytes,byte_eq,4
          ;
          endcase  ; 4-1
          ;
       2: begin   ; DEC to VAX
          ;
          ; invert byte order
          ;
           swap_bytes,byte_eq,4
          ;
          ; change exponent bias, 127 --> 128
          ;
           exponent = $
             byte((byte_eq(i1) and '7F'X) * 2) or byte(byte_eq(i2)/128)
           i = where(exponent ne 0)
           if ((size(i))(0) ne 0) then exponent(i) = byte(exponent(i) + 2)
           byte_eq(i1) = byte(byte_eq(i1) and '80'X) or byte(exponent/2)
           byte_eq(i2) = byte(byte_eq(i2) and '7F'X) or byte(exponent*128)
          ;
          ; swap adjacent bytes
          ;
           swap_bytes,byte_eq,2
          ;
          endcase  ; 4-2
          ;
       3: begin   ; VAX to SUN
          ;
          ; swap adjacent bytes
          ;
           swap_bytes,byte_eq,2
          ;
          ; change exponent bias, 128 --> 127
          ;
           exponent = $
             byte((byte_eq(i1) and '7F'X) * 2) or byte(byte_eq(i2)/128)
           i = where(exponent ne 0)
           if ((size(i))(0) ne 0) then exponent(i) = byte(exponent(i) - 2)
           byte_eq(i1) = byte(byte_eq(i1) and '80'X) or byte(exponent/2)
           byte_eq(i2) = byte(byte_eq(i2) and '7F'X) or byte(exponent*128)
          endcase  ; 4-3
          ;
       4: begin   ; SUN to VAX
          ;
          ; change exponent bias, 127 --> 128
          ;
           exponent = $
             byte((byte_eq(i1) and '7F'X) * 2) or byte(byte_eq(i2)/128)
           i = where(exponent ne 0)
           if ((size(i))(0) ne 0) then exponent(i) = byte(exponent(i) + 2)
           byte_eq(i1) = byte(byte_eq(i1) and '80'X) or byte(exponent/2)
           byte_eq(i2) = byte(byte_eq(i2) and '7F'X) or byte(exponent*128)
          ;
          ; swap adjacent bytes
          ;
           swap_bytes,byte_eq,2
          ;
          endcase  ; 4-4
          ;
       5: begin   ; DEC to SUN 
          ;
          ; invert byte order
          ;
           swap_bytes,byte_eq,4
          ;
          endcase  ; 4-5
          ;
       6: begin   ; SUN to DEC
          ;
          ; invert byte order
          ;
           swap_bytes,byte_eq,4
          ;
          endcase  ; 4-6
          ; 
      endcase  ; cpupar 
     ; 
      return
     endcase  ; 4
 ;
 ;
 ;
  5: begin    	         	; double precision
     ;
     ; define index variable
     ;
      byte_elems = byte_elems + 7L
      i1 = lindgen(byte_elems/8L)*8L
      i2 = i1 + 1L
      i3 = i2 + 1L
      I4 = i3 + 1L
      i5 = i4 + 1L
      i6 = i5 + 1L
      i7 = i6 + 1L
      i8 = i7 + 1L
     ;
     ;
     ;
      case cpupar of 
         ;      
       1: begin ;   VAX to DEC
          ;  
          ; swap bytes 
          ;
           swap_bytes,byte_eq,2
          ;
          ; change exponent 8-bit 128 bias to 11-bit 1023 bias twos comp
          ;
           exponent = fix( ((byte_eq(i1) and '7F'X)*2) or $
 		           ((byte_eq(i2) and '80'X)/128) )
           i = where(exponent ne 0)
           if ((size(i))(0) ne 0) then exponent(i) = exponent(i) - 128 + 1022
          ;
    byte_eq(i8) = ((byte_eq(i7) and '07'X)*32) or ((byte_eq(i8) and 'F8'X)/8)
    byte_eq(i7) = ((byte_eq(i6) and '07'X)*32) or ((byte_eq(i7) and 'F8'X)/8)
    byte_eq(i6) = ((byte_eq(i5) and '07'X)*32) or ((byte_eq(i6) and 'F8'X)/8)
    byte_eq(i5) = ((byte_eq(i4) and '07'X)*32) or ((byte_eq(i5) and 'F8'X)/8)
    byte_eq(i4) = ((byte_eq(i3) and '07'X)*32) or ((byte_eq(i4) and 'F8'X)/8)
    byte_eq(i3) = ((byte_eq(i2) and '07'X)*32) or ((byte_eq(i3) and 'F8'X)/8)
    byte_eq(i2) = ((exponent and '00F'X)*16) or ((byte_eq(i2) and '78'X)/8)
    byte_eq(i1) = (byte_eq(i1) and '80'X) or ((exponent and '7F0'X)/16)
          ; 
          ; invert byte order 
          ;
           swap_bytes,byte_eq,8
          endcase  ; 5-1
          ;
       2: begin ;   DEC to VAX
          ; 
          ; invert byte order 
          ;
           swap_bytes,byte_eq,8
          ;
          ; change exponent 11-bit 1023 bias twos comp to 8-bit 128 bias
          ;
           exponent = fix( ((byte_eq(i1) and '7F'X)*16) or $
 		           ((byte_eq(i2) and 'F0'X)/16) )
           i = where(exponent ne 0)
           if ((size(i))(0) ne 0) then exponent(i) = exponent(i) + 128 - 1022
          ;
    byte_eq(i1) = (byte_eq(i1) and '80'X) or ((exponent and 'FE'X)/2)
    byte_eq(i2) = ((exponent and '01'X)*128) or $
                  ((byte_eq(i2) and '0F'X)*8) or ((byte_eq(i3) and 'E0'X)/32)
    byte_eq(i3) = ((byte_eq(i3) and '1F'X)*8) or ((byte_eq(i4) and 'E0'X)/32)
    byte_eq(i4) = ((byte_eq(i4) and '1F'X)*8) or ((byte_eq(i5) and 'E0'X)/32)
    byte_eq(i5) = ((byte_eq(i5) and '1F'X)*8) or ((byte_eq(i6) and 'E0'X)/32)
    byte_eq(i6) = ((byte_eq(i6) and '1F'X)*8) or ((byte_eq(i7) and 'E0'X)/32)
    byte_eq(i7) = ((byte_eq(i7) and '1F'X)*8) or ((byte_eq(i8) and 'E0'X)/32)
    byte_eq(i8) = ((byte_eq(i8) and '1F'X)*8) 
          ;  
          ; swap bytes 
          ;
           swap_bytes,byte_eq,2
          ; 
          endcase  ; 5-2
          ;
       3: begin ;   VAX to SUN
          ;  
          ; swap bytes 
          ;
           swap_bytes,byte_eq,2
          ;
          ; change exponent 8-bit 128 bias to 11-bit 1023 bias twos comp
          ;
           exponent = fix( ((byte_eq(i1) and '7F'X)*2) or $
 		           ((byte_eq(i2) and '80'X)/128) )
           i = where(exponent ne 0)
           if ((size(i))(0) ne 0) then exponent(i) = exponent(i) - 128 + 1022
          ;
    byte_eq(i8) = ((byte_eq(i7) and '07'X)*32) or ((byte_eq(i8) and 'F8'X)/8)
    byte_eq(i7) = ((byte_eq(i6) and '07'X)*32) or ((byte_eq(i7) and 'F8'X)/8)
    byte_eq(i6) = ((byte_eq(i5) and '07'X)*32) or ((byte_eq(i6) and 'F8'X)/8)
    byte_eq(i5) = ((byte_eq(i4) and '07'X)*32) or ((byte_eq(i5) and 'F8'X)/8)
    byte_eq(i4) = ((byte_eq(i3) and '07'X)*32) or ((byte_eq(i4) and 'F8'X)/8)
    byte_eq(i3) = ((byte_eq(i2) and '07'X)*32) or ((byte_eq(i3) and 'F8'X)/8)
    byte_eq(i2) = ((exponent and '00F'X)*16) or ((byte_eq(i2) and '78'X)/8)
    byte_eq(i1) = (byte_eq(i1) and '80'X) or ((exponent and '7F0'X)/16)
          ; 
          endcase  ; 5-3
          ;
       4: begin ;   SUN to VAX
          ;
          ; change exponent 11-bit 1023 bias twos comp to 8-bit 128 bias
          ;
           exponent = fix( ((byte_eq(i1) and '7F'X)*16) or $
 		           ((byte_eq(i2) and 'F0'X)/16) )
           i = where(exponent ne 0)
           if ((size(i))(0) ne 0) then exponent(i) = exponent(i) + 128 - 1022
          ;
    byte_eq(i1) = (byte_eq(i1) and '80'X) or ((exponent and 'FE'X)/2)
    byte_eq(i2) = ((exponent and '01'X)*128) or $
                  ((byte_eq(i2) and '0F'X)*8) or ((byte_eq(i3) and 'E0'X)/32)
    byte_eq(i3) = ((byte_eq(i3) and '1F'X)*8) or ((byte_eq(i4) and 'E0'X)/32)
    byte_eq(i4) = ((byte_eq(i4) and '1F'X)*8) or ((byte_eq(i5) and 'E0'X)/32)
    byte_eq(i5) = ((byte_eq(i5) and '1F'X)*8) or ((byte_eq(i6) and 'E0'X)/32)
    byte_eq(i6) = ((byte_eq(i6) and '1F'X)*8) or ((byte_eq(i7) and 'E0'X)/32)
    byte_eq(i7) = ((byte_eq(i7) and '1F'X)*8) or ((byte_eq(i8) and 'E0'X)/32)
    byte_eq(i8) = ((byte_eq(i8) and '1F'X)*8) 
          ;  
          ; swap bytes 
          ;
           swap_bytes,byte_eq,2
          endcase  ; 5-4
          ;
       5: begin ;   DEC to SUN 
          ;
          ; invert byte order
          ;
           swap_bytes,byte_eq,8
          ;
          endcase  ; 5-5
          ;
       6: begin ;   SUN to DEC
          ;
          ; invert byte order
          ;
           swap_bytes,byte_eq,8
          ;
          endcase  ; 5-6
          ;
      endcase  ; cpupar
     ;
      return
     endcase  ; 5

  6: return			; complex
 ;
  7: return			; string
 ;
  8: return			; structure
 ;
  else: return			; unknown
 ;
endcase  ; vartyp
;
return
end  ; trans_bytes


