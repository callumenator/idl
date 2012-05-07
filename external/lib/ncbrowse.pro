; $I: ncbrowse.pro,v 1.0 1994/07/27 22:25:03 msegur Exp msegur $
; Copyright 1994 University Corporation for Atmospheric Research/Unidata
; 
; Portions of this software were developed by the Unidata Program at the 
; University Corporation for Atmospheric Research.
; 
; Access and use of this software shall impose the following obligations
; and understandings on the user. The user is granted the right, without
; any fee or cost, to use, copy, modify, alter, enhance and distribute
; this software, and any derivative works thereof, and its supporting
; documentation for any purpose whatsoever, provided that this entire
; notice appears in all copies of the software, derivative works and
; supporting documentation.  Further, the user agrees to credit
; UCAR/Unidata in any publications that result from the use of this
; software or in any product that includes this software. The names UCAR
; and/or Unidata, however, may not be used in any advertising or publicity
; to endorse or promote any products or commercial entity unless specific
; written permission is obtained from UCAR/Unidata. The user also
; understands that UCAR/Unidata is not obligated to provide the user with
; any support, consulting, training or assistance of any kind with regard
; to the use, operation and performance of this software nor to provide
; the user with any updates, revisions, new versions or "bug fixes."
; 
; THIS SOFTWARE IS PROVIDED BY UCAR/UNIDATA "AS IS" AND ANY EXPRESS OR
; IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL UCAR/UNIDATA BE LIABLE FOR ANY SPECIAL,
; INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING
; FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT,
; NEGLIGENCE OR OTHER TORTUOUS ACTION, ARISING OUT OF OR IN CONNECTION
; WITH THE ACCESS, USE OR PERFORMANCE OF THIS SOFTWARE.

;+
; NAME:
;	ncbrowse
;
; PURPOSE:
;	This IDL procedure provides an interface for users to browse generic
;	NetCDF files. It allows textual display of data, one- and two-
;	dimensional plots of various types, and animations of these plots.
;
; AUTHOR:
;	Matt Segur (msegur@colorado.edu)
;
; CATEGORY:
;	Widgets.
;
; CALLING SEQUENCE:
;	ncbrowse[, filename]
;
; INPUTS:
;
; OPTIONAL INPUT PARAMETERS:
;	filename:  A string containing the name of the file to use. If not
;		   specified, a file selection widget is used.
;
; KEYWORD PARAMETERS:
;	GROUP:	The widget ID of the widget that calls ncbrowse.  When this
;		ID is specified, the death of the caller results in the death
;		of ncbrowse.
;	HELP:	This option will print this header and exit.
;
; OUTPUTS:
;
; OPTIONAL OUTPUT PARAMETERS:
;
; COMMON BLOCKS:
;	globs, datadisp_blk, helpdisp_blk, getvar_blk, prefs_blk, animate_blk,
;	filename_blk
;
; SIDE EFFECTS:
;	Initiates the XMANAGER if it is not already running.
;
; RESTRICTIONS:
;	Under IDL 3.5.x, it may be necessary to enlarge some windows manually
;	after initially invisible buttons have been created.
;
; PROCEDURE:
;	Create and register the widget and then exit.
;
; MODIFICATION HISTORY:
;	Created from a template written by: Steve Richards, January, 1991.
;-



;	Main event manager

PRO ncbrowse_ev, event

	; Main-level global vars
COMMON globs, ncdf_base, info_base, var_base, butt_base, vdbutton, vbutt_base, data_base, var_list, var_names, dim_names, cdfid, var_texwig, current_var, units, path_used
	; Stores ID of data display widget
COMMON datadisp_blk, datadisp_base
	; Stores ID of help widget
COMMON helpdisp_blk, helpdisp_base
	; Dimension selector's variables
COMMON getvar_blk, dimvar, svarval, getvar_base, ready, dim_data, labels, dim_varid, sliders, ptype_base, plotbutton, splotbutton, cplotbutton, wplotbutton, mplotbutton, tplotbutton, animate, animvar
	; Preferences + associated variables
COMMON prefs_blk, pref_base, button_base, downhill, clevels, clabel, cfill, autoscale, xrot, zrot, sort, frame_threshold, mproj, gifout, downbutton, labelbutton, fillbutton, ascalebutton, sortbutton, gifbutton, projections, projlabel
; add lego and legobutton to prefs_blk if you wish to use the lego flag to
; the surface plot (requires idl 3.6)
COMMON filename_blk, name_wig
	; filename selector's block

; the map projections
projections = ["Aitoff","Azimuthal","Conic","Cylindrical","Gnomonic", "Lambert","Mercator","Mollweide", "Orthographic", "Sinusoidal","Stereographic"]

widget_control, event.id, GET_UVALUE = eventval		;find the user value
							;of the widget where
							;the event occured
CASE eventval OF

  "EXIT": BEGIN						;Quit the program
	ncdf_close,cdfid				; close the file
	widget_control, event.top, /DESTROY		
   END
 
  "NFILE": BEGIN					;Select new file
	ncdf_close,cdfid				; close the file
	widget_control, event.top, /DESTROY		
	ncbrowse, PATH = path_used, SECOND = 1		;Passes old path onto
							; program's new
							; incarnation,
							;Let it know it's run
							; before so preferences
							; are kept
   END
 
  "PREFS": prefs_set, GROUP = ncdf_base			; Runs pref widget

  "HELP": BEGIN						; Main help
	present = xregistered('Xhelpdisp')
  	IF (present) THEN widget_control, /DESTROY, helpdisp_base
        helpdisp_base = widget_base(title=string('Help'), /column, group=ncdf_base, $
		xoffset=300, yoffset=300)
      	button = widget_button(helpdisp_base, value='Dismiss', EVENT_PRO = "helpdisp_ev")
	fin_text = ["	This NetCDF browser allows exploration of NetCDF files", $
		"and limited display of the data contained therein.", $
		"", $
		"	The first text field contains general information", $
		"about the file, including the number of dimensions, the", $
		"name and size of each dimension, the number of global", $
		"attributes, and the value of each attribute.", $
		"", $
		"	The 'Variables' list contains a list of all variables", $
		"in the file. Variables from this list, when selected, will", $
		"be described in the second text field. In addition, once a", $
		"variable is selected, the 'Plot' and 'View Data' buttons", $
		"become usable.", $
		"", $
		"	The 'Preferences' button allows the adjustment of", $
		"various settings. Preferences are NOT saved when quitting.", $
		"", $

		"	The second text field displays variable descriptions,", $
		"which include the variable's name and data type, the", $
		"dimensions in which the variable is defined, all attributes", $
		"of the variable, and the values associated with those", $
		"attributes.", $
		"", $
		"	The 'View Data' button displays in text format whatever", $
		"data is contained in the selected variable. No attempt is made", $
		"to format the data based on dimensionality; it is simply a", $
		"list.", $
		"", $
		"	The 'Plot' submenu allows graphical display of the", $
		"data contained in the selected variable. Options vary based", $
		"on the dimensionality of the variable, but can include", $
		"linear plots, which disply one variable in terms of one", $
		"dimension, and surface plots, which display one variable in", $
		"terms of two dimensions."]

	label = widget_text(helpdisp_base, ysize=35, xsize=65, /SCROLL, value = fin_text)
        widget_control, helpdisp_base, /REALIZE
	xmanager, 'Xhelpdisp', helpdisp_base
  END

  "var_list": BEGIN					;Events from the
							; variable list

	; Destroy the widgets in existence which may be associated with the
	; variable which was previously selected
  	IF (xregistered('Xdatadisp')) THEN widget_control, /DESTROY, datadisp_base
  	IF (xregistered('Xgetvar')) THEN widget_control, /DESTROY, getvar_base

	current_var=event.index
	var_text = make_array(200, /STRING)
	var_text(0) = "Variable Info:"
	k=1
	var_text(k) = var_names(current_var) 
	k=k+1
	;	Get information about the variable
	info = ncdf_varinq(cdfid, current_var)
	var_text(k) = "Data Type: "+String(info.datatype)
	k=k+1
	IF (info.ndims NE 0) THEN BEGIN
		FmtStr = '("Defined in Dimensions: ", 10(A0," "),$)'
		var_text(k) = String(Format=FmtStr,dim_names(info.dim(*)))
		END $
		ELSE  $
			var_text(k) = "Scalar Variable"  
	
	k=k+1

	;	Get attributes associated with the variable
	for j=0l,info.natts-1 DO BEGIN
		attname = ncdf_attname(cdfid,current_var,j)
		ncdf_attget,cdfid,current_var,attname,attvalue
		temp1=String(attvalue)
		IF (attvalue(0) EQ 40) THEN $
			 var_text(k) = String(' Attribute ', attname, ' = ')+temp1 $
		ELSE $
			 var_text(k) = String(' Attribute ', attname, ' = ', temp1) 
		k=k+1
	ENDFOR
	fin_text = var_text(0:k)
	widget_control, var_texwig, SET_VALUE = fin_text

	; Destroy the plot and view buttons if they exist, then create new
	; ones based on the newly selected variable
	widget_control, vdbutton, /SENSITIVE
	widget_control, vbutt_base, /DESTROY
	CASE info.ndims OF
		0: plot_menu = ""
		1: plot_menu = ["'Linear Plot'		1DPLOT"]
		2: plot_menu = ["'Surface Plot'		2DPLOT", $
				"'Linear Plot'		1DPLOT", $
				"'Animated Linear'	1DAPLOT"]
		ELSE: plot_menu = ["'Surface Plot'	2DPLOT", $
				"'Linear Plot'		1DPLOT", $
				"'Animated Surface'	2DAPLOT", $
				"'Animated Linear'	1DAPLOT"]
	ENDCASE
	XPdMenu, ["'Plot'	{",		$
			plot_menu,	$
			"}"],				$
		 butt_base, BASE = vbutt_base
  END
 
