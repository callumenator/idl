function jd2string, jd
  caldat, jd, m, d, y, h, m
  doy = fix(jd - julday(1, 1, y, h, m) + 1)
  return, zeropad(y, 4) + "/" + zeropad(doy, 3) + "/" + zeropad(h, 2) + ":" + $
          zeropad(m, 2)
end
