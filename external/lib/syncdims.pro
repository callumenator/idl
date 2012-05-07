pro SyncDims, A, sizeinfo = SizeInfo, extendinfo=ExtendInfo, replicateinfo=ReplicateInfo

;@compile_opt.pro        ; On error, return to caller


IF n_elements(SizeInfo) NE 0 THEN BEGIN
    S = SizeInfo
    nS = S[S[0]+2]
    nA = n_elements(A)
    IF nS GT nA THEN        $   ; Sizeinfo array too big
        message, 'Inconsistent input array structures'  $
    ELSE IF nS LT nA THEN   $   ; Truncate A to fit SizeInfo array
        A = A[0:nS-1]

    IF S[0] EQ 0 THEN $         ; Scalar
        A = A[0]    $

    ELSE BEGIN                  ; Array
        IF S[S[0]+2] EQ 1 THEN A = replicate(A[0], 1)
        A = reform(A, S[1:S[0]], /overwrite)

    ENDELSE
ENDIF

IF n_elements(ExtendInfo) NE 0 THEN BEGIN
    S = ExtendInfo

    IF S[S[0]+2] GT n_elements(A) THEN message, 'Inconsistent input array structures

    IF S[0] eq 0 then begin     ; Extension of scalar
        X = size(A)             ; ... remove leading dim of 1
        X = [X[0]-1,X[2:*]]     ; X[1]=1
        A = reform(A,X[1:X[0]], /overwrite)
    ENDIF

ENDIF

IF n_elements(ReplicateInfo) NE 0 THEN BEGIN
    n = n_elements(ReplicateInfo)

    i = 0
    WHILE i LT n AND n_elements(S) EQ 0 DO BEGIN
        d = ReplicateInfo[i]+3                  ; Length size vector
        IF ReplicateInfo[i] NE 0 THEN S = ReplicateInfo[i:i+d-1]
        i = i+d                                 ; Find first array
    ENDWHILE

    WHILE i LT n DO BEGIN
        d = ReplicateInfo[i]+3                  ; Length next size vector
        IF ReplicateInfo[i] GT 0 THEN BEGIN             ; Add dimensions
            S = [ S[0:S[0]],ReplicateInfo[i+1:i+ReplicateInfo[i]],S[S[0]+1:S[0]+2] ]
            S[0] = S[0]+ReplicateInfo[i]                ; Update # dimensions
            S[S[0]+2] = S[S[0]+2]*ReplicateInfo[i+d-1]  ; Update # elements
        ENDIF
        i = i+d
    ENDWHILE

    IF n_elements(S) ne 0 then A = S else A = 0B

ENDIF

RETURN  &  END