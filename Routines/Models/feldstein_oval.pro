

pro Feldstein_Oval

		window, 0, xs = 900, ys = 900

;		times = findgen(24)
;		s = 100
;		arr = dblarr(s,s,24)
;		for dayno = 100, 200 do begin
;
;			file = mawname_from_ydn(2007, dayno)
;
;			if file_test(file) then begin
;
;				res = get_ncdf_data(file, /quick)
;
;				yymmdd = js_to_yymmdd(res.start_time(0))
;				cld = get_cloud_level(yymmdd, /day_average)
;				if cld lt 3 then begin
;
;				time = (js2ut(res.start_time) + 1.3) mod 24
;
;
;				zmap = zonemapper(s, s, [s/2., s/2.], res.rads, res.secs, 0)
;				pts = where(zmap eq -1)
;
;				for j = 0, res.nexps - 1 do begin
;					tarr = [time(j), times]
;					tarr = tarr(sort(tarr))
;					pt = where(tarr eq time(j))
;					pt = pt(0)
;					idx = pt - 1
;					img = congrid(float(get_allsky_image(file, j)), s, s, /interp)
;					img = rot(img, 22)
;					img = reverse(img)
;					simg = img(sort(img))
;					n = n_elements(simg)
;					ptsl = where(img lt simg(n*.6 - 1), nl)
;					ptsg = where(img gt simg(n*.9 - 1), ng)
;					if nl gt 0 then img(ptsl) = simg(n*.6 - 1)
;					if ng gt 0 then img(ptsg) = simg(n*.9 - 1)
;
;					img(pts) = simg(n*.4 - 1)
;					arr(*,*,idx) = arr(*,*,idx) + img
;					wait, 0.0001
;
;				endfor
;
;				for t = 0, 23 do begin
;					rot_ang = ((t-12)/12.)*180
;					rimg = arr(*,*,t)
;					rimg = rot(rimg, rot_ang)
;					x = 450 + 360.*sin(rot_ang*!dtor)
;					y = 450 + 360.*cos(rot_ang*!dtor)
;
;					tvscl, rimg, x-s/2., y-s/2., /device
;
;				endfor
;
;			endif
;			endif
;			print, dayno
;
;
;		endfor
;
;		stop

	level =1

	res = 100.

	pole = fltarr(res)
	equator = fltarr(res)
	mltarr = pole

	sth_dip_pole = [-74, 125]	;actually cgm pole
	mawson = [-67.603, 62.874]
	davis  = [-68.577, 77.967]

	;maw_mag = geo2mag(mawson)
	;dav_mag = geo2mag(davis)

	maw_mag = [-70.37, 90.46]
	dav_mag = [-74.65, 100.5]

		for mltx = 0, res-1 do begin

			mlt = (mltx/(res-1))*24.

			a1=[15.22,15.85,16.09,16.16,16.29,16.44,16.71]
		    a2=[2.41,2.7,2.51,1.92,1.41,0.81,0.37]
		    a3=[3.34,3.32,3.27,3.14,3.06,2.99,2.9]
		    a4=[-0.85,-0.67,-0.56,-0.46,-.09,.14,.63]
		    a5=[1.01,1.15,1.3,1.43,1.35,1.25,1.59]
		    a6=[.32,.49,.42,.32,.4,.48,.6]
		    a7=[.9,1.,.94,.96,1.03,1.05,1]
			b1=[17.36,18.66,19.73,20.63,21.56,22.32,23.18]
		    b2=[3.03,3.9,4.69,4.95,4.93,4.96,4.85]
		    b3=[3.46,3.37,3.34,3.31,3.31,3.29,3.34]
		    b4=[.42,.16,-.57,-.66,-.44,-.39,-.38]
		    b5=[2.11,2.55,-1.41,-1.28,-.81,-.72,-.62]
		    b6=[-.25,-.13,-.07,.3,-.07,-.16,-.53]
		    b7=[1.13,.96,.75,-.58,-.75,-.52,-.16]

			umr = !PI / 180.
			iq = level
			PHI = MLT * 15.

			z=a1(iq)+a2(iq)*cos(umr*(phi+a3(iq)))+a4(iq)*cos(2.*umr*(phi+a5(iq)))+a6(iq)*cos(3.*umr*(phi+a7(iq)))
			pcgl=90.-z

			y=b1(iq)+b2(iq)*cos(umr*(phi+b3(iq)))+b4(iq)*cos(2.*umr*(phi+b5(iq)))+b6(iq)*cos(3.*umr*(phi+b7(iq)))
			ecgl=90.-y

			mltarr(mltx) = mlt
			;mp = mag2geo([-pcgl, mlt*15.])
			pole(mltx) = -pcgl
			;me = mag2geo([-ecgl, mlt*15.])
			equator(mltx) = -ecgl

		endfor





		winx = 800
		loadct, 39, /silent

		window, 0, xs = winx, ys = winx

 		pole_rad = (pole + 90)/50.
 		equator_rad = (equator + 90)/50.
 		ang = findgen(100)*3.65*!dtor - !pi/2.

		maw = fltarr(100)
		maw(*) = (maw_mag(0)+ 90.)/50.
		dav = fltarr(100)
		dav(*) = (dav_mag(0)+ 90.)/50.

		ang = interpol(ang, 300)
		pole_rad = interpol(pole_rad, 300)
		equator_rad = interpol(equator_rad, 300)
		maw = interpol(maw, 300)
		dav = interpol(dav, 300)

		;loadct, 3
		;for j = 0, n_elements(ang) - 1 do begin
		;	plots, [.5 + pole_rad(j)*cos(ang(j)),.5 + equator_rad(j)*cos(ang(j))], $
		;		   [.5 + pole_rad(j)*sin(ang(j)), .5 + equator_rad(j)*sin(ang(j))], /normal, thick= 10, color = 150
		;endfor

		plots, .5 + pole_rad*cos(ang), $
			   .5 + pole_rad*sin(ang), /normal, thick = 3, color = 150

		plots, .5 + equator_rad*cos(ang), $
			   .5 + equator_rad*sin(ang), /normal, thick = 3, color = 150

		loadct, 39, /silent

		plots, .5 + maw*cos(ang), $
			   .5 + maw*sin(ang), /normal, thick = 8, color = 0
		plots, .5 + maw*cos(ang), $
			   .5 + maw*sin(ang), /normal, thick = 2, color = 100, line = 2

		plots, .5 + dav*cos(ang), $
			   .5 + dav*sin(ang), /normal, thick = 8, color = 0
		plots, .5 + dav*cos(ang), $
			   .5 + dav*sin(ang), /normal, thick = 2, color = 200, line=2

		stop
end