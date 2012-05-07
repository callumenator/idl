;Accept a three-dimensional data coordinate, 
;return a two-element vector containing the coordinate transformed 
;to two-dimensional normalized coordinates using the current transformation matrix.


FUNCTION CVT_TO_2D, X, Y, Z	
P = [!X.S[0] + !X.S[1] * X, !Y.S[0] + !Y.S[1] * Y, $
!Z.S[0] + !Z.S[1] * Z, 1]	
P = P # !P.T	;Transform by !P.T.
d2d = [P[0] / P[3], P[1] / P[3]]
if keyword_set(to_device) then d2d = convert_coord(d2d, /normal, /to_device)
RETURN, d2d	;Return the scaled result as a two-element, 2d vector
end