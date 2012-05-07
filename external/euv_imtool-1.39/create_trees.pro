;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
; create_tree - create Object Graphics trees
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

; last modified: 11-Aug-2003

pro create_trees

@euv_imtool-commons

; ------------
; main window
; ------------
scene -> ADD, imview
imview -> ADD, immodel
immodel -> ADD, image
immodel -> ADD, immodelc
immodel -> ADD, azline2
immodel -> ADD, radline2
immodel -> ADD, contour
immodel -> ADD, click_points
immodel -> ADD, center_point

immodelc -> ADD, center_ellipse

; -----------------------------
; zoomed image display window
; -----------------------------
scene3 -> ADD, imview3
imview3 -> ADD, immodel3
immodel3 -> ADD, image3
immodel3 -> ADD, immodel3c
immodel3 -> ADD, azline3
immodel3 -> ADD, radline3
immodel3 -> ADD, contour3
immodel3 -> ADD, click_points3
immodel3 -> ADD, center_point3

immodel3c -> ADD, center_ellipse3

; -------------------------------
; full frame image display window
; -------------------------------
scene4 -> ADD, imview4
imview4 -> ADD, immodel4
immodel4 -> ADD, image4
immodel4 -> ADD, immodelc_full
immodel4 -> ADD, click_points_full
immodel4 -> ADD, center_point_full

immodelc_full -> ADD, center_ellipse_full

; -----------------------------
; line plot window
; -----------------------------
sceneP -> ADD, imviewPa
sceneP -> ADD, imviewPr
imviewPa -> ADD, immodelPa
imviewPr -> ADD, immodelPr

immodelPr -> ADD, rad_plot
immodelPr -> ADD, rad_plot_z
immodelPr -> ADD, xaxis_rad
immodelPr -> ADD, yaxis_rad

immodelPa -> ADD, az_plot
immodelPa -> ADD, az_plot_z
immodelPa -> ADD, xaxis_az
immodelPa -> ADD, yaxis_az

end



