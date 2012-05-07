xx = dialog_pickfile(path='d:\users\sdi2000\data\', filter='sky*.pf')
yy = dialog_pickfile(path='d:\users\sdi2000\data\', filter='ins*.pf')
sdi2k_batch_spekfitz, xx, yy
sdi2k_batch_windfitz, xx, resarr, windfit
sdi2k_batch_plotz,    xx, resarr, windfit
end