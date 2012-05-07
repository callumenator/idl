;*****************************************************************************
;+
;
;*NAME:
;
;    SWAP_BYTES     (General IDL Library 01)  25-APR-80
;
;*CLASS:
;
;    Conversion
;
;*CATEGORY:
;
;*PURPOSE:
;
;    To perform the byte reordering required for conversion of 
;    integer, longword, floating point, or double precision 
;    variables between various machine representations.
;
;*CALLING SEQUENCE: 
;
;    SWAP_BYTES,BVAR,PARAM
; 
;*PARAMETERS: 
;
;    BVAR   (REQ) (I/O) (0 1) (B) 
;            byte representation of variable in which bytes will 
;            be reordered 
;
;    PARAM  (REQ) (I/O) (0)   (I)
;            parameter governing the byte reordering options
;             
;            2: Even and Odd bytes are swapped
;    
;            4: The order of each group of four bytes is reversed
;
;            8: The order of each group of eight bytes is reversed  
;
;*EXAMPLES:
;
;*SUBROUTINES CALLED:
;
;    PARCHECK
;
;*FILES USED:
;
;*SIDE EFFECTS:
;
;    The byte representation of the original vector or scalar is 
;    replaced by the reordered bytes
;
;*RESTRICTIONS:
;
;    Input must be of byte type. All conversion operations should
;    be done on the byte stream BEFORE the variables are read by
;    IDL as integer, longword, floating point, or double precision.
;    Prematurely reading a byte stream as one of these data types
;    can cause conflicts with reserved values (NaN, infinity, and
;    reserved operand faults ) which will corrupt the final data.
;
;*NOTES:
;   
;    tested with IDL Version 2.0.10  (sunos sparc)     3 Oct 91
;    tested with IDL Version 2.1.0   (ultrix mipsel)   3 Oct 91
;    tested with IDL Version 2.1.0   (vms vax)         3 Oct 91
; 
;*PROCEDURE:
;
;    Three different byte reordering schemes are required for the
;    conversion of integer, longword, floating point, and double
;    precision data between the machine formats used by SunOS, 
;    DEC ULTRIX, and VAX VMS. All conversions require the 
;    interchange of even and odd byte elements. Longword and
;    floating point conversion requires an additional byte reordering
;    in which the order of the four bytes which represent a single 
;    longword or floating point value are reversed. Double precision
;    conversion requires that the order of the eight bytes which 
;    represent a double precision value are reversed.
;    
;*MODIFICATION HISTORY:
;
;    Apr. 25 1980 D.J. Lindler   initial program
;    Mar. 21 1988 CAG add VAX RDAF-style prolog, add procedure
;                     call listing, and check for parameters.
;    Feb. 09 1988 RWT change suggested by D. Lindler to handle
;                     longword integers
;    Jun. 14 1989 RWT modify for SUN IDL, add optional parameter,
;                     and allow swapping of bytes in a byte array
;    May 30 1990  RWT add changes by Gitta Domik for allowing 
;                     TYPE = 8.
;    Feb 11 1991  GRA Changed name to SWAP_BYTES, and rewrote to
;                     work with byte variable types only. 
;                     Removed call to PARCHECK, and required that
;                     PARAM be defined, rather that determined by
;                     the IDL function SIZE. Changed the values of
;                     PARAM to equal the number of bytes considered
;                     as a group, i.e. 2, 4, and 8.
;    Mar 28 1991  PJL added PARCHECK; converted to lowercase
;    Jun 21 1991  GRA cleaned up; tested on SUN, DEC, VAX;
;                     updated prolog.
;    Aug 15 1991  A.Veale converted to use IDL BYTEORDER calls; tested
;                     on DEC
;    Oct  3 1991  GRA tested on SUN, DEC, and VAX.
;
;-
;*****************************************************************************
 pro swap_bytes,bvar,param
;
 npar = n_params(0)
 if npar eq 0 then begin
    print,'SWAP_BYTES,BVAR,PARAM'
    retall
 endif  ; npar
 parcheck,npar,2,'SWAP_BYTES'
;
 case param of 
;
    2 : begin  ; byte
          byteorder,bvar,/sswap
        endcase  ; 2
;
    4 : begin  ; swap bytes for 4 consecutive bytes
          byteorder,bvar,/lswap
        endcase  ; 4
;
    8 : begin  ; swap bytes for 8 consecutive bytes
	   npt = n_elements(bvar)
	   if npt gt 1 then begin
	      nd2  = npt / 4l
	      tmp  = bytarr(4,nd2)
              tmp(0) = bvar(*)
	      byteorder,tmp,/lswap
	      tmp = transpose(tmp)
	      byteorder,tmp,/sswap
	      tmp = transpose(tmp)
	      bvar(0) = tmp(*)
           endif  ; npt
        endcase  ; 8
;
    else : return
 endcase  ; param
;
 return
 end  ; swap_bytes
