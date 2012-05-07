;**********************************************************************
pro gc,k,rr,gg,bb,helpme=helpme,full=full,stp=stp
common tvcoltab,r,g,b,opcol,ctnum
common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
; plot axes and main color use element 250 of color vector
if n_params(0) eq 0 then helpme=1
if keyword_set(helpme) then begin
   print,' '
   print,'* GC - generate and load color table'
   print,'*   calling sequence: GC,ID,R,G,B'
   print,'*      ID: GC color table (0-11)'
   print,'*   R,G,B: optional output color vectors sent to TVLCT'
   print,'*   type GC,-1 for description of color tables.'
   print,'*   color tables are not loaded if R,G,B are returned'
   print,'*'
   print,'* k=0: 2-tone'
   print,'* k=1:  Black and white'
   print,'* K=2:    Compressed scale, saturated at 50'
   print,'* k=3-5:  Stepped distributions.'
   print,'* K=6,7:  Standard colors'
   print,'* k=8-10: Red/Brown (Halloween)'
   print,'* k=11: 5-red 15-yellow 25-violet 35-aqua 45-blue 55-green'
   print,'*       65-orange 75-puce 85-lime 95-lt. blue 105-gray 115-black'
   print,'*       value corresponds to c2 in ICUR common icurunits'
   print,'* k=12:    Red -> B/W'
   print,'* k=13: 0-black 1-yellow 2-violet 3-aqua 4-blue 5-green'
   print,'*       6-orange 7-puce 8-lime 9-lt. blue 10 - red 11-gray 12-black'
   print,'* k=14: 0-black 1-red 2-green 3-blue 4-yellow 5-white'
   print,'*       6-orange 7-cyan    '   ; Black,R,G,B,Y,White,Orange,Cyan
   print,'* k=15: 0-black 1-yellow 2-violet 3-aqua 4-blue 5-green'
   print,'*       6 up = gray'
   print,'* k=16: 0-black 1-yellow 2-violet 3-aqua 4-blue 5-green'
   print,'*       6 up = gc,9'
   print,'* k=20-23: HLS, R,G,B,2x'
   print,'* k=30-33: HSV, R,G,B,2x'
   print,'* k=40: yellow
;   print,'* k=60: k=6 k=11 (0-9)
   print,'* k<0 for inverse'
   print,'* k=100-115 = loadct(k-100)'
   print,' '
   return
   endif
;
; hex translations:    ct=13
      ;red:    ff0000  (10)
      ;yellow: ffff00  (1)
      ;purple: ff00ff  (2)
      ; aqua:  00ffff  (3)
      ;blue:   0000ff  (4)
      ;green:  00ff00  (5)
      ;orange  ff7f00  (6)
      ;puce    ff007f  (7)
      ;lime    7fff00  (8)
      ;lt.blue 007fff  (9)
      ;gray    7F7f7f  ( )
;
maxcol=256                                        ;pseudo-colors
if (k ge 100) and (k le 115) then begin          ;standard color tables
   loadct,k-100
   r=r_curr & g=g_curr & b=b_curr
   return
   endif
;
cta=k 
mz=248<!d.n_colors               ;color vector length - was 249
if keyword_set(full) then mz=256
opcol=mz-1
ro=255 & go=0 & bo=0
mz1=mz-1
reslen=256-mz1        ;length of reserved vector; mz+reslen=256
z=fix(findgen(mz)*255./mz)<255
y=intarr(mz1)
s64=64-reslen+1
s128=128-reslen+1
if k lt 0 then begin
   irev=1
   k=abs(k)
   endif else irev=0
