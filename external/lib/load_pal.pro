;=======================================================================
;
; This is a long-winded routine that makes a really nice rainbow palette:
;

  pro MARKS_PALETTE

  if !d.table_size lt 4 then device,pseudo_color=8
  pcnt = 20
  loadct,13, /silent
  tvlct, r,g,b, /get
  r = float(r)
  g = float(g)
  b = float(b)

  alo =  30.*!d.table_size/240
  ahi = 135.*!d.table_size/240
  blo = 160.*!d.table_size/240
  bhi = 192.*!d.table_size/240
  clo = 185.*!d.table_size/240


       rr = [r(alo:ahi), r(blo:bhi), r(clo:*)]
       gg = [g(alo:ahi), g(blo:bhi), g(clo:*)]
       bb = [b(alo:ahi), b(blo:bhi), b(clo:*)]
       rr = congrid(rr, n_elements(r))
       gg = congrid(gg, n_elements(g))
       bb = congrid(bb, n_elements(b))

;      Setup the "rainbow" colours:
       rbwmin = 0
       rbwmax = n_elements(r) - 1
       satval = 255.
       step = satval/(1 + rbwmax - rbwmin)
       rgbw = float(rbwmax - rbwmin)
       rw   = rgbw/0.9
       gw   = rgbw/3.8
       bw   = rgbw/1.8
       rp   = 1.4*rgbw
       gp   = 0.5*rgbw
       bp   = 0.18*rgbw
       i = findgen (rbwmax - rbwmin + 1)
       r(rbwmin:rbwmax) = exp(-((i-rp)/rw)^2)
       g(rbwmin:rbwmax) = exp(-((i-gp)/gw)^2)
       b(rbwmin:rbwmax) = exp(-((i-bp)/bw)^2)
       g(gp:gp+gw/2) = 1
       g(gp+gw/2:rbwmax) = exp(-((i(gp+gw/2:rbwmax)-(gp+gw/2))/(0.9*gw))^2)
       r = satval*r/max(r)
       g = satval*g/max(g)
       b = satval*b/max(b)

       wgt = findgen(n_elements(r))/n_elements(r)
       r = (0.5*r + r*(1-wgt) + 0.5*rr + rr*wgt)/2
       g = (0.5*g + g*(1-wgt) + 0.5*gg + gg*wgt)/2
       b = (0.5*b + b*(1-wgt) + 0.5*bb + bb*wgt)/2
       r = smooth(r, 15)
       g = smooth(g, 15)
       b = smooth(b, 15)

       range = fix(rgbw*(pcnt/100.))
       coeff = sqrt((findgen(range)/range))
       r(1:range-1) = r(1:range-1)*coeff(1:range-1)
       g(1:range-1) = g(1:range-1)*coeff(1:range-1)
       b(1:range-1) = b(1:range-1)*coeff(1:range-1)

       r(0) = 0
       g(0) = 0
       b(0) = 0
       r(n_elements(r)-1) = 255
       g(n_elements(r)-1) = 255
       b(n_elements(r)-1) = 255
       tvlct, r, g, b

end

pro pal_subsamp, idxlo, idxhi, sred, sgrn, sblu, brt, satval, sign

  tvlct, r,g,b, /get
  r = brt*r
  g = brt*g
  b = brt*b
  if sign lt 0 then begin
     r = reverse(r)
  g = reverse(g)
  b = reverse(b)
  endif

  sred = congrid(r, 1 + idxhi - idxlo)
  sgrn = congrid(g, 1 + idxhi - idxlo)
  sblu = congrid(b, 1 + idxhi - idxlo)

  nsat = 0
  satz = where(sred gt satval, nsat)
  if nsat gt 0 then sred(satz) = satval
  satz = where(sgrn gt satval, nsat)
  if nsat gt 0 then sgrn(satz) = satval
  satz = where(sblu gt satval, nsat)
  if nsat gt 0 then sblu(satz) = satval
end


;========================================================================
;
;  Setup a nice palette for superimposing the data sets.  The palette has
;  3 parts: 16 predefined "system" colors, a greyscale section, and a
;  color section.  The color section is derived from "marks_palette" by
;  default.  However, it can be derived from one of the IDL tables, simply
;  by setting the IDL_TABLE keyword to the appropriate IDL color table
;  number.  CULZ is a structure returned by this routine.  It contains
;  pointers to the various parts of the color table.  See the code below for details.
;
;  Mark Conde, Kingston, September 1998.
;

pro load_pal, culz, idl_table=itbl, bright=brt, proportion=prp

if not(keyword_set(prp))  then prp=0.66
if not(keyword_set(brt))  then brt=1
if not(keyword_set(itbl)) then itbl=[9999, 0]
brt = float(brt)

