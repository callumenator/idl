;**************************************************************************
; By default IDL programs generate output in landscape mode, upside down.
; Anyone using IDL programs can rotate their figures to portrait
; mode using the program below and entering
;
;IDL 	psopen,'p'
;IDL    make your plot
;IDL	device,/close_file
 
PRO psopen,opt,scale=scale,file=psfile,bpp=bpp,color=color,encapsulated=encapsulated
 ;+
 ;PURPOSE: TO OPEN A POSTSCRIPT FILE
 ;USEFUL WHEN MAKING COMPLICATED PLOTS
 ;DEAFULT IS FULL PAGE LANDSCAPE
 ;AFTER ISSUING PLOTTING COMMANDS (INTERACTIVELY OR VIA ROUTINES) USE
 ; THE "PSCLOSE" ROUTINE TO CLOSE THE POST SCRIPT FILE AND SEND IT TO
 ; A LAZY PRINTER.
 ;
 ; All parameters are optional
 ;
 ; Inputs:	SCALE   Sets the scale factor for the entire output plot
 ;			Default = 1.0
 ;		OPT	A string specifying Portrait ('p') or Landscape ('l')
 ;			Default is landscape
 ;		PSFILE  A string naming the output file.
 ;
 ; MARTIN SIRK   JULY  1989
 ; 
 ; modified J. Wheatley 1/18/90
 ; added file keyword; specified ~/idl.ps to avoid write-protection
 ; problems
 ;
 ; modified D. Finley 2/24/90
 ; Shrank landscape size to reasonable values and added option for portrait mode
 ; opt == 'p' --> portrait OR opt == 'l' --> landscape
 ; default is landscape
 ;-
 ; dev=!d.name
 
 if n_params() lt 1  then opt = 'l'
; if not keyword_set(psfile) then psfile='~/idl.ps'
 if not keyword_set(psfile) then psfile='idl.ps'
 if not keyword_set(scale) then scale=1.0
 
 print,'Output file is  ',psfile
 
 set_plot,'PS'               ; open post script file
 
 if not keyword_set(color) then color=0
 if not keyword_set(bpp) then bpp=4
 if not keyword_set(encapsulated) then encapsulated=0
 
 case opt of
   'l':DEVICE,file=psfile,/landscape,/INCHES,XOFFSET=0.5,XSIZE=10.0,$
       YOFFSET=10.5,YSIZE=7.5,scale_factor=scale,bits_per_pixel=bpp,$
 	color=color,encapsulated=encapsulated
   'pic':DEVICE,file=psfile,/landscape,/INCHES,XOFFSET=0.8,XSIZE=10.0,$
       YOFFSET=10.65,YSIZE=6.875,scale_factor=scale,bits_per_pixel=bpp,$
 	color=color,encapsulated=encapsulated
   'p':DEVICE,file=psfile,/portrait,/INCHES,XOFFSET=0.5,XSIZE=7.5,YOFFSET=0.5,$
 	YSIZE=10.0,scale_factor=scale,bits_per_pixel=bpp,color=color,$
 	encapsulated=encapsulated
   'pl':DEVICE,file=psfile,/portrait,/INCHES,XOFFSET=0.5,XSIZE=7.5,YOFFSET=0.5,$
 	YSIZE=5.625,scale_factor=scale,bits_per_pixel=bpp,color=color,$
 	encapsulated=encapsulated
   't':DEVICE,file=psfile,/portrait,/INCHES,XOFFSET=0.5,XSIZE=6.6,$
 	YOFFSET=0.5,$
 	YSIZE=10.0,scale_factor=scale,bits_per_pixel=bpp,color=color,$
 	encapsulated=encapsulated
   else: print,opt,'is not a valid option, use p for portrait or l for landscape'
 endcase
 
 return
 end
