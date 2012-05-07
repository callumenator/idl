function zeropad, i, l
  n = fix(i)
  x = strmid(strcompress(string(n)), 1, 1000)
  while(strlen(x) lt l) do x = '0' + x
  return, x
end
