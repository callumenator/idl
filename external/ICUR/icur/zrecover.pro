;*************************************************************************
pro zrecover,dum               ; solve cursor timing problem
common comxy,xcur,ycur,zerr
xcur=100
ycur=100
zerr=32
PRINT,' '
TYPE_AHEAD=GET_KBRD(0)
WHILE TYPE_AHEAD NE '' DO TYPE_AHEAD=GET_KBRD(0)
return
end
