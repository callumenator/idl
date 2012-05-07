;********************************************************************
function getval,l0,zh0,missing, $
   nval=nval,noapost=noapost,helpme=helpme,nomess=nomess
nval=0
missing=1
if n_params(0) lt 2 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* Function GETVAL obtains values from FITS header'
   print,'* call: GETVAL,X,H,MISSING'
   print,'*    X: either LINE NUMBER or KEYWORD'
   print,'*    H: Header array (byte or string array)'
   print,'*    MISSING: set if keyword not found'
   print,'*'
   print,'*   KEYWORD:'
   print,'*      NOAPOST: set to remove apostrophes from strings'
   print,'*      NOMESS:  set to skip error messages if value absent'
   print,' '
   return,-1
   end
;
missing=0
l=l0 & zh=zh0
;
if (n_elements(zh) eq 1) and (n_elements(l) gt 1) then begin    ;swap arguments
   t=zh & zh=l & l=t
   endif
;
if not ifstring(zh) then begin    ;make a string array
   s=size(zh)
   ns=n_elements(s)
   if s(ns-2) ne 1 then begin
      print,' The input must either be a string or a byte array'
      missing=1
      return,-1
      endif
   if s(0) eq 1 then begin          ;one dimensional
      h=bytarr(80,n_elements(zh)/80+1)
      h(0)=zh
      zh=string(h)
      endif
   zh=string(zh)
   endif
;
s=size(l)
if ifstring(l) eq 1 then begin   ; KEYWORD string passed
   l=strupcase(l)
   kwd=strtrim(strmid(zh,0,8),2)
   i=where(kwd eq l,count)
   if count gt 0 then begin
      l=i(0)
      goto,found
      endif else if not keyword_set(nomess) then print,' Keyword ',l,' not found'
      missing=1
      return,-1
   endif     ;keyword
found:
k=zh(l)
C1=STRPOS(K,'=')
IF C1 NE -1 THEN BEGIN
   C2=STRPOS(K,' /')
   IF C2 EQ -1 THEN C2=78
   VAL=STRTRIM(STRMID(K,C1+1,C2-C1),2)
   ENDIF ELSE VAL=K
nval=1
;
if keyword_set(noapost) then begin
   k=strpos(val,"'")
   if k eq -1 then return,val           ;no apostrophes found
   if k eq 0 then val=strmid(val,1,80)     
   k=strpos(val,"'")
   if k eq -1 then return,val
   val=strtrim(strmid(val,0,k),2)
   endif     
RETURN,VAL
END