; these are the events created by the variable menus
  "DATA": BEGIN						; View data button
	present = xregistered('Xdatadisp')
  	IF (present) THEN widget_control, /DESTROY, datadisp_base
	widget_control, NCDF_base, HOURGLASS = 1

  	info = ncdf_varinq(cdfid, current_var)

        datadisp_base = widget_base(title=string('Data for ', info.name), /column, group=ncdf_base, $
		xoffset=300, yoffset=300)
      	button = widget_button(datadisp_base, value='Dismiss', EVENT_PRO = "datadisp_ev")
 	ncdf_varget, cdfid, info.name, data
	fin_text = string(data)
	label = widget_text(datadisp_base, ysize=30, xsize=30, /SCROLL, value = fin_text)
        widget_control, datadisp_base, /REALIZE
	xmanager, 'Xdatadisp', datadisp_base
	widget_control, NCDF_base, HOURGLASS = 0
	widget_control, datadisp_base, HOURGLASS = 0
  END
	
  '1DAPLOT': BEGIN					; 1d animation menu.
	animate = 1					; sets animate flag
	goto, oned					; and jumps to normal
  END							; plotting routine.

  '1DPLOT': BEGIN 					;Plot variable with
  							;	1 dim. domain 
	animate = 0
	oned:
	info = ncdf_varinq (cdfid, current_var)
	glob = ncdf_inquire (cdfid)
	IF (animate) THEN ndims = 2 ELSE ndims = 1
	IF (info.ndims NE ndims) THEN BEGIN		; If sliders are needed
		ready = 0
		present = xregistered('Xgetvar')
  		IF (present) THEN widget_control, /DESTROY, getvar_base
		dimvar = -1
		animvar = -1
		dim_name = make_array(info.ndims, /STRING)
		dim_size = make_array(info.ndims, /LONG)
		dim_varid = make_array(info.ndims, /LONG)

		; Creates the fix value array, copying from the old values if
		; possible
		temp = size(svarval)
		IF (temp(0) NE 1) THEN $
			svarval = make_array(info.ndims, /LONG, VALUE=0) $
		ELSE IF (temp(1) NE info.ndims) THEN BEGIN
			temp2 = svarval
			svarval = make_array(info.ndims, /LONG, VALUE=0)
			IF (temp(1) GT info.ndims) THEN $
				svarval(0:(info.ndims-1)) = temp2(0:(info.ndims-1)) $
			ELSE $
				svarval(0:(temp(1)-1)) = temp2(0:(temp(1)-1))
		END

		; the dimension select buttons are in this
		cbuttons = make_array(info.ndims)
		; the dimension sliders are in this
		sliders = make_array(info.ndims)
		; the slider labels are in this
		labels = make_array(info.ndims)

		getvar_base = widget_base(GROUP_LEADER = ncdf_base, TITLE = "Select Dimension to Plot; Fix additional Dims.", /ROW)
		ptype_base = widget_base(getvar_base, /COLUMN)
		exitbutton = widget_button(ptype_base, VALUE = "Exit", UVALUE = -2)
		helpbutton = widget_button(ptype_base, VALUE = "Help", UVALUE = -3)
		IF (NOT animate) THEN $
			plotbutton = widget_button(ptype_base, VALUE = "Plot", UVALUE = -1) $
		ELSE $
			plotbutton = widget_button(ptype_base, VALUE = "Animate", UVALUE = -4)
		widget_control, plotbutton, SENSITIVE = 0
		button_base = widget_base(getvar_base, /EXCLUSIVE)
		label_base = widget_base(getvar_base)
		slider_base = widget_base(getvar_base)

		; create the animation dimension selectors if animating
		IF (animate) THEN BEGIN
			abuttons = make_array(info.ndims)
			alabel = widget_label(getvar_base, VALUE = "Animate in:")
			anim_base = widget_base(getvar_base, /COLUMN)
			abutton_base = widget_base(anim_base, /EXCLUSIVE)
		END

		; finds the largest dimension and creates the dimension data
		; storage array accordingly
		maxdim=0
		for i=0l, (info.ndims-1) DO BEGIN
			ncdf_diminq, cdfid, info.dim(i), temp_name, temp_size
			dim_name(i) = temp_name
			dim_size(i) = temp_size
			IF (dim_size(i) GT maxdim) THEN maxdim = dim_size(i)
		ENDFOR
		dim_data = make_array(info.ndims,maxdim) 

		; sets up the button + slider (and animate button) for each 
		; dimension
		for i=0l, (info.ndims-1) DO BEGIN
			IF (dim_size(i) GT 1) THEN BEGIN
				cbuttons(i) = widget_button(button_base, VALUE = dim_name(i), UVALUE = i)
				IF (animate) THEN $
					abuttons(i) = widget_button(abutton_base, VALUE = dim_name(i), UVALUE = 1000000*(i+1))
			END
			ncdf_control, cdfid, /NOVERBOSE
			dim_varid(i) = ncdf_varid(cdfid, dim_name(i))
			ncdf_control, cdfid, /VERBOSE
			IF (dim_varid(i) EQ -1) THEN BEGIN
				for j=0l, (dim_size(i)-1) DO dim_data(i,j) = j 
				dim_varid(i) = glob.nvars
			END $
			ELSE BEGIN
				ncdf_varget, cdfid, dim_varid(i), temp_data
				for j=0l, (dim_size(i)-1) DO dim_data(i,j) = temp_data(j)
			END
			IF ((dim_size(i)-1) GE svarval(i)) THEN $
				slide_val = svarval(i) $
			ELSE BEGIN
				slide_val = 0
				svarval(i) = 0
			END
			IF (dim_size(i) GT 1) THEN $
				sliders(i) = widget_slider(slider_base, MINIMUM = 0, MAXIMUM=dim_size(i)-1, VALUE = slide_val, UVALUE = 1000*(i+1), /SUPPRESS, /DRAG, XOFFSET=0, YOFFSET = 28*i+5) $
			ELSE $
				sliders(i) = -1
			labels(i) = widget_label(label_base, VALUE = string(dim_data(i, svarval(i))," ",  units(dim_varid(i))), XOFFSET=0, YOFFSET = 28*i+5)
		ENDFOR
		widget_control, getvar_base, /REALIZE
		xmanager, 'Xgetvar', getvar_base, $
			EVENT_HANDLER = "getvar_ev"
		return
	END 
	; If not enough dimensions exist for fixing values to be necessary:
	IF (NOT animate) THEN BEGIN
		widget_control, NCDF_base, HOURGLASS = 1
		IF (gifout) THEN BEGIN
			set_plot, 'Z', /COPY
  			device, SET_RESOLUTION = [640, 512], SET_CHARACTER_SIZE = [6, 9]
		END
		onedplot, 0, 0, "", "auto" 	; normal plot
		widget_control, NCDF_base, HOURGLASS = 0
		IF (gifout) THEN BEGIN
			set_plot, 'X', /COPY
			save_base = widget_base(title = "Save GIF", /COLUMN, group= ncdf_base)
			junk = widget_label(save_base, VALUE = "Enter Filename:")
			name_wig = widget_text(save_base, ALL_EVENTS = 0, /EDITABLE, EVENT_PRO = "filename_ev", VALUE = "ncimage.gif", UVALUE = 1)
			junk2 = widget_button(save_base, VALUE = "Save", UVALUE = 1, EVENT_PRO = "filename_ev")
			junk3 = widget_button(save_base, VALUE = "Cancel", UVALUE = 0, EVENT_PRO = "filename_ev")
			widget_control, save_base, /REALIZE
		ENDIF
	END $
	ELSE BEGIN						; animation
		ready = 0
		present = xregistered('Xgetvar')
  		IF (present) THEN widget_control, /DESTROY, getvar_base
		getvar_base = widget_base(GROUP_LEADER = ncdf_base, TITLE = "Select Dimension to Animate.", /ROW)
		ptype_base = widget_base(getvar_base, /COLUMN)
		exitbutton = widget_button(ptype_base, VALUE = "Exit", UVALUE = -2)
		helpbutton = widget_button(ptype_base, VALUE = "Help", UVALUE = -3)
		plotbutton = widget_button(ptype_base, VALUE = "Animate", UVALUE = -4)
		widget_control, plotbutton, SENSITIVE = 0
		abuttons = make_array(info.ndims)
		alabel = widget_label(getvar_base, VALUE = "Animate in:")
		anim_base = widget_base(getvar_base, /COLUMN)
		abutton_base = widget_base(anim_base, /EXCLUSIVE)
		dim_name = make_array(info.ndims, /STRING)
		dim_size = make_array(info.ndims, /LONG)
		for i=0l, (info.ndims-1) DO BEGIN
			ncdf_diminq, cdfid, info.dim(i), temp_name, temp_size
			dim_name(i) = temp_name
			dim_size(i) = temp_size
			IF ((dim_size(i) GT 1) AND animate) THEN $
				abuttons(i) = widget_button(abutton_base, VALUE = dim_name(i), UVALUE = 1000000*(i+1))
		ENDFOR
		widget_control, getvar_base, /REALIZE
		dimvar = -2
		xmanager, 'Xgetvar', getvar_base, $
			EVENT_HANDLER = "getvar_ev"
		return
		
	END
	
  END

  '2DAPLOT': BEGIN					;2d animation
	animate = 1					; sets animate flag and
	goto, twod					; jumps to normal 2d
  END

  '2DPLOT': BEGIN 					;Plot variable with
  							;	2 dim. domain 
	animate = 0
	twod:
	info = ncdf_varinq (cdfid, current_var)
	glob = ncdf_inquire (cdfid)
	present = xregistered('Xgetvar')
  	IF (present) THEN widget_control, /DESTROY, getvar_base
	IF (info.ndims NE 2) THEN $
		getvar_base = widget_base(GROUP_LEADER = ncdf_base, TITLE = "Select Dimensions to Plot; Fix additional Dims.", /ROW) $
	ELSE $
		getvar_base = widget_base(GROUP_LEADER = ncdf_base, TITLE = "Plot Type", /ROW)
	ptype_base = widget_base(getvar_base, /COLUMN)
	exitbutton = widget_button(ptype_base, VALUE = "       Exit        ", UVALUE = -6)
	helpbutton = widget_button(ptype_base, VALUE = "       Help        ", UVALUE = -7)
	temp = size(svarval)

	; creates the fixed-value array, copying from the old values if possible
	IF (temp(0) NE 1) THEN $
		svarval = make_array(info.ndims, /LONG, VALUE=0)  $
	ELSE IF (temp(1) NE info.ndims) THEN BEGIN
		temp2 = svarval
		svarval = make_array(info.ndims, /LONG, VALUE=0)
		IF (temp(1) GT info.ndims) THEN $
			svarval(0:(info.ndims-1)) = temp2(0:(info.ndims-1)) $
		ELSE $
			svarval(0:(temp(1)-1)) = temp2(0:(temp(1)-1))
	END

	; these buttons will be desensitized later if necessary
	IF (NOT animate) THEN BEGIN
		wplotbutton = widget_button(ptype_base, VALUE = "Plot Wireframe", UVALUE = -1)
		splotbutton = widget_button(ptype_base, VALUE = "Plot Shaded Surface", UVALUE = -2)
		cplotbutton = widget_button(ptype_base, VALUE = "Plot Contour", UVALUE = -3)
		mplotbutton = widget_button(ptype_base, VALUE = "Plot Contour w/ Map", UVALUE = -4)
		tplotbutton = widget_button(ptype_base, VALUE = "Plot TV", UVALUE = -5)
	END $
	ELSE BEGIN
		wplotbutton = widget_button(ptype_base, VALUE = "Animate Wireframe", UVALUE = -8)
		splotbutton = widget_button(ptype_base, VALUE = "Animate Shaded Surface", UVALUE = -9)
		cplotbutton = widget_button(ptype_base, VALUE = "Animate Contour", UVALUE = -10)
		mplotbutton = widget_button(ptype_base, VALUE = "Animate Contour w/ Map", UVALUE = -11)
		tplotbutton = widget_button(ptype_base, VALUE = "Animate TV", UVALUE = -12)
	END
	IF (animate) THEN ndims = 3 ELSE ndims = 2
	IF (info.ndims NE ndims) THEN BEGIN		; if sliders are needed
		dimvar = -1
		animvar = -1

		; desensitizes the buttons just created
		widget_control, wplotbutton, SENSITIVE=0	
		widget_control, splotbutton, SENSITIVE=0
		widget_control, cplotbutton, SENSITIVE=0
		widget_control, mplotbutton, SENSITIVE=0
		widget_control, tplotbutton, SENSITIVE=0
		IF (NOT animate) THEN ready = [0, 1] $
		ELSE ready = [0, 0]
		dimvar = make_array(info.ndims, /INT)
		dim_name = make_array(info.ndims, /STRING)
		dim_size = make_array(info.ndims, /LONG)
		dim_varid = make_array(info.ndims, /LONG)
		button_base = widget_base(getvar_base, /NONEXCLUSIVE)
		cbuttons = make_array(info.ndims)
		sliders = make_array(info.ndims)
		labels = make_array(info.ndims)
		label_base = widget_base(getvar_base)
		slider_base = widget_base(getvar_base)
		IF (animate) THEN BEGIN			;create anim selectors
			abuttons = make_array(info.ndims)
			alabel = widget_label(getvar_base, VALUE = "Animate in:")
			anim_base = widget_base(getvar_base, /COLUMN)
			abutton_base = widget_base(anim_base, /EXCLUSIVE)
		END
		maxdim=0
		for i=0l, (info.ndims-1) DO BEGIN
			ncdf_diminq, cdfid, info.dim(i), temp_name, temp_size
			dim_name(i) = temp_name
			dim_size(i) = temp_size
			IF (dim_size(i) GT maxdim) THEN maxdim = dim_size(i)
		ENDFOR
		dim_data = make_array(info.ndims,maxdim) 
		for i=0l, (info.ndims-1) DO BEGIN	; set up sliders
			IF (dim_size(i) GT 1) THEN BEGIN
				cbuttons(i) = widget_button(button_base, VALUE = dim_name(i), UVALUE = i )
				IF (animate) THEN $
					abuttons(i) = widget_button(abutton_base, VALUE = dim_name(i), UVALUE = 1000000*(i+1))
			END
			ncdf_control, cdfid, /NOVERBOSE
			dim_varid(i) = ncdf_varid(cdfid, dim_name(i))
			ncdf_control, cdfid, /VERBOSE
			IF (dim_varid(i) EQ -1) THEN BEGIN
				for j=0l, (dim_size(i)-1) DO dim_data(i,j) = j 
				dim_varid(i) = glob.nvars
			END $
			ELSE BEGIN
				ncdf_varget, cdfid, dim_varid(i), temp_data
				for j=0l, (dim_size(i)-1) DO dim_data(i,j) = temp_data(j)
			END
			IF ((dim_size(i)-1) GE svarval(i)) THEN $
				slide_val = svarval(i) $
			ELSE BEGIN
				slide_val = 0
				svarval(i) = 0
			END
			IF (dim_size(i) GT 1) THEN $
				sliders(i) = widget_slider(slider_base, MINIMUM = 0, MAXIMUM=dim_size(i)-1,VALUE = slide_val, UVALUE = 1000*(i+1), /SUPPRESS, /DRAG, XOFFSET=0, YOFFSET = 28*i+5) $
			ELSE $
				sliders(i) = -1
			labels(i) = widget_label(label_base, VALUE = string(dim_data(i, svarval(i)), " ",  units(dim_varid(i))), XOFFSET = 0, YOFFSET = 28*i+5)
		ENDFOR
		widget_control, getvar_base, /REALIZE
		xmanager, 'Xgetvar', getvar_base, $
			EVENT_HANDLER = "getvar2_ev"
	END $
	ELSE BEGIN				; if sliders not needed
		IF (NOT animate) THEN BEGIN 
			ready=[2, 1]
			dimvar=[0,1]
		END $
		ELSE BEGIN
			widget_control, wplotbutton, SENSITIVE=0
			widget_control, splotbutton, SENSITIVE=0
			widget_control, cplotbutton, SENSITIVE=0
			widget_control, mplotbutton, SENSITIVE=0
			widget_control, tplotbutton, SENSITIVE=0
			abuttons = make_array(info.ndims)
			alabel = widget_label(getvar_base, VALUE = "Animate in:")
			anim_base = widget_base(getvar_base, /COLUMN)
			abutton_base = widget_base(anim_base, /EXCLUSIVE)
			dim_name = make_array(info.ndims, /STRING)
			dim_size = make_array(info.ndims, /LONG)
			for i=0l, (info.ndims-1) DO BEGIN
				ncdf_diminq, cdfid, info.dim(i), temp_name, temp_size
				dim_name(i) = temp_name
				dim_size(i) = temp_size
				IF ((dim_size(i) GT 1) AND animate) THEN $
					abuttons(i) = widget_button(abutton_base, VALUE = dim_name(i), UVALUE = 1000000*(i+1))
			ENDFOR
			ready = [2, 0]
			dimvar = [-2,-2,-2]
		END
		widget_control, getvar_base, /REALIZE
		xmanager, 'Xgetvar', getvar_base, $
			EVENT_HANDLER = "getvar2_ev"
	END
  END



  ELSE: message, "Event User Value Not Found"		;When an event occurs
							;in a widget that has
							;no user value in this
							;case statement, an
							;error message is shown