if (k eq 11) and (!d.n_colors le 120) then k=0
case 1 of
   k eq 0: begin   ;two tone
      g=[0,255+intarr(maxcol)]
      r=[0,255+intarr(maxcol)]
      b=[0,255+intarr(maxcol)]
      end
   k eq 1: begin   ;bw
      g=z
      r=z
      b=z
      end
   k eq 2: begin
      b=[0,129+indgen(13),reverse(20*indgen(13)),255+intarr(mz-27)]<255
      g=[intarr(6),20*indgen(13),reverse(40*indgen(6)),255+intarr(mz-25)]<255
      r=10*[z,1]<255
      r(opcol)=255 & g(opcol)=0 & b(opcol)=0
      end
    k eq 3: begin
      g=[2*indgen(128),intarr(s128)]
      b=[intarr(64),2*indgen(128),intarr(s64)]
      r=[intarr(128),2*indgen(s128)]
      r(opcol)=255 & g(opcol)=255 & b(opcol)=0
      end
    k eq 4: begin
      b=[2*indgen(128),intarr(s128)]
      g=[intarr(64),2*indgen(128),intarr(s64)]
      r=[intarr(128),2*indgen(s128)]
      r(opcol)=255 & g(opcol)=255 & b(opcol)=255
      end
    k eq 5: begin
      b=[2*indgen(128),reverse(2*indgen(s128))]
      g=[intarr(64),2*indgen(128),reverse(2*indgen(s64))]
      r=[intarr(128),2*indgen(s128)]
      r(opcol)=255 & g(opcol)=255 & b(opcol)=255
      end
    k eq 6: begin
      b=[4*indgen(64),reverse(2*indgen(128)),intarr(s64)]
      g=[2*indgen(128),reverse(2*indgen(s128))]
      r=[intarr(128),2*indgen(s128)]
      r(opcol)=255 & g(opcol)=255 & b(opcol)=255
      end
   k eq 7: begin
      b=[0,129+indgen(127),reverse(2*indgen(s128))]
      g=[intarr(64),2*indgen(128),reverse(4*indgen(s64))]
      r=[z,1]
      r(opcol)=255 & g(opcol)=255 & b(opcol)=255
      end
   k eq 8: begin
      b=[y,1]
      r=[255-reverse(z)/2,1]
      g=[z,1]
      r(0)=0
      r(opcol)=255 & g(opcol)=255 & b(opcol)=255
      end
   k eq 9: begin     ;best yet
      b=[intarr(192),indgen(s64)*4]
      r=[255-reverse(z)/1.6,1]
      g=[z,1]
      r(0)=0
      r(opcol)=0 & g(opcol)=255 & b(opcol)=255
      end
   k eq 10: begin    ;Halloween colors
      g0=50 & r0=200
      g=[g0+z*(mz-1.-g0)/(mz-1.),1]
      r=[r0+z*(mz-1.-r0)/(mz-1.),1]
      g(0)=0
      r(0)=0
      b=[intarr(192),indgen(s64)*4]
      r(opcol)=0 & g(opcol)=255 & b(opcol)=255
      end
   k eq 11: begin
      ; 1-10:red  11-20:yellow  21-30:violet   31-40: aqua  41:50 blue
      ;51-60 green  61-70: orange  71-80: puce  81-90: lime  91:100: lt. blue
      ;101-110: gray   111-!d.n_colors-1: black   !d.ncolors-255: white
      r=[z,1]
      r(1:30)=255
      r(31:60)=0
      r(61:80)=255
      r(81:90)=127
      r(91:100)=0
      r(101:110)=127           ;grey
      r(111:120<(maxcol-1))=0             ;black
      g=[z,1]
      g(1:10)=0
      g(11:20)=255
      g(21:30)=0
      g(31:40)=255
      g(41:50)=0
      g(51:60)=255
      g(61:70)=127
      g(71:80)=0
      g(81:90)=255
      g(91:110)=127
      g(111:120<(maxcol-1))=0
      b=[z,1]
      b(1:20)=0
      b(21:50)=255
      b(51:70)=0
      b(71:80)=127
      b(81:90)=0
      b(91:100)=255
      b(101:110)=127
      b(111:120<(maxcol-1))=0
      r(0)=0 & g(0)=0 & b(0)=0                 ;black
;      r(175<(mz1-1))=255 & g(175<(mz1-1))=255 & b(175<(mz1-1))=255   
                                  ;fudge because CDA viewer changes !d.n_colors
      r(opcol)=255 & g(opcol)=255 & b(opcol)=255
      end
   k eq 12: begin   ;kgd1 default
      r=[y,0]+255
      r(0)=0
      b=[z,1]
      g=b
      b(0:80)=0
      r(opcol)=0 & g(opcol)=0 & b(opcol)=255
      end
   k eq 13: begin
      ; 0:black  1:yellow  2:violet   3: aqua  4: blue
      ;5: green  6: orange  7: puce  8: lime  9: lt. blue
      ;10: red   11: black
      ; rest - scheme 6
      r=[  0,255,255,  0,  0,  0,255,255,127,  0,255,127]
      g=[  0,255,  0,255,  0,255,127,  0,255,127,  0,127]
      b=[  0,  0,255,255,255,  0,  0,127,  0,255,  0,127]
      l=(mz1-n_elements(r))/4+1
      b=[b,4*indgen(l),reverse(2*indgen(l*2)),intarr(l)]
      g=[g,2*indgen(l*2),reverse(2*indgen(l*2))]
      r=[r,intarr(l*2),2*indgen(l*2)]
