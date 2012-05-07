
function coord3to2, p, data=data, device=device, normal=normal

;@compile_opt.pro        ; On error, return to caller


data   = keyword_set(data)
normal = keyword_set(normal) and not data
device = keyword_set(device) and not (data or normal)
if data+normal+device eq 0 then data = 1B

n = (where([data,normal,device]))[0]

szp = size(p)

q = reform(p,szp[1],szp[szp[0]+2]/szp[1])       ; Reform to [3,*] array
                                                ; Convert to normal coordinates
if not normal then q = convert_coord(q, data=data, device=device , /to_normal, /t3d)

; convert_coord turns an array[3,1] into an array[3] (drops trailing dimension of 1)
; so we have to check for his explicitly.

sz = size(q)
if sz[0] eq 1 then  $
    q = [q,1]       $
else                $
    q = [q,[replicate(1,1,sz[2])]]              ; Convert from [3,*] to [4,*]

; This seems to work without needing the convert_coord calls???????
; q= invert(!p.t)#q

q = transpose(transpose(q)#!p.t)                ; Get 2D position

q = q[0:2,*]
                                                ; Convert back to input coordinates
if not normal then q = convert_coord(q, /normal, to_data=data, to_device=device , /t3d)

SyncDims, q, sizeinfo=szp

return, q
end

