;+
; NAME:
;       SCALE_VECTOR
;
; PURPOSE:
;
;       This is a utility routine to scale the points of a vector
;       (or an array) into a given data range. The minimum value of
;       the vector (or array) is set equal to the minimun data range. And
;       the maximun value of the vector (or array) is set equal to the
;       maximun data range.
;
; AUTHOR:
;
;       FANNING SOFTWARE CONSULTING
;       David Fanning, Ph.D.
;       2642 Bradbury Court
;       Fort Collins, CO 80521 USA
;       Phone: 970-221-0438
;       E-mail: davidf@dfanning.com
;       Coyote's Guide to IDL Programming: http://www.dfanning.com
;
; CATEGORY:

;       Utilities
;
; CALLING SEQUENCE:
;       scaledVector = SCALE_VECTOR(vector, minRange, maxRange)
;
; INPUTS:
;       vector:   The vector (or array) to be scaled.
;       minRange: The minimun value of the scaled vector. Set to 0 by default.
;       maxRange: The maximun value of the scaled vector. Set to 1 by default.
;;
; RETURN VALUE:
;       scaledVector: The vector (or array) values scaled into the data range.
;           This is always at least a FLOAT value.
;
; COMMON BLOCKS:
;       None.
;
; EXAMPLE:
;       x = [3, 5, 0, 10]
;       xscaled = SCALE_VECTOR(x, -50, 50)
;       Print, xscaled
;          -20.0000     0.000000     -50.0000      50.0000
;
;
; MODIFICATION HISTORY:
;       Written by:  David Fanning, 12 Dec 98.
;-

FUNCTION Scale_Vector, vector, minRange, maxRange

On_Error, 1

CASE N_Params() OF
   0: Message, 'Incorrect number of arguments.'
   1: BEGIN
      minRange = 0.0
      maxRange = 1.0
      ENDCASE
   2: BEGIN
      maxRange = 1.0 > (minRange + 0.0001)
      ENDCASE
   3:
ENDCASE

minRange = Float( minRange )
maxRange = Float( maxRange )

IF maxRange LT minRange THEN Message, 'Error -- maxRange LT minRange'

vectorMin = Float( Min(vector) )
vectorMax = Float( Max(vector) )

scaleFactor = [((minRange * vectorMax)-(maxRange * vectorMin)) / $
    (vectorMax-vectorMin), (maxRange - minRange) / (vectorMax - vectorMin)]

RETURN, vector * scaleFactor[1] + scaleFactor[0]

END
;-------------------------------------------------------------------------
