
;===========================================================
; gen_transforms - generate matrices for coordinate
;                  transformations
;===========================================================
pro gen_transforms,fmjd,t1,t2,t3,t4,t5

; last updated: 7-Mar-2001

HALFPI = !PI / 2.0

; ----------------------------------
; calculate time in Julian centuries
; ----------------------------------
ut = (fmjd mod 1.0) * 24.0
mjd = float(long(fmjd))
t0 = (mjd - 51544.5) / 36525.0

; -----------------------
; calculate sidereal time
; -----------------------
theta = (100.461 + 36000.77*t0 + 15.04107*ut) / !RADEG

; -----------------------
; magnetic pole position
; -----------------------
phi    = (78.8 + 0.04283 * ((mjd - 46066.0)/365.25)) / !RADEG
lambda = (289.1 - 0.01413 * ((mjd - 46066.0)/365.25)) / !RADEG

;-----------------
; T1 - GEI to GEO
;-----------------
t1 = dblarr(3,3)
t1 = [ [cos(theta),sin(theta),0.0], [-sin(theta),cos(theta),0.0], [0.0,0.0,1.0] ]

; -------------------------
; obliquity of the ecliptic
; -------------------------
eps = (23.439 - 0.013 * t0) / !RADEG

; -----------------------------
; ecliptic longitude of the Sun
; -----------------------------
mean_anomaly = (357.528 + 35999.05* t0 + .04107*ut) / !RADEG
big_lambda = (280.460 + 36000.772 * t0 + .04107* ut)
lambda_sun = (big_lambda + (1.915 - 0.0048*t0)*sin(mean_anomaly) + 0.020 * sin(2.0*mean_anomaly))
ls = lambda_sun / !RADEG

;-----------------
; T2 - GEI to GSE
;-----------------
t2a = dblarr(3,3)
t2b = dblarr(3,3)
t2 = dblarr(3,3)

t2a = [[cos(ls),sin(ls),0.0],[-sin(ls),cos(ls),0.0],[0.0,0.0,1.0]]
t2b = [[1.0,0.0,0.0],[0.0,cos(eps),sin(eps)],[0.0,-sin(eps),cos(eps)]]
t2 = t2a##t2b

qg = dblarr(3)
qg = [cos(phi)*cos(lambda),cos(phi)*sin(lambda),sin(phi)]
qe = t2##transpose(t1)##qg
big_phi = atan(qe[1]/qe[2])

;-----------------
; T3 - GSE to GSM
;-----------------
t3=dblarr(3,3)
t3=[ [1.0,0.0,0.0], [0.0,cos(-big_phi),sin(-big_phi)], [0.0,-sin(-big_phi),cos(-big_phi)] ]

;-----------------
; T4 - GSM to SM
;-----------------
mu = atan(qe[0] / sqrt(qe[1]^2+qe[2]^2))
t4=dblarr(3,3)
t4 = [ [cos(-mu),0.0,sin(-mu)], [0.0,1.0,0.0], [-sin(-mu),0.0,cos(-mu)] ]

;-----------------
; T5 - GEO to MAG
;-----------------
t5=dblarr(3,3)
t5a=dblarr(3,3)
t5b=dblarr(3,3)

arg = phi - HALFPI
t5a = [ [cos(arg),0.0,sin(arg)], [0.0,1.0,0.0], [-sin(arg),0.0,cos(arg)] ]
t5b = [ [cos(lambda),sin(lambda),0.0], [-sin(lambda),cos(lambda),0.0], [0.0,0.0,1.0] ]
t5 = t5a##t5b

end