ENDCASE

END ; end of event handling 


; event handler for filename getter (used when saving gifs)
PRO filename_ev, event
COMMON filename_blk, name_wig

widget_control, event.id, GET_UVALUE = eventval		;find the user value

CASE eventval OF
	0:	widget_control, event.top, /DESTROY	; Cancel Button
	1:	BEGIN
		widget_control, name_wig, GET_VALUE = filename
		IF(n_elements(filename(0)) GT 0 ) THEN BEGIN
			widget_control, event.top, /HOURGLASS
			set_plot, 'Z', /COPY
			image = tvrd()
			device, /CLOSE
			write_gif, filename(0), image
			set_plot, 'X', /COPY
			widget_control, event.top, HOURGLASS = 0
			widget_control, event.top, /DESTROY
		END
	   END
ENDCASE
END


; event handler for prefs
PRO prefs_ev, event

COMMON prefs_blk, pref_base, button_base, downhill, clevels, clabel, cfill, autoscale, xrot, zrot, sort, frame_threshold, mproj, gifout, downbutton, labelbutton, fillbutton, ascalebutton, sortbutton, gifbutton, projections, projlabel

widget_control, event.id, GET_UVALUE = eventval		;find the user value

CASE eventval OF
	
	"EXIT":		widget_control, event.top, /DESTROY

	; buttons
  "XLOADCT": XLoadct, GROUP = event.top			;XLoadct is the library
							;routine that lets you
							;select and adjust the
							;color palette being
							;used.
	"GIFON":	BEGIN
				gifout = 1
				widget_control, gifbutton, SET_VALUE = "Output to: gif file", SET_UVALUE = "GIFOFF"
			END
	"GIFOFF":	BEGIN
				gifout = 0
				widget_control, gifbutton, SET_VALUE = "Output to: screen", SET_UVALUE = "GIFON"
			END
	"ASCALEON":	BEGIN
				autoscale = 1
				widget_control, ascalebutton, SET_VALUE = "Turn off animation single-scaling", SET_UVALUE = "ASCALEOFF"
			END
	"ASCALEOFF":	BEGIN
				autoscale = 0
				widget_control, ascalebutton, SET_VALUE = "Turn on animation single-scaling", SET_UVALUE = "ASCALEON"
			END
; uncomment this stuff to use the lego option to surface (requires idl 3.6)
;	"LEGOON":	BEGIN
;				lego = 1
;				widget_control, legobutton, SET_VALUE = "Turn off lego mode in wireframes", SET_UVALUE = "LEGOOFF"
;			END
;	"LEGOOFF":	BEGIN
;				lego = 0
;				widget_control, legobutton, SET_VALUE = "Turn on lego mode in wireframes", SET_UVALUE = "LEGOON"
;			END
	"SORTON":	BEGIN
				sort = 1
				widget_control, sortbutton, SET_VALUE = "Turn off sorting of animation dim", SET_UVALUE = "SORTOFF"
			END
	"SORTOFF":	BEGIN
				sort = 0
				widget_control, sortbutton, SET_VALUE = "Turn on sorting of animation dim", SET_UVALUE = "SORTON"
			END
	"DOWNHILLON":	BEGIN
			downhill = 1
			widget_control, downbutton, SET_VALUE = "Turn off downhill arrows in contour plots", SET_UVALUE = "DOWNHILLOFF"
			widget_control, labelbutton, SENSITIVE=0
			END
	"DOWNHILLOFF":	BEGIN
			downhill = 0
			widget_control, downbutton, SET_VALUE = "Turn on downhill arrows in contour plots", SET_UVALUE = "DOWNHILLON"
			widget_control, labelbutton, SENSITIVE = 1
			END
			
	"CLABELON":	BEGIN
				clabel = 1
				widget_control, labelbutton, SET_VALUE = "Turn off level labels in contour plots", SET_UVALUE = "CLABELOFF"
			END
	"CLABELOFF":	BEGIN
				clabel = 0
				widget_control, labelbutton, SET_VALUE = "Turn on level labels in contour plots", SET_UVALUE = "CLABELON"
			END
	"CFILLON":	BEGIN
			cfill = 1
			widget_control, fillbutton, SET_VALUE = "Turn off filled contours", SET_UVALUE = "CFILLOFF"
			widget_control, labelbutton, SENSITIVE = 0
			widget_control, downbutton, SENSITIVE = 0
			END
	"CFILLOFF":	BEGIN
			cfill = 0
			widget_control, fillbutton, SET_VALUE = "Turn on filled contours", SET_UVALUE = "CFILLON"
			widget_control, labelbutton, SENSITIVE = 1
			widget_control, downbutton, SENSITIVE = 1
			END

	; sliders
	"LEVELSLIDE":	clevels = event.value
	"XROTSLIDE":	xrot = event.value
	"ZROTSLIDE":	zrot = event.value
	"THRESHSLIDE":	frame_threshold = event.value

	; help
 	"HELP": BEGIN						; Main help
	present = xregistered('Xhelpdisp')
  	IF (present) THEN widget_control, /DESTROY, helpdisp_base
        helpdisp_base = widget_base(title=string('Help'), /column, group=pref_base, $
		xoffset=300, yoffset=300)
      	button = widget_button(helpdisp_base, value='Dismiss', EVENT_PRO = "helpdisp_ev")
	fin_text = ["	The preferences widget allows the user to adjust the", $
		"value of various preferences. These are:",$
		"'Adjust Palette': Customizes the palette, which is used in",$
		"		  filled contour, shaded surface, and TV plots.",$
		"'Output to:': Normally, graphical output goes to the screen.",$
		"	      This option sends plots to a gif file instead.",$
		"	      instead. Works only with plots, not animations.",$
;		This feature was removed for version compatibility
;		"'Lego mode': Turns on/off the lego option in wireframe plots,",$
;		"	     which produces box-style cells.",$
		"'Sorting in animation dim': Turns on/off the sorting of",$
		"			    frames in animation according to",$
		"			    the values of the animation",$
		"			    variable.",$
		"'Animation single-scaling': Turns on/off the use of a single",$
		"			    scale for all frames of an",$
		"			    animation. Tends to deaccentuate",$
		"			    values, but usually necessary.",$
		"'Filled contours': Turns on/off filling of contours in",$
		"		   contour plots. If this is on, downhill",$
		"		   arrows and level labels are not possible.",$
		"'Downhill arrows': Turns on/off arrows which point in the",$
		"		   'Downhill' direction in contour plots.",$
		"		   If this is on, level labels are mandatory.",$
		"'Level labels': Turn on/off labelling of contour levels.",$
		"'Levels in contour plots': Adjusts the number of equally",$
		"			   spaced levels displayed in",$
		"			   contour plots.",$
		"'X- and Z-axis angle of rotation': Adjust the angle at which",$
		"				   surface and shaded surface",$
		"				   plots are displayed.",$
		"'Max frames in animation': Threshold for frames in animation,",$
		"			   beyond which every other/third/etc",$
		"			   frame will be displayed. Animation",$
		"			   tends to be slow if frames exceed",$
		"			   available memory.",$
		"'Map projection': Changes the map projection used by the", $
		"		  'Plot Contour w/ Map' command."]

	label = widget_text(helpdisp_base, ysize=36, xsize=65, /SCROLL, value = fin_text)
        widget_control, helpdisp_base, /REALIZE
	xmanager, 'Xhelpdisp', helpdisp_base
  END
  "Aitoff":  BEGIN 			; map projections
	mproj = 0
	widget_control, projlabel, SET_VALUE = projections(mproj)
  END
  "Azimuthal":  BEGIN 			; map projections
	mproj = 1
	widget_control, projlabel, SET_VALUE = projections(mproj)
  END
  "Conic":  BEGIN 			; map projections
	mproj = 2
	widget_control, projlabel, SET_VALUE = projections(mproj)
  END
  "Cylindrical":  BEGIN 			; map projections
	mproj = 3
	widget_control, projlabel, SET_VALUE = projections(mproj)
  END
  "Gnomonic":  BEGIN 			; map projections
	mproj = 4
	widget_control, projlabel, SET_VALUE = projections(mproj)
  END
  "Lambert":  BEGIN 			; map projections
	mproj = 5
	widget_control, projlabel, SET_VALUE = projections(mproj)
  END
  "Mercator":  BEGIN 			; map projections
	mproj = 6
	widget_control, projlabel, SET_VALUE = projections(mproj)
  END
  "Mollweide":  BEGIN 			; map projections
	mproj = 7
	widget_control, projlabel, SET_VALUE = projections(mproj)
  END
  "Orthographic":  BEGIN 			; map projections
	mproj = 8
	widget_control, projlabel, SET_VALUE = projections(mproj)
  END
  "Sinusoidal":  BEGIN 			; map projections
	mproj = 9
	widget_control, projlabel, SET_VALUE = projections(mproj)
  END
  "Stereographic":  BEGIN 			; map projections
	mproj = 10
	widget_control, projlabel, SET_VALUE = projections(mproj)
  END
  
