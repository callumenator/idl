;**********************************************************************
FUNCTION gauslin,X,a,nline
; returns shape of individual line
; nline runs 1 through 5
np=n_elements(a)
if (nline le 0) or (nline gt (np-3)/3) then return,0.
l=nline*3
k=l+1
J=K+1
T=((X-A(K))/A(J)*2.)<18.
CL=A(L)*EXP(-T*T/2.)
RETURN,cl
END