;      r(175<(mz1-1))=255 & g(175<(mz1-1))=255 & b(175<(mz1-1))=255   
                                  ;fudge because CDA viewer changes !d.n_colors
      r(opcol)=255 & g(opcol)=255 & b(opcol)=255
      end
   k eq 14: begin
   ; 0-black 1-red 2-green 3-blue 4-yellow 5-white 6-orange 7-cyan

      ; 0:black  1:yellow  2:violet   3: aqua  4: blue
      ;5: green  6: orange  7: puce  8: lime  9: lt. blue
      ; rest - scheme 6

      r=[  0,255,  0,  0,255,255,255,127]  ; 255,  0,255,127,  0]
      g=[  0,  0,255,  0,255,255,127,255]  ;   0,255,  0,255,127]
      b=[  0,  0,  0,255,  0,255,  0,  0]  ; 255,255,127,  0,255]
;                                             v  aq   pu  li  lb  
      l=(mz1-n_elements(r))/4+1
      b=[b,4*indgen(l),reverse(2*indgen(l*2)),intarr(l)]
      g=[g,2*indgen(l*2),reverse(2*indgen(l*2))]
      r=[r,intarr(l*2),2*indgen(l*2)]
;      r(175<(mz1-1))=255 & g(175<(mz1-1))=255 & b(175<(mz1-1))=255   
                                  ;fudge because CDA viewer changes !d.n_colors
      r(opcol)=255 & g(opcol)=255 & b(opcol)=255
      end
;      b=[4*indgen(64),reverse(2*indgen(128)),intarr(s64)]
;      g=[2*indgen(128),reverse(2*indgen(s128))]
;      r=[intarr(128),2*indgen(s128)]
   k eq 15: begin   ;bw
      g=z
      r=z
      b=z
      ; 0:black  1:yellow  2:violet   3: aqua  4: blue   5: green  6: gray
      r(0)=[  0,255,255,  0,  0,  0]
      g(0)=[  0,255,  0,255,  0,255]
      b(0)=[  0,  0,255,255,255,  0]
      end
;
   k eq 16: begin     ;best yet
      b=[intarr(192),indgen(s64)*4]
      r=[255-reverse(z)/1.6,1]
      g=[z,1]
      r(opcol)=0 & g(opcol)=255 & b(opcol)=255
      ; 0:black  1:yellow  2:violet   3: aqua  4: blue   5: green  6: gray
      r(0)=[  0,255,255,  0,  0,  0]
      g(0)=[  0,255,  0,255,  0,255]
      b(0)=[  0,  0,255,255,255,  0]
      end