ENDCASE
END


; Event handler for the 1d plot widget
PRO getvar_ev, event

COMMON globs, ncdf_base, info_base, var_base, butt_base, vdbutton, vbutt_base, data_base, var_list, var_names, dim_names, cdfid, var_texwig, current_var, units, path_used
COMMON getvar_blk, dimvar, svarval, getvar_base, ready, dim_data, labels, dim_varid, sliders, ptype_base, plotbutton, splotbutton, cplotbutton, wplotbutton, mplotbutton, tplotbutton, animate, animvar
COMMON prefs_blk, pref_base, button_base, downhill, clevels, clabel, cfill, autoscale, xrot, zrot, sort, frame_threshold, mproj, gifout, downbutton, labelbutton, fillbutton, ascalebutton, sortbutton, gifbutton, projections, projlabel
COMMON animate_blk, animate_base
COMMON filename_blk, name_wig

widget_control, event.id, GET_UVALUE = eventval		;find the user value
							;of the widget where
							;the event occured
CASE eventval OF

  -1: BEGIN						; plot button
		widget_control, NCDF_base, HOURGLASS = 1
		IF (gifout) THEN BEGIN
			set_plot, 'Z', /COPY
  			device, SET_RESOLUTION = [640, 512], SET_CHARACTER_SIZE = [6, 9]
		END
		IF (ready) THEN onedplot, dimvar, svarval, "", "auto"
		widget_control, NCDF_base, HOURGLASS = 0
		IF (gifout) THEN BEGIN
			set_plot, 'X', /COPY
			save_base = widget_base(title = "Save GIF", /COLUMN, group= ncdf_base)
			junk = widget_label(save_base, VALUE = "Enter Filename:")
			name_wig = widget_text(save_base, ALL_EVENTS = 0, /EDITABLE, EVENT_PRO = "filename_ev", VALUE = "ncimage.gif", UVALUE = 1)
			junk2 = widget_button(save_base, VALUE = "Save", UVALUE = 1, EVENT_PRO = "filename_ev")
			junk3 = widget_button(save_base, VALUE = "Cancel", UVALUE = 0, EVENT_PRO = "filename_ev")
			widget_control, save_base, /REALIZE
		ENDIF
	END
  -2: BEGIN						; exit button
		widget_control, getvar_base, /DESTROY
	END
  -3: BEGIN						; help button
	present = xregistered('Xhelpdisp')
  	IF (present) THEN widget_control, /DESTROY, helpdisp_base
        helpdisp_base = widget_base(title=string('Help'), /column, group=ncdf_base, $
		xoffset=300, yoffset=300)
      	button = widget_button(helpdisp_base, value='Dismiss', EVENT_PRO = "helpdisp_ev")
	fin_text = ["	This widget allows the user to decide which dimension", $
		"should be used in plotting the variable if the variable is",$
		"defined in more dimensions than can be plotted. The check-",$
		"boxes correspond to the dimensions in which the variable is",$
		"defined. One of these boxes must be checked in order to",$
		"perform a surface plot; the selected variable will then be",$
		"plotted in terms of the selected dimension.",$
		"",$
		"	The sliders at right allow the user to specify the",$
		"values at which non-plotted dimensions will be fixed. The",$
		"sliders alongside the dimension which is selected has no",$
		"effect until the dimension is unselected.",$
		"",$
		"	The 'Plot' button, which becomes usable when the", $
		"appropriate number of dimensions has been selected, performs",$
		"the plot.", $
		"",$
		"	If you are animating instead of simply plotting, you",$
		"must also select the dimension along which you wish to",$
		"animate. Once you have done so, the 'Animate' button,",$
		"functionally identical to the 'Plot' button, becomes usable."]

	label = widget_text(helpdisp_base, ysize=22, xsize=65, /SCROLL, value = fin_text)
        widget_control, helpdisp_base, /REALIZE
	xmanager, 'Xhelpdisp', helpdisp_base
   END	
  -4: BEGIN						; animate button
		IF (ready) then BEGIN
			; sometimes scaling and creating frames is slow.
			; Hourglass the cursor to let the user know it may
			; be a while 
			widget_control, NCDF_base, HOURGLASS = 1

			IF (dimvar EQ -2) THEN BEGIN
				CASE animvar OF
					0: dimvar = 1
					1: dimvar = 0
				ENDCASE
				svarval = [0,0]
			END
			present = xregistered('NCAnimate')
  			IF (present) THEN widget_control, /DESTROY, animate_base
			info = ncdf_varinq (cdfid, current_var)
			glob = ncdf_inquire (cdfid)
			ncdf_diminq, cdfid, info.dim(animvar), dim_name, dim_size
			ncdf_diminq, cdfid, info.dim(dimvar), dim2_name, dim2_size
			ncdf_control, cdfid, /NOVERBOSE
			dim_varid = ncdf_varid(cdfid, dim_name)
			ncdf_control, cdfid, /VERBOSE
			IF (dim_varid EQ -1) THEN  BEGIN
				dim_data = SINDGEN(dim_size) 
				dim_varid = glob.nvars
			END $
			ELSE ncdf_varget, cdfid, dim_varid, dim_data
			animate_base = widget_base (GROUP = getvar_base, TITLE = "Animation: " + info.name)
			; If too many frames are created the process becomes
			; painfully slow. This takes every (other/3rd/4th/etc)
			; frame as necessary to get the number of frames below
			; the limit
			step = 1
			frames = dim_size / step
			WHILE (frames GT frame_threshold) DO BEGIN
				step = step + 1
				frames = dim_size / step
			END
			animate_wig = cw_animate(animate_base, 640, 512, frames)
			; If autoscale is set, find the largest and smallest
			; values in the data to be animated and use these as
			; min and max for all frames
			IF (autoscale) THEN BEGIN
				; yes, these names are correct. Max will be
				; raised and min lowered using the data
				min = 9.0*10.0^37	; very big
				max = -9.0*10.0^37	; very big negatively

				glob = ncdf_inquire( cdfid )
 				for j=0l,info.natts-1 DO BEGIN
					attname = ncdf_attname(cdfid,current_var,j)
					IF (attname EQ '_FillValue') THEN BEGIN
						ncdf_attget,cdfid,current_var,attname,attvalue
						fillval = attvalue
					END
				ENDFOR

 				temp = size(fillval)
				IF (temp(1) NE 0) THEN fill = 1 $
				ELSE fill = 0
				for i=0l, (frames-1) DO BEGIN
					svarval(animvar)=i*step
					info = ncdf_varinq (cdfid, current_var)
					offset = svarval
					offset(dimvar) = 0	
					count = make_array(info.ndims, /LONG, VALUE=1)	
					count(dimvar) = dim2_size
					ncdf_varget, cdfid, current_var, var_data , OFFSET=offset, COUNT=count
					IF (fill) THEN rem_fill_vals,var_data, fillval
					for j=0l, (dim2_size-1) DO BEGIN
						IF (var_data(j) GT max) THEN max = var_data(j)
						IF (var_data(j) LT min) THEN min = var_data(j)
					END
				ENDFOR
			END

			; sort the values increasingly if sort is set
			IF(sort) THEN access_array = SORT(dim_data) $
			ELSE access_array = INDGEN (dim_size)
			window, 1, XSIZE = 640, YSIZE = 512, /PIXMAP
			for i=0l, (frames-1) DO BEGIN 	;create the frames
				svarval(animvar)=access_array(i*step)
				IF (autoscale) THEN $
					onedplot, dimvar,svarval, dim_name + " = " + string(dim_data(access_array(i*step))), [min, max]  $
				ELSE $
					onedplot, dimvar,svarval, dim_name + " = " + string(dim_data(access_array(i*step))), "auto"
				cw_animate_load, animate_wig, FRAME = i, $
					WINDOW = [1]
			ENDFOR
			; turn of the hourglass cursor
			widget_control, NCDF_base, HOURGLASS = 0

			widget_control, animate_base, /realize
			; run the animation
			cw_animate_run, animate_wig
			xmanager, 'NCAnimate', animate_base, EVENT_HANDLER = "anim_ev", GROUP_LEADER = NCDF_base
		END
	END
  ELSE: BEGIN						
	; slider and selector events have positive values depending on the
	; dimension concerned. Currently up to 999 dimensions are allowed.
	; This should be far more than would ever be needed

	IF (1000 GT eventval) THEN BEGIN		; dim selector buttons
		i=eventval

		; ready keeps track of whether 1 dimension and 1 animation
		; dimension have been selected. prevready is the value before
		; the event is processed, which allows the procedure to
		; determine if the plot button should be (de)sensitized
		prevready = ready
							
		IF (event.select) then BEGIN
			dimvar = i
			IF (animate) THEN BEGIN
				IF ((animvar NE -1) AND (animvar NE dimvar)) THEN BEGIN
					ready = 1 
					widget_control, plotbutton, SENSITIVE = 1
				END $
				ELSE ready = 0
			END $
			ELSE BEGIN
				ready = 1
				widget_control, plotbutton, SENSITIVE = 1
			END
			IF (sliders(i) NE -1) THEN $
				widget_control, sliders(i), SENSITIVE = 0
			IF ((ready EQ 0) AND (prevready EQ 1)) THEN $
				widget_control, plotbutton, SENSITIVE = 0
		END $
		ELSE BEGIN
			ready = 0
			IF ((animvar NE dimvar) AND (sliders(i) NE -1)) THEN $
				widget_control, sliders(i), SENSITIVE = 1
			dimvar = -4
		END
		IF ((ready EQ 0) AND (prevready EQ 1)) THEN $
			widget_control, plotbutton, SENSITIVE = 0
		RETURN
	END
        IF (1000000 GT eventval) THEN BEGIN             ; dim sliders
                i=(eventval/1000)-1
                widget_control, labels(i),SET_VALUE = string(dim_data(i,event.value), " ", units(dim_varid(i)))
                IF (not event.drag) THEN svarval(i)=event.value
                RETURN
        END
	IF (1000000000 GT eventval) THEN BEGIN		; animate selectors
		i=(eventval/1000000)-1
		prevready = ready
		IF (event.select) then BEGIN
			animvar = i
			IF ((dimvar NE -1) AND (animvar NE dimvar)) THEN BEGIN
				ready = 1 
				widget_control, plotbutton, SENSITIVE = 1
			END $
			ELSE ready = 0
			IF ((dimvar NE -2) AND (sliders(i) NE -1)) THEN $
				widget_control, sliders(i), SENSITIVE = 0
		END $
		ELSE BEGIN
			IF ((animvar NE dimvar) AND (dimvar NE -2) AND (sliders(i) NE -1)) THEN $
				widget_control, sliders(i), SENSITIVE = 1
			info = ncdf_varinq(cdfid, current_var)
			IF (info.ndims EQ 2) THEN dimvar = -2
			animvar = -3
			ready = 0
		END
		IF ((ready EQ 0) AND (prevready EQ 1)) THEN $
			widget_control, plotbutton, SENSITIVE = 0
	END
   END	
