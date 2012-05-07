;========================================================================
;                               ggm.pro
;========================================================================

PRO GGM,ART,LONGI,LATI,MLONG,MLAT,gmpole=gmpole
;
;+
;NAME:
;     GGM
;PURPOSE:
;     calculates geomagnetic longitude (mlong) and latitude (mlat)
;       from geographic longitude (longi) and latitude (lati) for art=0
;     calculates reverse for art=1
;     Does a simple coordinate shift from the N pole to the GM Pole
;CALLING SEQUENCE:
;     ggm,art,longi,lati,mlong,mlat
;PROCEDURE:
;     coordinate transformation about geomagnetic/geocentric axis
;INPUTS:
;     art - 0 for geographic to magnetic conversion
;         - 1 for magnetic to geographic conversion
;     gmpole - optional 2 element array of geographic coordinates
;              of the geomagnetic pole, [0<elon<360,-90<lat<90]
;INPUT/OUTPUT:
;     longi, lati - geographic coordinates (in or out depends on art)
;     mlong, mlat - geomagnetic coordinates (in or out depends on art)
;CAUTIONS:
;     all input and output angles are in degrees
;     latitude range -90 to 90, longitude range 0 to 360 east
;HISTORY:
;     From:NSSDCA::STPMODELS    "D. Bilitza, (301)286-9536"  8-JUN-1990 14:10
;          To:CASS05::ROSEN
;          CC:STPMODELS
;          Subj:subroutine GGM: geographic <=> geomagnetic coordinates
;     1990 - Lyons - UCSD - original FORTRAN code revised for IDL Version 2
;     1999 adopted by Debi-Lee Wilkinson for Aurora Boundary - UPOS project
;     1999 modified to generalize geomagnetic pole position.
;-
;
 IF NOT KEYWORD_SET(gmpole) THEN gmpole=[288.35,79.4]
        faktor=6.2831853/360.                        ; degrees to radians
        ZPI=FAKTOR*360.
        co_lat = 90 - gmpole(1)          ;co-latitude in degrees
        CBG=co_lat*FAKTOR                              ; in radians
        CI=COS(CBG)
        SI=SIN(CBG)
;
;     convert geomagnetic coordinates to geographic
;
cvt:    if art eq 1 then begin
           CBM=COS(MLAT*FAKTOR)
           SBM=SIN(MLAT*FAKTOR)
           CLM=COS(MLONG*FAKTOR)
           SLM=SIN(MLONG*FAKTOR)
           SBG=SBM*CI-CBM*CLM*SI
           LATI=ASIN(SBG)
           CBG=COS(LATI)
           SLG=(CBM*SLM)/CBG
           CLG=(SBM*SI+CBM*CLM*CI)/CBG
;
;     IF ABS(CLG) GT 1. then CLG=SIGN(1.,CLG) replaced for IDL
;     (limit test on clg)
;
           for i=0,n_elements(CLG)-1 do begin
            if CLG(i) lt -1. then CLG(i) = -1.
            if CLG(i) gt 1. then CLG(i) = 1.
           endfor
           LONGI=ACOS(CLG)
           for i=0,n_elements(SLG)-1 do begin
            IF SLG(i) LT 0.0 then LONGI(i)=ZPI-ACOS(CLG(i))
           endfor
           LATI=LATI/FAKTOR
           LONGI=LONGI/FAKTOR
           LONGI=LONGI-360.+gmpole(0)     ; longitude offset of pole
           for i=0,n_elements(LONGI)-1 do begin
            IF LONGI(i) LT 0.0 then LONGI(i)=LONGI(i)+360.0
           endfor
        endif
;
;     convert geographic latitude and longitude to geomagnetic
;
        if art eq 0 then begin
           YLG=LONGI+360.-gmpole(0)     ;  Go the other way
           CBG=COS(LATI*FAKTOR)
           SBG=SIN(LATI*FAKTOR)
           CLG=COS(YLG*FAKTOR)
           SLG=SIN(YLG*FAKTOR)
           SBM=SBG*CI+CBG*CLG*SI
           MLAT=ASIN(SBM)
           CBM=COS(MLAT)
           SLM=(CBG*SLG)/CBM
           CLM=(-SBG*SI+CBG*CLG*CI)/CBM
           bad=where(clm gt 1.)
           if (bad(0) ne -1) then CLM(bad)=1.
           MLONG=ACOS(CLM)
           bad=where(slm lt 0.)
           if (bad(0) ne -1) then MLONG(bad)=ZPI-ACOS(CLM(bad))
           MLAT=MLAT/FAKTOR
           MLONG=MLONG/FAKTOR
        endif
;
;     error condition - allow user intervention when debugging
;
        if ((art ne 0) and (art ne 1)) then begin
           print,'GGM - invalid value of coord conversion direction specifier'
           print,'    - value received was ',art
           print,'    - enter 0 to convert from geographic to geomagnetic'
           print,'    - enter 1 to convert from geomagnetic to geographic'
           art=''
           read,'GGM - enter appropriate value for specifier ',art
           if ((art eq 0) or (art eq 1)) then goto,cvt
           print,'GGM - invalid specifier entered - returning - no action taken'
        endif
;
        return
        end