;  Create the colors pointer structure:
culz   = {s_cul, sysculz: 21, $
                 black:      0, $
                 bground:    0, $
                 red:        0, $
                 green:      0, $
                 blue:       0, $
                 yellow:     0, $
                 orange:     0, $
                 purple:     0, $
                 cyan:       0, $
                 lilac:      0, $
                 rose:       0, $
                 slate:      0, $
                 chocolate:  0, $
                 olive:      0, $
                 wheat:      0, $
                 ash:        0, $
                 white:      0, $
                 fill_1:     0, $
                 fill_2:     0, $
                 arrows:     0, $
                 text:       0, $
                 imgmin:     0, $
                 imgmax:     0, $
                 greymin:    0, $
                 greymax:    0, $
                 user_editable: 1}
; Define the color value corresponding to saturation, and also the number
; of reserved "system" colors:
  satval = 255
  culz.sysculz = 17
  tvlct, r,g,b, /get

  ncl = !d.table_size < n_elements(r)
  culz.imgmin  = culz.sysculz
  culz.imgmax  = culz.imgmin + prp*(ncl - culz.sysculz)
  culz.greymin = culz.imgmax + 1
  culz.greymax = ncl - 1

; Setup the image palette.  First, make a full palette, then sample it down
; to a smaller number of colors - to make room for greyscale and "system" colors:
; Also define the index values corresponding to min,max color table entries for
; rainbow and greyscale colors:
  if keyword_set(itbl) and abs(itbl(0)) lt 1000 then begin
     loadct, abs(fix(itbl(0))), /silent
  endif else begin
     marks_palette
  endelse
  pal_subsamp, culz.imgmin, culz.imgmax, rbwr, rbwg, rbwb, brt(0), satval, itbl(0)

; Setup the greyscale colours:
  if n_elements(itbl) gt 1 then begin
     loadct, abs(itbl(1)), /silent
  if n_elements(brt) gt 1 then brt1=brt(1) else brt1=brt(0)
     pal_subsamp, culz.greymin, culz.greymax, greyr, greyg, greyb, brt1, satval, itbl(1)
endif else begin
     i     = indgen(1 + culz.greymax - culz.greymin)
     step  = 0.96*satval/(1. + culz.greymax - culz.greymin)
     greyr = i*step
     greyg = i*step
     greyb = i*step
  endelse
  
  r = [intarr(16), rbwr, greyr]
  g = [intarr(16), rbwg, greyg]
  b = [intarr(16), rbwb, greyb]

; Define the color table index values for each of the system colors:
  culz.black     = 0
  culz.bground   = 1
  culz.red       = 2
  culz.green     = 3
  culz.blue      = 4
  culz.yellow    = 5
  culz.orange    = 6
  culz.purple    = 7
  culz.cyan      = 8
  culz.lilac     = 9
  culz.rose      = 10
  culz.slate     = 11
  culz.chocolate = 12
  culz.olive     = 13
  culz.wheat     = 14
  culz.ash       = 15
  culz.white     = culz.sysculz-1

; Define the system colors to be used for various "logical" drawing entities:
  culz.fill_1 = culz.lilac
  culz.fill_2 = culz.slate
  culz.arrows = culz.white
  culz.text   = culz.yellow

; Now define the actual r,g,b color values for each system color
  r(culz.black) = 0
  g(culz.black) = 0
  b(culz.black) = 0
  r(culz.bground) = 0.00*satval
  g(culz.bground) = 0.25*satval
  b(culz.bground) = 0.40*satval
  r(culz.white) = satval
  g(culz.white) = satval
  b(culz.white) = satval
  r(culz.red) = satval
  g(culz.red) = satval/5
  b(culz.red) = satval/5
  r(culz.green) = satval/5
  g(culz.green) = satval
  b(culz.green) = satval/5
  r(culz.blue) = satval/5
  g(culz.blue) = satval/5
  b(culz.blue) = satval
  r(culz.yellow) = satval
  g(culz.yellow) = satval - 5
  b(culz.yellow) = 0
  r(culz.orange) = satval
  g(culz.orange) = satval/2
  b(culz.orange) = 0
  r(culz.purple) = satval
  g(culz.purple) = 0
  b(culz.purple) = satval
  r(culz.lilac) = satval
  g(culz.lilac) = .7*satval
  b(culz.lilac) = satval
  r(culz.rose) = satval
  g(culz.rose) = 0.4*satval
  b(culz.rose) = 0.6*satval
  r(culz.slate) = 0.4*satval
  g(culz.slate) = 0.7*satval
  b(culz.slate) = 0.86*satval
  r(culz.chocolate) = 0.6*satval
  g(culz.chocolate) = 0.3*satval
  b(culz.chocolate) = 0.04*satval
  r(culz.olive) = 0.43*satval
  g(culz.olive) = 0.7*satval
  b(culz.olive) = 0.2*satval
  r(culz.wheat) = satval
  g(culz.wheat) = satval
  b(culz.wheat) = .66*satval
  r(culz.cyan) = 0.
  g(culz.cyan) = .85*satval
  b(culz.cyan) = .85*satval
  r(culz.ash) = 0.5*satval
  g(culz.ash) = 0.5*satval
  b(culz.ash) = 0.5*satval

; Finally, load our fancy color table:
  tvlct, r,g,b
end