ENDCASE 
END


; Event handler for the 2d plot widget
PRO getvar2_ev, event

COMMON globs, ncdf_base, info_base, var_base, butt_base, vdbutton, vbutt_base, data_base, var_list, var_names, dim_names, cdfid, var_texwig, current_var, units, path_used
COMMON prefs_blk, pref_base, button_base, downhill, clevels, clabel, cfill, autoscale, xrot, zrot, sort, frame_threshold, mproj, gifout, downbutton, labelbutton, fillbutton, ascalebutton, sortbutton, gifbutton, projections, projlabel
COMMON getvar_blk, dimvar, svarval, getvar_base, ready, dim_data, labels, dim_varid, sliders, ptype_base, plotbutton, splotbutton, cplotbutton, wplotbutton, mplotbutton, tplotbutton, animate, animvar
COMMON animate_blk, animate_base
COMMON filename_blk, name_wig

widget_control, event.id, GET_UVALUE = eventval		;find the user value
							;of the widget where
							;the event occured
prevready = ready
CASE eventval OF

  -1: BEGIN				; -1 to -5 are the normal plot buttons
		widget_control, NCDF_base, HOURGLASS = 1
		IF (gifout) THEN set_plot, 'Z', /COPY
		twodplot, dimvar, svarval, 0, "", "auto", 0
		widget_control, NCDF_base, HOURGLASS = 0
		IF (gifout) THEN BEGIN
			set_plot, 'X', /COPY
			save_base = widget_base(title = "Save GIF", /COLUMN, group= ncdf_base)
			junk = widget_label(save_base, VALUE = "Enter Filename:")
			name_wig = widget_text(save_base, ALL_EVENTS = 0, /EDITABLE, EVENT_PRO = "filename_ev", VALUE = "ncimage.gif", UVALUE = 1)
			junk2 = widget_button(save_base, VALUE = "Save", UVALUE = 1, EVENT_PRO = "filename_ev")
			junk3 = widget_button(save_base, VALUE = "Cancel", UVALUE = 0, EVENT_PRO = "filename_ev")
			widget_control, save_base, /REALIZE
		ENDIF
	END
  -2: BEGIN
		widget_control, NCDF_base, HOURGLASS = 1
		IF (gifout) THEN set_plot, 'Z', /COPY
		twodplot, dimvar, svarval, 1, "", "auto", 0
		widget_control, NCDF_base, HOURGLASS = 0
		IF (gifout) THEN BEGIN
			set_plot, 'X', /COPY
			save_base = widget_base(title = "Save GIF", /COLUMN, group= ncdf_base)
			junk = widget_label(save_base, VALUE = "Enter Filename:")
			name_wig = widget_text(save_base, ALL_EVENTS = 0, /EDITABLE, EVENT_PRO = "filename_ev", VALUE = "ncimage.gif", UVALUE = 1)
			junk2 = widget_button(save_base, VALUE = "Save", UVALUE = 1, EVENT_PRO = "filename_ev")
			junk3 = widget_button(save_base, VALUE = "Cancel", UVALUE = 0, EVENT_PRO = "filename_ev")
			widget_control, save_base, /REALIZE
		ENDIF
	END
  -3: BEGIN
		widget_control, NCDF_base, HOURGLASS = 1
		IF (gifout) THEN set_plot, 'Z', /COPY
		twodplot, dimvar, svarval, 2, "", "auto", 0
		widget_control, NCDF_base, HOURGLASS = 0
		IF (gifout) THEN BEGIN
			set_plot, 'X', /COPY
			save_base = widget_base(title = "Save GIF", /COLUMN, group= ncdf_base)
			junk = widget_label(save_base, VALUE = "Enter Filename:")
			name_wig = widget_text(save_base, ALL_EVENTS = 0, /EDITABLE, EVENT_PRO = "filename_ev", VALUE = "ncimage.gif", UVALUE = 1)
			junk2 = widget_button(save_base, VALUE = "Save", UVALUE = 1, EVENT_PRO = "filename_ev")
			junk3 = widget_button(save_base, VALUE = "Cancel", UVALUE = 0, EVENT_PRO = "filename_ev")
			widget_control, save_base, /REALIZE
		ENDIF
	END
  -4: BEGIN
		widget_control, NCDF_base, HOURGLASS = 1
		IF (gifout) THEN set_plot, 'Z', /COPY
		twodplot, dimvar, svarval, 3, "", "auto", 0
		widget_control, NCDF_base, HOURGLASS = 0
		IF (gifout) THEN BEGIN
			set_plot, 'X', /COPY
			save_base = widget_base(title = "Save GIF", /COLUMN, group= ncdf_base)
			junk = widget_label(save_base, VALUE = "Enter Filename:")
			name_wig = widget_text(save_base, ALL_EVENTS = 0, /EDITABLE, EVENT_PRO = "filename_ev", VALUE = "ncimage.gif", UVALUE = 1)
			junk2 = widget_button(save_base, VALUE = "Save", UVALUE = 1, EVENT_PRO = "filename_ev")
			junk3 = widget_button(save_base, VALUE = "Cancel", UVALUE = 0, EVENT_PRO = "filename_ev")
			widget_control, save_base, /REALIZE
		ENDIF
	END
  -5: BEGIN
		widget_control, NCDF_base, HOURGLASS = 1
		IF (gifout) THEN set_plot, 'Z', /COPY
		twodplot, dimvar, svarval, 4, "", "auto", 0
		widget_control, NCDF_base, HOURGLASS = 0
		IF (gifout) THEN BEGIN
			set_plot, 'X', /COPY
			save_base = widget_base(title = "Save GIF", /COLUMN, group= ncdf_base)
			junk = widget_label(save_base, VALUE = "Enter Filename:")
			name_wig = widget_text(save_base, ALL_EVENTS = 0, /EDITABLE, EVENT_PRO = "filename_ev", VALUE = "ncimage.gif", UVALUE = 1)
			junk2 = widget_button(save_base, VALUE = "Save", UVALUE = 1, EVENT_PRO = "filename_ev")
			junk3 = widget_button(save_base, VALUE = "Cancel", UVALUE = 0, EVENT_PRO = "filename_ev")
			widget_control, save_base, /REALIZE
		ENDIF
	END
  -6: BEGIN						; exit button
		widget_control, getvar_base, /DESTROY
	END
  -7: BEGIN 						;help button
	present = xregistered('Xhelpdisp')
  	IF (present) THEN widget_control, /DESTROY, helpdisp_base
        helpdisp_base = widget_base(title=string('Help'), /column, group=ncdf_base, $
		xoffset=300, yoffset=300)
      	button = widget_button(helpdisp_base, value='Dismiss', EVENT_PRO = "helpdisp_ev")
	fin_text = ["	This widget allows the user to decide which dimensions", $
		"should be used in plotting the variable if the variable is",$
		"defined in more dimensions than can be plotted. The check-",$
		"boxes correspond to the dimensions in which the variable is",$
		"defined. Two of these boxes must be checked in order to",$
		"perform a surface plot; the selected variable will then be",$
		"plotted in terms of the selected dimensions.",$
		"",$
		"	The sliders at right allow the user to specify the",$
		"values at which non-plotted dimensions will be fixed. Sliders",$
		"alongside dimensions which are selected have no effect until",$
		"the dimension is unselected.",$
		"",$
		"	The 'Plot Surface', 'Plot Shaded Surface', 'Plot Contour',",$
		"'Plot Contour w/ Map', and 'Plot TV' buttons, which become", $
		"usable when the appropriate number of dimensions have been",$
		"selected, perform the plot and determine the type of plot",$
		"that will be created. In the case of 'Plot Contour w/ Map',",$
		"a projection of the earth's continents is plotted under the",$
		"data. For best results, data plotted in this way should be in",$
		"'lon' and 'lat' dimensions. Otherwise data may be meaningless.", $
		"",$
		"	If you are animating, you must also select the",$
		"dimension along which you wish to animate. Once you have done",$
		"so, 'Animate' buttons become usable, which are functionally",$
		"identical to their 'Plot' counterparts."]

	label = widget_text(helpdisp_base, ysize=27, xsize=65, /SCROLL, value = fin_text)
        widget_control, helpdisp_base, /REALIZE
	xmanager, 'Xhelpdisp', helpdisp_base
		
	END
  ELSE: BEGIN
	; sliders and selectors have positive values depending on the dimension
	; concerned. Up to 999 dimensions are allowed.

	; the animate buttons have values -8 to -12
	IF (0 GT eventval) THEN BEGIN			; animate buttons
		IF ((ready(0) EQ 2) AND (ready(1) EQ 1)) then BEGIN
			IF(dimvar(0) EQ -2) THEN BEGIN	
				dimvar = [1,1,1]
				dimvar(animvar) = 0
				svarval = [0,0,0]
			END
			present = xregistered('NCAnimate')
  			IF (present) THEN widget_control, /DESTROY, animate_base
			;scaling/loading frames can be slow. hourglass the
			; cursor to let the user know it may be a while
			widget_control, NCDF_base, /HOURGLASS

			info = ncdf_varinq (cdfid, current_var)
			glob = ncdf_inquire (cdfid)
			ncdf_diminq, cdfid, info.dim(animvar), dim_name, dim_size
			ncdf_control, cdfid, /NOVERBOSE
			dim_varid = ncdf_varid(cdfid, dim_name)
			ncdf_control, cdfid, /VERBOSE
			IF (dim_varid EQ -1) THEN  BEGIN
				dim_data = SINDGEN(dim_size) 
				dim_varid = glob.nvars
			END $
			ELSE ncdf_varget, cdfid, dim_varid, dim_data
			animate_base = widget_base (GROUP = getvar_base, TITLE = "Animation: " + info.name)
			step = 1
			; if too many frames are created the process can be
			; painfully slow. There seems to be a threshold of
			; about 20 for me, but it's adjustable. This takes
			; every (other/3rd/4th/etc) frame as necessary to
			; insure few enough frames)
			frames = dim_size / step
			WHILE (frames GT frame_threshold) DO BEGIN
				step = step + 1
				frames = dim_size / step
			END

			; if autoscale is set, find the largest and smallest
			; values in the data and use them as the range for all
			; frames
			IF (autoscale) THEN BEGIN
				; yes, these names are correct. Max will be
				; raised and min lowered using the data
				min = 9.0*10.0^37	; very big
				max = -9.0*10.0^37	; very big negatively
				glob = ncdf_inquire( cdfid )
				info = ncdf_varinq (cdfid, current_var)
				dims = make_array(2, /INT)

				; changes the dimvar binary array to a
				; two element array of the dimensions to be
				; plotted against
				j=0
				FOR k=0, (info.ndims-1) DO BEGIN
					IF (dimvar(k) EQ 1) THEN BEGIN
						dims(j) = k
						j=j+1
					END
				ENDFOR
				; sort the dimensions
				IF (dims(0) GT dims(1)) THEN BEGIN
					temp = dims(0)
					dims(0) = dims(1)
					dims(1) = temp
				END
				ncdf_diminq, cdfid, info.dim(dims(0)), dim1_name, dim1_size
				ncdf_diminq, cdfid, info.dim(dims(1)), dim2_name, dim2_size
				count = make_array(info.ndims, /LONG, VALUE=1)	
				count(dims(0)) = dim1_size
				count(dims(1)) = dim2_size
 				for j=0l,info.natts-1 DO BEGIN
					attname = ncdf_attname(cdfid,current_var,j)
					IF (attname EQ '_FillValue') THEN BEGIN
						ncdf_attget,cdfid,current_var,attname,attvalue
						fillval = attvalue
					END
				ENDFOR

 				temp = size(fillval)
				IF (temp(1) NE 0) THEN fill = 1 $
				ELSE fill = 0

				for i=0l, (frames-1) DO BEGIN 
					svarval(animvar)=i*step
					offset = svarval
					offset(dims(0)) = 0	
					offset(dims(1)) = 0
					ncdf_varget, cdfid, current_var, var_data , OFFSET=offset, COUNT=count

  ; the ncdf_varget procedure returns 2d slices with additional 1 element
  ; dimensions unless they are trailing. This mess removes those extra
  ; dimensions. p_data ends up as a 2d array containing the values to be plotted
					p_data = make_array(dim1_size, dim2_size)
					command = "p_data(*,*) = var_data("
					FOR n=0,(info.ndims-2) DO BEGIN
						command = command + string('0:(count(',n,')-1),')
					ENDFOR
					command = command + string('0:(count(',n,')-1))')
					R = execute(command)

					IF (fill) THEN rem_fill_vals,p_data, fillval
					FOR l=0, (dim1_size-1) DO $
						FOR m=0, (dim2_size-1) DO BEGIN
							IF (p_data(l,m) GT max) THEN max = p_data(l,m)
							IF (p_data(l,m) LT min) THEN min = p_data(l,m)
						END
				ENDFOR
			END
			IF (eventval NE -12) THEN $
				animate_wig = cw_animate(animate_base, 640, 512, frames) $
			ELSE $
				animate_wig = cw_animate(animate_base, dim1_size, dim2_size, frames) 
			CASE eventval OF ; convert event value to plot type
				-8: ptype = 0
				-9: ptype = 1
				-10: ptype = 2
				-11: ptype = 3
				-12: ptype = 4
			ENDCASE

			; sort the data increasingly if sort is selected
			IF(sort) THEN access_array = SORT(dim_data) $
			ELSE access_array = INDGEN (dim_size)

			; create the frames
			IF (ptype NE 4) THEN $
				window, 1, XSIZE = 640, YSIZE = 512, /PIXMAP
			for i=0l, (frames-1) DO BEGIN
				svarval(animvar)=access_array(i*step)
				IF (autoscale) THEN $
					twodplot, dimvar,svarval, ptype, dim_name +" =  "+ string(dim_data(access_array(i*step))), [min,max] , 1 $
				ELSE $
					twodplot, dimvar,svarval, ptype, dim_name +" =  "+ string(dim_data(access_array(i*step))), "auto", 1
				cw_animate_load, animate_wig, FRAME = i, $
					WINDOW = [1]
			END
			widget_control, animate_base, /realize

			; turn off the hourglass cursor
			widget_control, NCDF_base, HOURGLASS = 0

			; do the animation
			cw_animate_run, animate_wig
			xmanager, 'NCAnimate', animate_base, EVENT_HANDLER = "anim_ev", GROUP_LEADER = NCDF_base
		END
		RETURN
	END
	IF (1000 GT eventval) THEN BEGIN		; dim selector buttons
		i=eventval
		IF (event.select) then BEGIN
			dimvar(i) = 1
			IF ((animate) AND (animvar EQ i)) THEN ready(1) = 0
			ready(0) = ready(0) + 1
			IF (sliders(i) NE -1) THEN $
				widget_control, sliders(i), SENSITIVE = 0
		END $
		ELSE BEGIN
			dimvar(i) = 0
			IF ((animate) AND (animvar EQ i)) THEN ready(1) = 1
			ready(0) = ready(0) - 1
			IF ((animvar NE i) AND (sliders(i) NE -1)) THEN $
				widget_control, sliders(i), SENSITIVE = 1
		END
		goto, check_ready 			; checks whether
							; 2 dims and 1 anim-
							; dim are selected,
							;greys/ungreys plot
							;buttons accordingly
	END
	IF (1000000 GT eventval) THEN BEGIN		; dim sliders
		i=(eventval/1000)-1
		widget_control, labels(i),SET_VALUE = string(dim_data(i,event.value), " ",  units(dim_varid(i)))
		IF (not event.drag) THEN svarval(i)=event.value 
		goto, check_ready
	END
	IF (1000000000 GT eventval) THEN BEGIN		; animate selectors
		i=(eventval/1000000)-1
		info = ncdf_varinq(cdfid, current_var)
		IF (event.select) then BEGIN
			animvar = i
			ready(1) = 0
			for j=0l, (info.ndims-1) DO BEGIN
				IF ((dimvar(j) NE 1) AND (j EQ animvar)) THEN BEGIN
					ready(1) = 1 
				END
			END
			IF ((dimvar(0) NE -2) AND (sliders(i) NE -1)) THEN $
				widget_control, sliders(i), SENSITIVE = 0
		END $
		ELSE BEGIN
			animvar = -2
			IF (info.ndims EQ 3) THEN dimvar = [-2, -2, -2]
			ready(1) = 0
			IF ((dimvar(i) NE 1) AND (dimvar(0) NE -2)) THEN $
				widget_control, sliders(i), SENSITIVE = 1
		END
	END
   END	