;
   k eq 20: begin
      hls,0,100,0,100,0,0,clr
      r=clr(0:mz1,0) & g=clr(0:mz1,1) & b=clr(0:mz1,2)
      end
   k eq 21: begin
      hls,0,100,0,100,120,0,clr
      r=clr(0:mz1,0) & g=clr(0:mz1,1) & b=clr(0:mz1,2)
      end
   k eq 22: begin
      hls,0,100,0,100,240,0,clr
      r=clr(0:mz1,0) & g=clr(0:mz1,1) & b=clr(0:mz1,2)
      end
   k eq 23: begin
      hls,0,100,0,100,0,2,clr
      r=clr(0:mz1,0) & g=clr(0:mz1,1) & b=clr(0:mz1,2)
      end
   k eq 30: begin
      hsv,0,100,0,100,0,0,clr
      r=clr(0:mz1,0) & g=clr(0:mz1,1) & b=clr(0:mz1,2)
      end
   k eq 31: begin
      hsv,0,100,0,100,120,0,clr
      r=clr(0:mz1,0) & g=clr(0:mz1,1) & b=clr(0:mz1,2)
      end
   k eq 32: begin
      hsv,0,100,0,100,240,0,clr
      r=clr(0:mz1,0) & g=clr(0:mz1,1) & b=clr(0:mz1,2)
      end
   k eq 33: begin
      hsv,0,100,0,100,0,2,clr
      r=clr(0:mz1,0) & g=clr(0:mz1,1) & b=clr(0:mz1,2)
      end
   k eq 41: begin               ;yellow
      r=indgen(256) & g=indgen(256) & b=r*0
      end
   k eq 42: begin               ;violet
      r=indgen(256) & b=indgen(256) & g=r*0
      end
   k eq 43: begin               ;aqua
      b=indgen(256) & g=indgen(256) & r=b*0
      end
   k eq 44: begin               ;blue
      b=indgen(256) & r=b*0 & g=r
      end
   k eq 45: begin               ;green
      g=indgen(256) & b=g*0 & r=b
      end
   k eq 46: begin               ;orange
      r=indgen(256) & g=r/2 & b=r*0
      end
   k eq 47: begin               ;puce
      r=indgen(256) & b=r/2. & g=r*0
      end
   k eq 48: begin               ;lime
      g=indgen(256) & r=g/2 & b=r*0
      end
   k eq 49: begin               ;lt. blue
      b=indgen(256) & g=b/2 & r=b*0
      end
    k eq 60: begin
      b=[4*indgen(64),reverse(2*indgen(128)),intarr(s64)]
      g=[2*indgen(128),reverse(2*indgen(s128))]
      r=[intarr(128),2*indgen(s128)]
      end
   k eq 99: begin
      read,' enter r0,g0',r0,g0
      g=g0+fix(z*float(mz1-g0)/mz1)
      r=r0+fix(z*float(mz1-r0)/mz1)
      g(0)=0
      r(0)=0
      b=[intarr(192),indgen(s64)*4]
      end
   k eq 100: begin
      r=z
      zz=[0,255,0,0,255,255,200,0]
      r(0)=zz
      g=z
      zz=[0,0,255,0,255,255,50,255]
      g(0)=zz
      b=z
      zz=[0,0,0,255,0,255,0,255]
      b(0)=zz
      end
   k eq 101: begin     ;9+100
      b=[intarr(192),indgen(s64)*4]
      g=z
      r=255-reverse(g)/1.6
      zz=[0,255,0,0,255,255,200,0]
      r(0)=zz
      zz=[0,0,255,0,255,255,50,255]
      g(0)=zz
      zz=[0,0,0,255,0,255,0,255]
      b(0)=zz
      end
   else: begin   ;bw
      g=z
      r=z
      b=z
      end
   endcase
if irev eq 1 then begin
   r=reverse(r)
   g=reverse(g)
   b=reverse(b)
   savcol0=0
   endif else savcol0=255
if reslen gt 0 then begin
   savcol=intarr(reslen)+savcol0    ;elements 250-255 are white
   r=fix([r,savcol])
   g=fix([g,savcol])
   b=fix([b,savcol])
   endif
if k eq 60 then begin
   yellow=250
   r(yellow)=255 & g(yellow)=255 & b(yellow)=0
   violet=251
   r(violet)=255 & g(violet)=0 & b(violet)=255
   aqua=252
   r(aqua)=0 & g(aqua)=255 & b(aqua)=255
   lime=253
   r(lime)=127 & g(lime)=255 & b(lime)=0
;      r=[255,255,255,  0,  0,  0,255,255,127,  0,127]
;      g=[  0,255,  0,255,  0,255,127,  0,255,127,127]
;      b=[  0,  0,255,255,255,  0,  0,127,  0,255,127]
      ; 0:red  1:yellow  2:violet   3: aqua  4 blue
      ;5 green  6: orange  7: puce  8: lime  9: lt. blue
   endif
if n_elements(r) gt 256 then r=r(0:255) 
if n_elements(g) gt 256 then g=g(0:255) 
if n_elements(b) gt 256 then b=b(0:255) 
if n_params(0) eq 1 then tvlct,r,g,b else begin
   rr=r & gg=g & bb=b
   endelse
ctnum=cta
if keyword_set(stp) then stop,'GC>>>'
return
end
