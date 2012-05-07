function rgbidx, rgb
  return,  rgb(0) + 256L * (rgb(1) + 256L * rgb(2))
end