ENDCASE 

check_ready:
IF ((prevready(0) EQ 2) AND (prevready(1) EQ 1)) THEN BEGIN
	IF ((ready(0) NE 2) OR (ready(1) NE 1)) THEN BEGIN
		widget_control, wplotbutton, SENSITIVE = 0
		widget_control, splotbutton, SENSITIVE = 0
		widget_control, cplotbutton, SENSITIVE = 0
		widget_control, mplotbutton, SENSITIVE = 0
		widget_control, tplotbutton, SENSITIVE = 0
	END
  END $
ELSE BEGIN
	IF ((ready(0) EQ 2) AND (ready(1) EQ 1)) THEN BEGIN
	widget_control, wplotbutton, SENSITIVE = 1
	widget_control, splotbutton, SENSITIVE = 1
	widget_control, cplotbutton, SENSITIVE = 1
	widget_control, mplotbutton, SENSITIVE = 1
	widget_control, tplotbutton, SENSITIVE = 1
  END
END
END


; Event manager for data display widget. The only event this can see is the
; dismiss button
PRO datadisp_ev, ev
  WIDGET_CONTROL, ev.top, /DESTROY
END


; Event manager for help widget. The only event this can see is the
; dismiss button
PRO helpdisp_ev, ev
  WIDGET_CONTROL, ev.top, /DESTROY
END

PRO anim_ev, ev
; The only event that can be seen by this application is the "DONE"
; event from the CW_ANIMATION cluster.
 
  widget_control, /DESTROY, ev.top
END



; sets up the prefs base 
PRO prefs_set, GROUP = GROUP
COMMON prefs_blk, pref_base, button_base, downhill, clevels, clabel, cfill, autoscale, xrot, zrot, sort, frame_threshold, mproj, gifout, downbutton, labelbutton, fillbutton, ascalebutton, sortbutton, gifbutton, projections, projlabel


present = xregistered('Xprefs')
IF (present) THEN widget_control, /DESTROY, pref_base
pref_base = widget_base(title=string('Preferences'), /ROW, GROUP=group)
nonproj_base = widget_base(pref_base, /COLUMN)
button_base = widget_base(nonproj_base,  /COLUMN)
slider_base = widget_base(nonproj_base,  /COLUMN)
proj_base = widget_base(pref_base,  /COLUMN)
junk = widget_label(proj_base, VALUE = "Map Projection:")
projlabel = widget_label(proj_base, VALUE = projections(mproj))
proj_butt_base = widget_base(proj_base,  /COLUMN, /EXCLUSIVE)
pbuttons = make_array(11)

for i=0l, 10 DO pbuttons(i) = widget_button(proj_butt_base, VALUE = projections(i), UVALUE = projections(i))
exitbutton = widget_button(button_base, VALUE = "Exit", UVALUE = "EXIT")

helpbutton = widget_button (button_base, VALUE = "Help", UVALUE = "HELP")
palbutton = widget_button (button_base, VALUE = "Adjust Palette", UVALUE = "XLOADCT")

; all of these buttons change based on the current value of the pref

; uncomment this to use lego option
;CASE lego OF
;	0: legobutton = widget_button(button_base, VALUE = "Turn on lego mode in wireframes", UVALUE = "LEGOON")
;	ELSE: legobutton = widget_button(button_base, VALUE = "Turn off lego mode in wireframes", UVALUE = "LEGOOFF")
;ENDCASE

CASE gifout OF
	0: gifbutton = widget_button(button_base, VALUE = "Output to: screen", UVALUE = "GIFON")
	ELSE: gifbutton = widget_button(button_base, VALUE = "Output to: gif file", UVALUE = "GIFOFF")
ENDCASE

CASE sort OF
	0: sortbutton = widget_button(button_base, VALUE = "Turn on sorting in animation dim", UVALUE = "SORTON")
	ELSE: sortbutton = widget_button(button_base, VALUE = "Turn off sorting in animation dim", UVALUE = "SORTOFF")
ENDCASE

