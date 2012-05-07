xx = 'G:\users\SDI3000\Data\Spectra\spectra_2009_spring\PKR 2009_062_Poker_630nm_Red_Sky_Date_03_03.nc'

sdi3k_simple_plotter, xx, plotarr, canvas_size=[1300,900], what_plot='XY_TEMPERATURE', $
                      yrange=[450, 1050], time_smoothing=0.08, space_smoothing=0.005, quality_filter = {snr: 2400., chisq: 1.4}, /psplot, /notitle
end