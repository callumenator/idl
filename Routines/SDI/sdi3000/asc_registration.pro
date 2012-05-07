
;sdi3k_read_netcdf_data, 'D:\users\SDI3000\Data\Spectra\PKR 2008_087_Poker_558nm_Green_Sky_Date_03_27.nc', $
;                         metadata=mm
;sdi3k_read_netcdf_data, 'D:\users\SDI3000\Data\Spectra\PKR 2008_087_Poker_558nm_Green_Sky_Date_03_27.nc', $
;                         metadata=mm, zonemap=zonemap, zone_centers=zone_centers, zone_edges=zone_edges, $
;                         image=sdi, range=[17,17]
;sdi3k_read_netcdf_data, 'D:\users\SDI3000\Data\Spectra\PKR 2008_088_Poker_630nm_Red_Sky_Date_03_28.nc', $
;                         metadata=mm, zonemap=zonemap, zone_centers=zone_centers, zone_edges=zone_edges, $
;                         image=sdi, range=[55,55]
sdi3k_read_netcdf_data, 'D:\users\SDI3000\Data\Spectra\PKR 2008_041_Poker_630nm_Red_Sky_Date_02_10.nc', $
                         metadata=mm, zonemap=zonemap, zone_centers=zone_centers, zone_edges=zone_edges, $
                         image=sdi, range=[252,252]

sdi_img_gain = 0.15
sdi(0).scene  = sdi_img_gain*(sdi(0).scene - min(smooth(sdi(0).scene, 15))) < 255
;asc = readfits('C:\Poker_ASC_data\20080327\AS065240.FITS', hdr)
asc = readfits('C:\Poker_ASC_data\20080210\AS121038.FITS', hdr)
asc = rotate(asc, 2)
asc = rebin(asc, 512,512)
asc = asc - min(asc)
asc = bytscl(asc, max=1200)

ascmag  = 1.35
xcen = 0.52
ycen = 0.48

green = congrid(asc, n_elements(asc(*,0))*ascmag, n_elements(asc(0,*))*ascmag, /interp)
red   = green*0.
blue  = green*0.

xpix    = n_elements(green(*,0))
ypix    = n_elements(green(0,*))
sdixpix = n_elements(sdi(0).scene(*,0))
sdiypix = n_elements(sdi(0).scene(0,*))

sdibase = [xcen*xpix - sdixpix/2, ycen*ypix - sdixpix/2]
red(sdibase(0):sdibase(0)+sdixpix-1, sdibase(1):sdibase(1)+sdixpix-1) = sdi(0).scene


while !d.window ge 0 do wdelete, !d.window
window, xsize=xpix, ysize=ypix

tv, [[[red]], [[green]], [[blue]]], true=3

end
