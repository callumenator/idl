    doyz = indgen(120) + 1
    dates = strarr(n_elements(doyz))
    for j=0, n_elements(dates) - 1 do dates(j) = ydn2date(2010, doyz(j), format='0n$_0d$')
    mcchoice, 'Day Number?', string(doyz, format='(i3.3)'), choice

    fpath = 'I:\users\SDI3000\Data\Poker\'
    fred  = fpath + 'PKR 2010_' + string(doyz(choice.index), format='(i3.3)') + $
            '_Poker_630nm_Red_Sky_Date_' + dates(choice.index) + '.nc'
    fgrn  = fpath + 'PKR 2010_' + string(doyz(choice.index), format='(i3.3)') + $
            '_Poker_558nm_green_Sky_Date_' + dates(choice.index) + '.nc'

;    sdi3k_simple_cirplot, fred, canvas=[2200,2500], center=[0.77, 0.8], temp=[200,550], rgb=fgrn
    sdi3k_simple_cirplot, fgrn, canvas=[2200,2500], center=[0.77, 0.8], temp=[200,550], rgb=fgrn
    gif_this, /png, file='C:\Users\Conde\Main\ampules\Ampules_II\Proposal\figures\Wind_Dial_Plot_PKR_2010_DOY' + $
                          choice.name + '_wind558_rgb558.png'

    end
