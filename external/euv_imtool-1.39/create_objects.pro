;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; create_objects - create all the Object Graphics objects
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 14-Aug-2003

pro create_objects

@euv_imtool-commons

; --------------------------------------------
; use scene containers for ease of destruction
; --------------------------------------------
scene   = OBJ_NEW('IDLgrScene')
scene3   = OBJ_NEW('IDLgrScene')
scene4   = OBJ_NEW('IDLgrScene')
sceneP   = OBJ_NEW('IDLgrScene')

; ----------------
; create the views
; ----------------
imview = OBJ_NEW('IDLgrView')
imview3 = OBJ_NEW('IDLgrView')
imview4 = OBJ_NEW('IDLgrView')
imviewPa = OBJ_NEW('IDLgrView')
imviewPr = OBJ_NEW('IDLgrView')

; ----------------
; create models
; ----------------
immodel       = OBJ_NEW('IDLgrModel')
immodel3      = OBJ_NEW('IDLgrModel')
immodel4      = OBJ_NEW('IDLgrModel')
immodelc      = OBJ_NEW('IDLgrModel')
immodel3c     = OBJ_NEW('IDLgrModel')
immodelc_full = OBJ_NEW('IDLgrModel')
immodelPa     = OBJ_NEW('IDLgrModel')
immodelPr     = OBJ_NEW('IDLgrModel')

; ---------------------
; create image objects
; ---------------------
image  = OBJ_NEW('IDLgrImage')
image -> SetProperty, data=bytscl(darray)

image3  = OBJ_NEW('IDLgrImage')
image3 -> SetProperty, data=bytscl(darray3)

image4  = OBJ_NEW('IDLgrImage')
image4 -> SetProperty, data=bytscl(full)

; ---------------------------
; create contour plot objects
; --------------------------
contour = OBJ_NEW('IDLgrContour',bytscl(darray),/planar, geomz=0)
contour3 = OBJ_NEW('IDLgrContour',bytscl(darray3),/planar, geomz=0)
set_contour_props

; ---------------------------
; define viewplane rectangles
; ---------------------------
viewp = [0,0,xdim2,ydim2]
imview -> SetProperty, viewplane_rect=viewp
if(expanded_zoom) then viewp3 = [0,0,xdim3,ydim3] else viewp3 = [0,0,xdim3,ydim3/2]
imview3 -> SetProperty, viewplane_rect=viewp3
viewp4 = [0,0,mxdim,mydim]
imview4 -> SetProperty, viewplane_rect=viewp4

; ----------------------------------------------
; create objects for the radial/azimuthal plots
; ----------------------------------------------
rad_plot = OBJ_NEW('IDLgrPlot')
az_plot  = OBJ_NEW('IDLgrPlot')
rad_plot_z = OBJ_NEW('IDLgrPlot')
az_plot_z  = OBJ_NEW('IDLgrPlot')

xaxis_az  = OBJ_NEW('IDLgrAxis',0)
yaxis_az  = OBJ_NEW('IDLgrAxis',1)
xaxis_rad = OBJ_NEW('IDLgrAxis',0)
yaxis_rad = OBJ_NEW('IDLgrAxis',1)

azline2   = OBJ_NEW('IDLgrPolyline')
radline2  = OBJ_NEW('IDLgrPolyline')
azline3   = OBJ_NEW('IDLgrPolyline')
radline3  = OBJ_NEW('IDLgrPolyline')

mlt_label    = OBJ_NEW('IDLgrText','MLT')
l_label      = OBJ_NEW('IDLgrText','L Shell')
counts_label = OBJ_NEW('IDLgrText','Counts')

log_label_a  = OBJ_NEW('IDLgrText',['0','1','2','3'])
log_label_r  = OBJ_NEW('IDLgrText',['0','1','2','3'])
null_label_a = OBJ_NEW()
null_label_r = OBJ_NEW()

; ------------------------------------------------
; create stuff for Earth center and click marking
; ------------------------------------------------
click_points  = OBJ_NEW('IDLgrPlot', xclick, yclick)
click_points -> SetProperty, linestyle=6
click_points3  = OBJ_NEW('IDLgrPlot', xclick3, yclick3)
click_points3 -> SetProperty, linestyle=6
click_points_full  = OBJ_NEW('IDLgrPlot', xclick, yclick)
click_points_full -> SetProperty, linestyle=6


click_symbol  = OBJ_NEW('IDLgrSymbol',6)
click_symbol  -> SetProperty, size=[1.4,1.4]
click_symbol  -> SetProperty, color=255

click_points -> SetProperty, symbol=[click_symbol]
click_points -> SetProperty, hide=1
click_points3 -> SetProperty, symbol=[click_symbol]
click_points3 -> SetProperty, hide=1
click_points_full -> SetProperty, symbol=[click_symbol]
click_points_full -> SetProperty, hide=1

center_ellipse      = OBJ_NEW('IDLgrPolyline')
center_ellipse3     = OBJ_NEW('IDLgrPolyline')
center_ellipse_full = OBJ_NEW('IDLgrPolyline')

center_ellipse      -> SetProperty, linestyle=1
center_ellipse3     -> SetProperty, linestyle=1
center_ellipse_full -> SetProperty, linestyle=1

center_symbol  = OBJ_NEW('IDLgrSymbol',1)
center_symbol  -> SetProperty, size=[2.0,2.0]
center_symbol  -> SetProperty, color=0

center_point  = OBJ_NEW('IDLgrPlot', [0], [0])
center_point -> SetProperty, linestyle=6
center_point -> SetProperty, symbol=[center_symbol]

center_point3  = OBJ_NEW('IDLgrPlot', [0], [0])
center_point3 -> SetProperty, linestyle=6
center_point3 -> SetProperty, symbol=[center_symbol]

center_point_full  = OBJ_NEW('IDLgrPlot', [0], [0])
center_point_full -> SetProperty, linestyle=6
center_point_full -> SetProperty, symbol=[center_symbol]

end
