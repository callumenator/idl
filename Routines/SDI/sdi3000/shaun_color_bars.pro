window, xsize=900, ysize=400
load_pal, culz

erase, color=culz.white


        xlo = 0.1
        xhi = 0.9
        ylo = 0.4
        yhi = 0.6
        mccolbar, [xlo, ylo, xhi, yhi], culz.imgmin, culz.imgmax, 0., 100., $
                      parname=' ', units=' ', $
                      color=culz.black, thick=3, charsize=2.5, format='(i6)', $
                     /horizontal, /both_units,  reserved_colors=20

end