    whoami, dir, file
    disk = strmid(dir, 0,2)
    logdir = disk + '\users\sdi2000\data\'
    ff = dialog_pickfile(path=logdir, filter='sky*.pf')
    sdi_load,ff,sect,zon,mer,tem,zen,delz,delt,/sdi2000 
    js2ymds, sect, yy,mm,dd,ss
    hr = ss/3600.
    load_pal, culz
    erase, color=culz.white
;    hr=hr(100:400)
;    zen=zen(100:400)
    
;    plot, hr, zen, charsize=2, /xstyle, xtit='Hours UT', ytit='Vertical Wind in m/s', $
;          /noerase, xthick=2, ythick=2, charthick=2, color=culz.black, /ystyle, yrange=[-120,120]
    oplot, [hr(0), hr(n_elements(hr)-1)], [0,0], linestyle=1, color=culz.ash
    plot, hr, zen, charsize=2, /xstyle, xtit='Hours UT', ytit='Vertical Wind in m/s', $
          /noerase, xthick=3, ythick=3, charthick=2, color=culz.black, /ystyle, yrange=[-120,120], xminor=6
    oplot, hr, zen, psym=1, color=culz.red, symsize=0.3
    !p.color = culz.blue
    oploterr, hr, zen, delz, 3
 stop
    erase, color=culz.white
    plot, hr, tem, charsize=2, /xstyle, xtit='Hours UT', ytit='Temperature, Kelvin', $
          /noerase, xthick=2, ythick=2, charthick=2, color=culz.black, /ystyle, yrange=[500,2000]
    plot, hr, tem, charsize=2, /xstyle, xtit='Hours UT', ytit='Temperature, Kelvin', $
          /noerase, xthick=3, ythick=3, charthick=2, color=culz.black, /ystyle, yrange=[500,2000], xminor=12
    oplot, hr, tem, psym=1, color=culz.red, symsize=0.3
    !p.color = culz.blue
    oploterr, hr, tem, delt, 3
 
    end