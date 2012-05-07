function mc_dist, nx, ny, xcen, ycen, x=xx, y=yy
    xx     = float(transpose(lindgen(ny,nx)/ny) - xcen)
    yy     = float(lindgen(nx,ny)/nx - ycen)

    return, sqrt(xx^2 + yy^2)

end