CASE autoscale OF
	0: ascalebutton = widget_button(button_base, VALUE = "Turn on animation single-scaling", UVALUE = "ASCALEON")
	ELSE: ascalebutton = widget_button(button_base, VALUE = "Turn off animation single-scaling", UVALUE = "ASCALEOFF")
ENDCASE

CASE cfill OF
	0: fillbutton = widget_button(button_base, VALUE = "Turn on filled contours", UVALUE = "CFILLON")
	ELSE: fillbutton = widget_button(button_base, VALUE = "Turn off filled contours", UVALUE = "CFILLOFF")
ENDCASE

CASE downhill OF
	0: downbutton = widget_button(button_base, VALUE = "Turn on downhill arrows in contour plots", UVALUE = "DOWNHILLON")
	ELSE: downbutton = widget_button(button_base, VALUE = "Turn off downhill arrows in contour plots", UVALUE = "DOWNHILLOFF")
ENDCASE

CASE clabel OF
	0: labelbutton = widget_button(button_base, VALUE = "Turn on level labels in contour plots", UVALUE = "CLABELON")
	ELSE: labelbutton = widget_button(button_base, VALUE = "Turn off level labels in contour plots", UVALUE = "CLABELOFF")
ENDCASE

IF (cfill EQ 1) THEN BEGIN
	 widget_control, downbutton, SENSITIVE = 0
	 widget_control, labelbutton, SENSITIVE = 0
END
IF (downhill EQ 1) THEN BEGIN
	 widget_control, labelbutton, SENSITIVE = 0
END
; sliders for the non-binary prefs

level_slider = widget_slider(slider_base, MINIMUM = 1, MAXIMUM=29,VALUE = clevels, UVALUE = "LEVELSLIDE")
levellabel = widget_label(slider_base, VALUE = "Number of Levels in Contour Plots")
xrot_slider = widget_slider(slider_base, MINIMUM = -180, MAXIMUM=180,VALUE = xrot, UVALUE = "XROTSLIDE")
xrotlabel = widget_label(slider_base, VALUE = "X-axis angle of rotation (surfaces)")
zrot_slider = widget_slider(slider_base, MINIMUM = -180, MAXIMUM=180,VALUE = zrot, UVALUE = "ZROTSLIDE")
zrotlabel = widget_label(slider_base, VALUE = "Z-axis angle of rotation (surfaces)")
thresh_slider =  widget_slider(slider_base, MINIMUM = 4, MAXIMUM=100,VALUE = frame_threshold, UVALUE = "THRESHSLIDE")
threshlabel = widget_label(slider_base, VALUE = "Max frames in animation (above 20 may hurt performance)")

widget_control, pref_base, /REALIZE
xmanager, 'Xprefs', pref_base, EVENT_HANDLER = "prefs_ev"
END

 


; get basic file information (number of dims, sizes, etc)
; adapted from the ncdf_cat sample program

PRO ncdf_cat2

COMMON globs, ncdf_base, info_base, var_base, butt_base, vdbutton, vbutt_base, data_base, var_list, var_names, dim_names, cdfid, var_texwig, current_var, units, path_used

	glob = ncdf_inquire( cdfid )		; Find out general info

	dim_text = make_array(500, /STRING)
	k=0
	dim_text(k) = string('Dimensions: ', glob.ndims)
	k=k+1
	dim_names = make_array(glob.ndims, /STRING)
	d_size = make_array(glob.ndims, /LONG)

	; dim names and sizes
	for i=0l,glob.ndims-1 DO BEGIN
		ncdf_diminq, cdfid, i, temp_name, temp_size
		dim_names(i) = temp_name
		d_size(i) = temp_size
		temp3 = ''
		for j=0l, (15-strlen(dim_names(i))) DO temp3 = temp3 + ' '
		IF i EQ glob.recdim THEN	$ 
			dim_text(k) = string('    ', dim_names(i),temp3,  d_size(i), ' (Unlimited dim)') $
		ELSE	$
			dim_text(k) = string('    ', dim_names(i),temp3, d_size(i)) 
		k=k+1
	ENDFOR

	; global attributes	
	IF (glob.ngatts NE 0) THEN BEGIN
		dim_text(k) = ''
		k=k+1
		dim_text(k) = string('Global Attributes: ', glob.ngatts)
		k=k+1
		for i=0l,glob.ngatts-1 DO BEGIN
			attname = ncdf_attname(cdfid, i, /GLOBAL)
			ncdf_attget,cdfid,attname,attvalue, /GLOBAL
		temp1=String(attvalue)
		IF (attvalue(0) EQ 40) THEN $
			 dim_text(k) = String(' Attribute ', attname, ' = ')+temp1 $
		ELSE $
			 dim_text(k) = String(' Attribute ', attname, ' = ', temp1) 
			k=k+1
		ENDFOR
	END

	; create the display window
	fin_text = dim_text(0:k)
	dim_texwig = widget_text(info_base, YSIZE = 10, XSIZE = 60, /FRAME, /SCROLL, VALUE = fin_text)
	var_names = make_array(glob.nvars, /STRING)
	units = make_array(glob.nvars + 1, /STRING, VALUE = "")

	; create variable list
	for i=0l,glob.nvars-1 DO BEGIN
		info = ncdf_varinq(cdfid, i)
		var_names(i)=info.name
		; sets up the units array, which contains the units of each
		; variable (or "" if none defined)
		for j=0l,info.natts-1 DO BEGIN
			attname = ncdf_attname(cdfid,i,j)
			IF (attname EQ 'units') THEN BEGIN
				ncdf_attget,cdfid,i,attname,attvalue
				units(i) = string(attvalue)
			END
		ENDFOR
	ENDFOR

	; draw variable list
	list_base = widget_base(info_base, /COLUMN)
	junk = widget_label(list_base, VALUE = "Variables:")
	var_list = widget_list(list_base, VALUE = var_names, YSIZE = 9, $
		UVALUE = "var_list")
END


; The 1d plotting engine
PRO onedplot, dim, svarval, title, minmax
COMMON globs, ncdf_base, info_base, var_base, butt_base, vdbutton, vbutt_base, data_base, var_list, var_names, dim_names, cdfid, var_texwig, current_var, units, path_used
  glob = ncdf_inquire( cdfid )
  info = ncdf_varinq (cdfid, current_var)
  ncdf_diminq, cdfid, info.dim(dim), dim_name, dim_size
  ncdf_control, cdfid, /NOVERBOSE
  dim_varid = ncdf_varid(cdfid, dim_name)
  ; get the dimension's values if they exist
  ncdf_control, cdfid, /VERBOSE
  IF (dim_varid EQ -1) THEN  BEGIN
  	dim_data = SINDGEN(dim_size) 
  	dim_varid = glob.nvars
  END $
  ELSE ncdf_varget, cdfid, dim_varid, dim_data
 
  ; offset in the ncdf file: 0s except for fixed dimensions
  offset = svarval
  offset(dim) = 0	

  ; amount to get in ncdf file: 1s except for independent variable
  count = make_array(info.ndims, /LONG, VALUE=1)	
  count(dim) = dim_size

 
  ncdf_varget, cdfid, current_var, var_data , OFFSET=offset, COUNT=count

  ; look for the _FillValue attribute
  for j=0l,info.natts-1 DO BEGIN
  attname = ncdf_attname(cdfid,current_var,j)
  IF (attname EQ '_FillValue') THEN BEGIN
  	ncdf_attget,cdfid,current_var,attname,attvalue
  	fillval = attvalue
  	END
  ENDFOR

  ; If it was found, change any instances of this value in the data to the
  ; lowest knormal value (using the rem_fill_vals procedure defined later)
  temp = size(fillval)
  IF (temp(1) NE 0) THEN rem_fill_vals,var_data, fillval

  ; If the independent dimension has 1 or 0 points
  IF (1 GE dim_size) THEN $
  	print, "Insufficient data points for plot." $
  ELSE BEGIN
	; If a minimum/maximum have been defined by autoscale, use them
  	temp = size(minmax)
  	IF (temp(1) NE 7) THEN $
  		plot, dim_data, var_data, XTITLE = (dim_name + " (" + units(dim_varid) + ")"), YTITLE = (info.name + " (" + units(current_var)+")") , CHARSIZE = 1.2, TITLE = title, YRANGE = minmax $
  	ELSE $
  		plot, dim_data, var_data, XTITLE = (dim_name + " (" + units(dim_varid) + ")"), YTITLE = (info.name + " (" + units(current_var)+")") , CHARSIZE = 1.2, TITLE = title
  END
END ; end of 1d plotting engine


