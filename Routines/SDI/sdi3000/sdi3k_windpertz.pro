function sdi_interp, valbefore, valafter, timebefore, timeafter, when
         return, valbefore + (valafter - valbefore)*(when - timebefore)/(timeafter - timebefore)
end

pro overplot_wind_vectors, zon, mer, zone_centers, scale, mm, culz
    pix = min([mm.rows, mm.columns])
    zx  = zone_centers(*,0)*mm.columns
    zy  = zone_centers(*,1)*mm.rows
        x0 = zx - 0.25*pix*zon/scale
        x1 = zx + 0.25*pix*zon/scale
        y0 = zy + 0.25*pix*mer/scale
        y1 = zy - 0.25*pix*mer/scale
        arrow, x0, y0,x1, y1, color=culz.green, thick=2, hthick=2
end

fills = 5
data_path = 'c:\users\sdi3000\data\spectra\'
if getenv('computername') eq 'VERTEX'   then data_path = 'd:\'
if getenv('computername') eq 'FLYWHEEL' then data_path = 'D:\users\SDI3000\Data\Spectra\'
ncfile = dialog_pickfile(path=data_path, get_path=data_path, /read, /must_exist)

sdi3k_read_netcdf_data, ncfile, metadata=mm, zonemap=zonemap, zone_centers=zone_centers, zone_edges=zone_edges
while !d.window gt 0 do wdelete, !d.window
window, xsize=mm.columns, ysize=mm.rows
;---Choose the color palette:
    load_pal, culz, proportion=0.5, /doppler
    loshade = culz.imgmin+1
    hishade = culz.imgmax-1

    channel_spacing = (1e-9*mm.wavelength_nm)^2/(2e-3*mm.gap_mm*mm.scan_channels)
    c=2.997925e8
    amu=1.66053e-27
    bk=1.380658e-23
    f = c*channel_spacing/(1e-9*mm.wavelength_nm)
    g = mm.mass_amu*amu/(2*bk)

    vzero = 0.

for j=0,mm.maxrec-2 do begin
    sdi3k_read_netcdf_data, ncfile, winds=winds, spekfits=spekfits, range=[j,j+1]
    spekfits.velocity = spekfits.velocity - median(spekfits.velocity)
    spekfits.velocity = f*spekfits.velocity
    spekfits.sigma_velocity = f*spekfits.sigma_velocity
    zang = 2*sqrt((zone_centers(*, 0)-0.5)^2 + (zone_centers(*,1)-0.5)^2)*mm.sky_fov_deg
    u0 = winds.zonal_wind(0)
    v0 = winds.meridional_wind(0)
    scene = intarr(mm.columns, mm.rows)

    for ff=0,fills-1 do begin
        ct0 = (spekfits(0).start_time + spekfits(0).end_time)/2
        ct1 = (spekfits(1).start_time + spekfits(1).end_time)/2
        obslos = sdi_interp(spekfits(0).velocity, spekfits(1).velocity, ct0, ct1, ct0 + float(ff)*(ct1-ct0)/float(fills))
        u0now  = sdi_interp(u0(0), u0(1), ct0, ct1, ct0 + float(ff)*(ct1-ct0)/float(fills))
        v0now  = sdi_interp(v0(0), v0(1), ct0, ct1, ct0 + float(ff)*(ct1-ct0)/float(fills))
        zon    = sdi_interp(winds(0).zonal_wind, winds(1).zonal_wind, ct0, ct1, ct0 + float(ff)*(ct1-ct0)/float(fills))
        mer    = sdi_interp(winds(0).meridional_wind, winds(1).meridional_wind, ct0, ct1, ct0 + float(ff)*(ct1-ct0)/float(fills))
        fitlos = sin(!dtor*zang)*u0now*sin(!dtor*(winds(0).azimuths - 28.5)) + sin(!dtor*zang)*v0now*cos(!dtor*(winds(0).azimuths - 28.5))
        for k=0,mm.nzones-1 do begin
            these = where(zonemap eq k)
;            shade = (hishade + loshade)/2. + spekfits(0).velocity(k)*(hishade - loshade)/600.
;            shade = (hishade + loshade)/2. + fitlos(k)*(hishade - loshade)/600.
            shade = (hishade + loshade)/2. + (fitlos(k)-obslos(k))*(hishade - loshade)/300.
;            shade = (hishade + loshade)/2. + (spekfits(0).velocity(k))*(hishade - loshade)/600.
;            shade = (hishade + loshade)/2. + (fitlos(k))*(hishade - loshade)/600.
            shade = shade > loshade
            shade = shade < hishade
            scene(these) = shade
        endfor
        scene(zone_edges) = culz.black
        tv, scene
        overplot_wind_vectors, zon, mer, zone_centers, 1200., mm, culz
        wait, 0.004
    endfor
endfor
sdi3k_read_netcdf_data, ncfile, /close
end
