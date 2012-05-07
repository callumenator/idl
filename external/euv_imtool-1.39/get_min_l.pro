
function l_, ro2, s, ro, no
Epsilon = 10.0 ^ (-5)
r2 = ro2 + s ^ 2.0D
z = ro[2] + s * no[2]
d = r2 - z ^ 2.0D
if(abs(d) lt Epsilon or d lt 0.0) then return, (10.0D) ^ 5
return, (r2 ^ (1.5D)) / (r2 - z ^ (2.0D))
end

function get_min_L, org, dir, rp
  MaxPathLen = 50.0D
  Epsilon = 1.0D ^ (-5)

  root = dblarr(3)
  no = dblarr(3)
  ro = dblarr(3)

  ns = 0.0D
  si = 0.0D
  ro2 = 0.0D

  for k = 0, 2 do begin
      ns = ns + dir[k] ^ 2.0D
      si = si + dir[k] * org[k]
  endfor

  ns = ns ^ (0.5D)
  si = si / ns;

  for k = 0, 2 do begin
      no[k] = dir[k] / ns
      ro[k] = org[k] - si * no[k]
      ro2 = ro2 + ro[k] ^ 2.0D
  endfor

  nz = no[2]
  zo = ro[2]
  c3 = 1.0 - nz ^ 2.0D
  c2 = -4.0D * zo * nz
  c1 = ro2 - 3.0D * (zo ^ (2.0D)) + 2.0 * ro2 * (nz ^ (2.0D))
  c0 = 2.0D * ro2 * zo * nz
  if ro2 gt 1.0 then $
    sf = MaxPathLen $
  else if si lt 0.0 then $
    sf = -((1.0 - ro2) ^ (0.5D)) $
  else $
    sf = MaxPathLen

  if ro2 lt Epsilon then begin
      if si gt 0.0 then $
        minS = si $
      else $
        minS = sf
      minL = L_( ro2, minS, ro, no )
  endif else if (abs(c3) lt Epsilon) then begin
      if si gt 0.0 then $
          minS = si $
      else if ro2 gt 1.0 then $
          minS = 0.0 $
      else $
          minS = sf
      minL = L_( ro2, minS, ro, no )
  endif else begin
      Li = L_( ro2, si, ro, no )
      Lf = L_( ro2, sf, ro, no )
      if Li lt Lf then begin
        minS = si
        minL = Li     
      endif else begin
	minS = sf
        minL = Lf
      endelse
    endelse
    root = cuberoot([c0/c3, c1/c3, c2/c3, 1])
    cnt = n_elements(where(root gt -1 * (10.0D)^29))
    for k = 0, cnt - 1 do begin
        s = root[k]        
        if not (s lt si or s gt sf) then begin
            r2 = ro2 + s ^ 2
            if not (r2 lt 1.0) then begin
                L = L_(ro2, s, ro, no)
                if (not (L lt 1.0)) and (L lt minL) then begin
                    minS = s
                    minL = L
                endif
            endif
        endif
    endfor  

    px = ro[0] + minS * no[0]
    py = ro[1] + minS * no[1]
    pz = ro[2] + minS * no[2]

    return, [minL, px, py, pz]
end