; The 2d plotting engine
PRO twodplot, dimvar, svarval, ptype, title, minmax, animate
COMMON prefs_blk, pref_base, button_base, downhill, clevels, clabel, cfill, autoscale, xrot, zrot, sort, frame_threshold, mproj, gifout, downbutton, labelbutton, fillbutton, ascalebutton, sortbutton, gifbutton, projections, projlabel
COMMON globs, ncdf_base, info_base, var_base, butt_base, vdbutton, vbutt_base, data_base, var_list, var_names, dim_names, cdfid, var_texwig, current_var, units, path_used
  info = ncdf_varinq (cdfid, current_var)
  dims = make_array(2, /INT)

  ; dimvar is an array of binary elements where 1s correspond to selected
  ; dimensions and 0s to unselected. This creates a two element array called
  ; dims from dimvar which is simply the numbers of the two selected dimensions
  j=0
  for i=0l, (info.ndims-1) DO BEGIN
  	IF (dimvar(i) EQ 1) THEN BEGIN
  		dims(j) = i 
  		j=j+1
  	END
  ENDFOR

  ; put the dimensions in order
  IF (dims(0) GT dims(1)) THEN BEGIN
  	temp = dims(0)
  	dims(0) = dims(1)
  	dims(1) = temp
  END
 
  glob = ncdf_inquire( cdfid )
  ncdf_diminq, cdfid, info.dim(dims(0)), dim1_name, dim1_size
  ncdf_diminq, cdfid, info.dim(dims(1)), dim2_name, dim2_size
  ncdf_control, cdfid, /NOVERBOSE
  dim1_varid = ncdf_varid(cdfid, dim1_name)
  ncdf_control, cdfid, /VERBOSE
  IF (dim1_varid EQ -1) THEN BEGIN
  	dim1_data = SINDGEN(dim1_size) 
  	dim1_varid = glob.nvars
  END $
  ELSE ncdf_varget, cdfid, dim1_varid, dim1_data
  ncdf_control, cdfid, /NOVERBOSE
  dim2_varid = ncdf_varid(cdfid, dim2_name)
  ncdf_control, cdfid, /VERBOSE
  IF (dim2_varid EQ -1) THEN BEGIN
  	dim2_data = SINDGEN(dim2_size) 
  	dim2_varid = glob.nvars
  END $
  ELSE ncdf_varget, cdfid, dim2_varid, dim2_data

  ; offset is the fixed values except for the selected dimensions
  offset = svarval
  offset(dims(0)) = 0	
  offset(dims(1)) = 0	

  ; count is 1s except for the selected dimensions
  count = make_array(info.ndims, /LONG, VALUE=1)	
  count(dims(0)) = dim1_size
  count(dims(1)) = dim2_size

  ncdf_varget, cdfid, current_var, var_data, OFFSET=offset, COUNT=count

  ; looks for the _FillValue attribute
  for j=0l,info.natts-1 DO BEGIN
  	attname = ncdf_attname(cdfid,current_var,j)
  	IF (attname EQ '_FillValue') THEN BEGIN
  		ncdf_attget,cdfid,current_var,attname,attvalue
  		fillval = attvalue
  	END
  ENDFOR

  ; changes all instances of the fillvalue to the lowest normal value, if
  ; there is one. Uses the rem_fill_vals procedure defined later.
  temp = size(fillval)
  IF (temp(1) NE 0) THEN rem_fill_vals,var_data, fillval
 
  ; if either dimensions has only 0 or 1 points 
  IF ((1 GE dim1_size) OR (1 GE dim2_size)) THEN BEGIN
  	print, "Insufficient data points for plot." 
  	return
  END
 
  ; the ncdf_varget procedure returns 2d slices with additional 1 element
  ; dimensions unless they are trailing. This mess removes those extra
  ; dimensions. p_data ends up as a 2d array containing the values to be plotted
  p_data = make_array(dim1_size, dim2_size)
  command = "p_data(*,*) = var_data("
  for i=0l,(info.ndims-2) DO BEGIN
  	command = command + string('0:(count(',i,')-1),')
  ENDFOR
  command = command + string('0:(count(',i,')-1))')
  R = execute(command)

  IF (gifout AND (NOT animate)) THEN device, SET_RESOLUTION = [640, 512], SET_CHARACTER_SIZE = [6, 9]

  CASE ptype OF  					; varous plot-types
  0:	BEGIN 
  	temp = size(minmax)			; if a min/max is defined, use
  	IF (temp(1) NE 7) THEN $ 			
  		surface, p_data, dim1_data, dim2_data, XTITLE = (dim1_name + " (" + units(dim1_varid) + ")"), YTITLE = (dim2_name + " (" + units(dim2_varid) + ")") , ZTITLE = (info.name + " (" + units(current_var)+")") , CHARSIZE = 2.3 , TITLE = title, ZRANGE = minmax, ax = xrot, az = zrot $
  	ELSE $
  		surface, p_data, dim1_data, dim2_data, XTITLE = (dim1_name + " (" + units(dim1_varid) + ")"), YTITLE = (dim2_name + " (" + units(dim2_varid) + ")") , ZTITLE = (info.name + " (" + units(current_var)+")") , CHARSIZE = 2.3 , TITLE = title, ax = xrot, az = zrot
  	END
 		; add the statement LEGO = lego to the above lines to use the
		; lego option 
  1:	BEGIN 
  	temp = size(minmax)
  	IF (temp(1) NE 7) THEN $
  		shade_surf, p_data, dim1_data, dim2_data, XTITLE = (dim1_name + " (" + units(dim1_varid) + ")"), YTITLE = (dim2_name + " (" + units(dim2_varid) + ")") , ZTITLE = (info.name + " (" + units(current_var)+")") , CHARSIZE = 2.3 , TITLE = title, ZRANGE = minmax, ax = xrot, az = zrot $
  	ELSE $
  		shade_surf, p_data, dim1_data, dim2_data, XTITLE = (dim1_name + " (" + units(dim1_varid) + ")"), YTITLE = (dim2_name + " (" + units(dim2_varid) + ")") , ZTITLE = (info.name + " (" + units(current_var)+")") , CHARSIZE = 2.3 , TITLE = title, ax = xrot, az = zrot
  	END
  
  2:	BEGIN 
  	temp = size(minmax)
  	IF (temp(1) NE 7) THEN $
  		contour, p_data, dim1_data, dim2_data, XTITLE = (dim1_name + " (" + units(dim1_varid) + ")"), YTITLE = (dim2_name + " (" + units(dim2_varid) + ")") , ZTITLE = (info.name + " (" + units(current_var)+")") , CHARSIZE = 1.2, FOLLOW = clabel, FILL = cfill, DOWNHILL = DOWNHILL, NLEVELS = clevels, TITLE = title, ZRANGE = minmax $
  	ELSE $
  		contour, p_data, dim1_data, dim2_data, XTITLE = (dim1_name + " (" + units(dim1_varid) + ")"), YTITLE = (dim2_name + " (" + units(dim2_varid) + ")") , ZTITLE = (info.name + " (" + units(current_var)+")") , CHARSIZE = 1.2, FOLLOW = clabel, FILL = cfill, DOWNHILL = DOWNHILL, NLEVELS = clevels, TITLE = title 
  	END
  
  3:	BEGIN 
	aitoff = 0 
	azimuthal = 0 
	conic = 0 
	cylindrical = 0 
	gnomic = 0 
	lambert = 0
	mercator = 0
	mollweide = 0
	orthographic = 0
	sinusoidal = 0
	stereographic = 0
	CASE mproj OF
		0:	aitoff = 1
		1:	azimuthal = 1
		2:	conic = 1
		3:	cylindrical = 1
		4:	gnomic = 1
		5:	lambert = 1
		6:	mercator = 1
		7:	mollweide = 1
		8:	orthographic = 1
		9:	sinusoidal = 1
		10:	stereographic = 1
	ENDCASE
  	map_set,/continents,/grid, color = 150, TITLE = title, AITOFF = aitoff, azimuthal = azimuthal, conic = conic, cylindrical = cylindrical, gnomic = gnomic, lambert = lambert, mercator = mercator, mollweide = mollweide, orthographic = orthographic, sinusoidal = sinusoidal, stereographic = stereographic
  	temp = size(minmax)
  	IF (temp(1) NE 7) THEN $
  		contour, p_data, dim1_data, dim2_data, XTITLE = (dim1_name + " (" + units(dim1_varid) + ")"), YTITLE = (dim2_name + " (" + units(dim2_varid) + ")") , ZTITLE = (info.name + " (" + units(current_var)+")") , CHARSIZE = 1.2, FOLLOW = clabel , /OVERPLOT, DOWNHILL = DOWNHILL, NLEVELS = clevels, ZRANGE = minmax $
  	ELSE $
  		contour, p_data, dim1_data, dim2_data, XTITLE = (dim1_name + " (" + units(dim1_varid) + ")"), YTITLE = (dim2_name + " (" + units(dim2_varid) + ")") , ZTITLE = (info.name + " (" + units(current_var)+")") , CHARSIZE = 1.2, FOLLOW = clabel , /OVERPLOT, DOWNHILL = DOWNHILL, NLEVELS = clevels
  	END
  
  4:	BEGIN
		IF ((NOT gifout) AND (NOT animate)) THEN $
			window, 1, xsize = dim1_size, ysize = dim2_size 
		IF (gifout AND (NOT animate)) THEN $
			device, SET_RESOLUTION=[dim1_size, dim2_size]
		IF (animate) THEN $
			window, 1, xsize = dim1_size, ysize = dim2_size, /pixmap
  		tv, p_data
		IF ((NOT gifout) AND (NOT animate)) THEN $
			wset, 0
	END
  ENDCASE
END


;looks through data for the fill value and changes each instance to the lowest
; normal value (which it finds)
PRO rem_fill_vals, var_data, fillval

data_size = size(var_data)
len = 1
FOR i=1, data_size(0) DO len = len * data_size(i)
raw_data = make_array(len)
raw_data(*) = var_data
min = 9.0*10.0^37	 ; very big
for i=0l, (len-1) DO BEGIN
	IF ((raw_data(i) NE fillval) AND (raw_data(i) LT min)) THEN $
			 min = raw_data(i)
END

for i=0l, (len-1) DO BEGIN
	IF (raw_data(i) EQ fillval) THEN raw_data(i) = min
END
var_data(*) = raw_data
END

; main

PRO ncbrowse, filename, GROUP = GROUP, PATH = PATH, SECOND = SECOND, HELP = HELP, filter=fltr

COMMON globs, ncdf_base, info_base, var_base, butt_base, vdbutton, vbutt_base, data_base, var_list, var_names, dim_names, cdfid, var_texwig, current_var, units, path_used
COMMON prefs_blk, pref_base, button_base, downhill, clevels, clabel, cfill, autoscale, xrot, zrot, sort, frame_threshold, mproj, gifout, downbutton, labelbutton, fillbutton, ascalebutton, sortbutton, gifbutton, projections, projlabel

IF (keyword_set(HELP)) THEN BEGIN 
	doc_library,'ncbrowse' 
	RETURN 
ENDIF 

temp = size(path)
; HERE IS THE DEFAULT PATH:
IF (temp(1) NE 7) THEN path = "."

temp = size(filename)
IF (temp(1) NE 7) THEN BEGIN
        if not(keyword_set(fltr)) then fltr='*.nc'
	; idl's file selector
	the_file = pickfile(PATH=path, GET_PATH = path_used, FILTER = fltr, /READ) 
END $
ELSE the_file = filename

IF (the_file EQ "") THEN return
IF (XRegistered("ncbrowse") NE 0) THEN RETURN		;only one instance of
							;the ncbrowse widget
							;is allowed.  If it is
							;already managed, do
							;nothing and return

; create the main base
ncdf_base = widget_base(TITLE = string("NetCDF Browser: ",the_file) , /COLUMN)

info_base = widget_base(ncdf_base, /ROW)	;create the base which holds
					        ;all displayed information

cdfid = ncdf_open(the_file,/NOWRITE)	; Open the file

ncdf_cat2				; display a catalog of the dimensions
					; and get the variable names

butt_base = widget_base(NCDF_base, /ROW) ; create a base for the buttons

XPdMenu, [	'"Done"				EXIT',		$
		'"New File"			NFILE',		$
		'"Help"				HELP',		$
		'"Preferences"			PREFS'], $
	 butt_base
vdbutton = widget_button (butt_base, VALUE = "View Data", UVALUE = "DATA")
widget_control, vdbutton, SENSITIVE = 0
XPdMenu, ["'Plot'	{",	$
		"}"],				$
	 butt_base, BASE = vbutt_base

; Initial values for all preferences. These are contained in prefs_blk
; number of contour levels. This doesn't get done if the program has run before
; and called itself

temp = size(second)

IF (temp(1) NE 2) THEN BEGIN
clevels = 6
;label contour levels (1=yes, 0=no)
clabel = 1
;filled contours (1/0)
cfill = 0
;lego mode for wireframes (1/0)
; uncomment this to activate
;lego = 0
;downhill arrows in contours (1/0)
downhill = 0
;single-scaling for animations (1/0)
autoscale = 1
;x- and z-axis rotation angles (-180 to 180 degrees)
xrot = 30
zrot = 30
;sort values in animation dimension increasingly (1/0)
sort = 1
;Maximum frames in an animation. It may be possible to raise this if you have
; enough memory. I don't know.
frame_threshold = 20
; Map projection to use. Default is mercator
mproj = 6
; Output graphics to gif file instead of a plot window.
gifout = 0
END
;;

; creates empty variable info box
var_texwig = widget_text(info_base, YSIZE = 10, XSIZE = 60, /FRAME, /SCROLL, VALUE = ["Variable Info:"])

widget_control, ncdf_base, /REALIZE			;create the widgets
							;that are defined

XManager, "ncbrowse", ncdf_base, $			;register the widgets
		EVENT_HANDLER = "ncbrowse_ev", $	;with the XManager
		GROUP_LEADER = GROUP			;and pass through the
							;group leader if this
							;routine is to be 
							;called from some group
							;leader.

END ; end of main routine

