function spek_fun, x, j
@spekinc.pro
          lftz = where(ctlz.fix_mask(ptrz.backgnd:ptrz.molecular) eq 0, nlft)
          return, transpose(funz.basis(lftz, 0:dimz.npts-1))
end