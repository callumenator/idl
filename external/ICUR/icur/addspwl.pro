;****************************************************************
pro addspwl,h0,w0,lam1,lam2,dl,krange   ;get wavelength limits
idat=h0(0)
ncam=h0(3)
case 1 of
   idat eq 0: begin   ;IUE low dispersion
      krange=7
      case 1 of
         ncam eq 3: begin   ;SWP
            lam1=1100.
            lam2=1980.
            dl=1.0
            end
         (ncam eq 1) or (ncam eq 2): begin   ;LWP/R
            lam1=1900.
            lam2=3300.
            dl=1.5
            end
         else: begin
            print,' invalid camera number =',ncam
            stop
            end
         endcase
      end
   idat eq 1: begin
      krange=11
      lam1=min(w0)
      lam2=max(w0)
      dl=float(h(22))+float(h(23))/1000.
      end
   idat eq 7: begin   ;IUE high dispersion, long format
      krange=11
      case 1 of
         ncam eq 3: begin   ;SWP
            lam1=1150.
            lam2=2068.5
            end
         (ncam eq 1) or (ncam eq 2): begin   ;LWP/R
            lam1=2000.
            lam2=3200.
            end
         else: begin
            print,' invalid camera number =',ncam
            stop
            end
         endcase
      dl=(w0(5000)-w0(0))/5000.
      end
   else: begin
   print,' ADDSPWL: parameters for IDAT=',idat,' undefined'
      krange=11
      lam1=min(w0)
      lam2=max(w0)
      dl=w0(1)-w0(0)
      end
   endcase
return
end
