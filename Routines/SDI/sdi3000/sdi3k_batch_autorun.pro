;spawn, "xxcopy /BB \\137.229.18.250\sdi3000\Data\spectra\*.nc d:\users\sdi3000\data\spectra"
;spawn, "xxcopy /BB \\137.229.18.250\sdi3000\Data\spectra\*.pf d:\users\sdi3000\data\spectra"
sdi3k_ftp_latest_spectra, '137.229.18.203', 'conde', 'davros','d:\users\sdi3000\data\spectra\', 'sdi_data', 'PKR ', 'Poker'
zfiles = mc_recent_files(path='D:\users\SDI3000\Data\Spectra\', filter="Wind_flat_field_???_5577*.sav", max_age=365L*86400L, count=nf)
zfile  = zfiles(0).name
setenv, 'SDI_GREEN_ZERO_VELOCITY_FILE=' + zfile
zfiles = mc_recent_files(path='D:\users\SDI3000\Data\Spectra\', filter="Wind_flat_field_???_6300*.sav", max_age=365L*86400L, count=nf)
zfile  = zfiles(0).name
setenv, 'SDI_RED_ZERO_VELOCITY_FILE=' + zfile
sdi3k_batch_autoprox, path='d:\users\sdi3000\data\spectra', filter=['*.pf', '*.nc', '*.sky', '*.las'], calfit='new', skyfit='new', windfit='new', plotting='new', lookback_seconds=3L*86400L
exit, /no_confirm

