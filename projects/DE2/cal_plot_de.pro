;
; IDL Widget Interface Procedures. This Code is automatically
;     generated and should not be modified.

;
; Generated on:	03/23/2009 16:54.37
;
pro WID_BASE_0_event, Event

  wTarget = (widget_info(Event.id,/NAME) eq 'TREE' ?  $
      widget_info(Event.id, /tree_root) : event.id)


  wWidget =  Event.top

  case wTarget of

    Widget_Info(wWidget, FIND_BY_UNAME='WID_LIST_0'): begin
      if( Tag_Names(Event, /STRUCTURE_NAME) eq 'WIDGET_LIST' )then $
        load_file, Event
    end
    Widget_Info(wWidget, FIND_BY_UNAME='WID_BUTTON_0'): begin
      if( Tag_Names(Event, /STRUCTURE_NAME) eq 'WIDGET_BUTTON' )then $
        select_plot, Event
    end
    Widget_Info(wWidget, FIND_BY_UNAME='WID_BUTTON_1'): begin
      if( Tag_Names(Event, /STRUCTURE_NAME) eq 'WIDGET_BUTTON' )then $
        plot_vz, Event
    end
    Widget_Info(wWidget, FIND_BY_UNAME='WID_BUTTON_2'): begin
      if( Tag_Names(Event, /STRUCTURE_NAME) eq 'WIDGET_BUTTON' )then $
        plot_vz_mod, Event
    end
    Widget_Info(wWidget, FIND_BY_UNAME='WID_BUTTON_3'): begin
      if( Tag_Names(Event, /STRUCTURE_NAME) eq 'WIDGET_BUTTON' )then $
        select_oplot, Event
    end
    Widget_Info(wWidget, FIND_BY_UNAME='WID_BUTTON_4'): begin
      if( Tag_Names(Event, /STRUCTURE_NAME) eq 'WIDGET_BUTTON' )then $
        plot_vz_poly, Event
    end
    Widget_Info(wWidget, FIND_BY_UNAME='WID_BUTTON_5'): begin
      if( Tag_Names(Event, /STRUCTURE_NAME) eq 'WIDGET_BUTTON' )then $
        use_ut, Event
    end
    Widget_Info(wWidget, FIND_BY_UNAME='WID_BUTTON_6'): begin
      if( Tag_Names(Event, /STRUCTURE_NAME) eq 'WIDGET_BUTTON' )then $
        use_lat, Event
    end
    Widget_Info(wWidget, FIND_BY_UNAME='WID_BUTTON_7'): begin
      if( Tag_Names(Event, /STRUCTURE_NAME) eq 'WIDGET_BUTTON' )then $
        set_yrange, Event
    end
    Widget_Info(wWidget, FIND_BY_UNAME='WID_BUTTON_8'): begin
      if( Tag_Names(Event, /STRUCTURE_NAME) eq 'WIDGET_BUTTON' )then $
        set_xrange, Event
    end
    else:
  endcase

end

pro WID_BASE_0_GUI, GROUP_LEADER=wGroup, _EXTRA=_VWBExtra_

	common data, k_vz, k_ut, k_vz_ion, k_lat, k_vz_poly, k_vz_mod, plot_data, list

  Resolve_Routine, 'cal_plot_de_eventcb',/COMPILE_FULL_FILE  ; Load event callback routines

	list = file_search('C:\Cal\IDLSource\de2_data\Cal_Saves', '*.dat')

  WID_BASE_0 = Widget_Base( GROUP_LEADER=wGroup, UNAME='WID_BASE_0'  $
      ,XOFFSET=5 ,YOFFSET=5 ,SCR_XSIZE=1178 ,SCR_YSIZE=639  $
      ,TITLE='IDL' ,SPACE=3 ,XPAD=3 ,YPAD=3)


  WID_DRAW_0 = Widget_Draw(WID_BASE_0, UNAME='WID_DRAW_0'  $
      ,XOFFSET=230 ,YOFFSET=3 ,SCR_XSIZE=929 ,SCR_YSIZE=593)


  WID_LIST_0 = Widget_List(WID_BASE_0, UNAME='WID_LIST_0' ,XOFFSET=7  $
      ,YOFFSET=5 ,SCR_XSIZE=200 ,SCR_YSIZE=359 ,XSIZE=11 ,YSIZE=2, value = file_basename(list))


  WID_BUTTON_0 = Widget_Button(WID_BASE_0, UNAME='WID_BUTTON_0'  $
      ,XOFFSET=5 ,YOFFSET=375 ,SCR_XSIZE=88 ,SCR_YSIZE=28  $
      ,/ALIGN_CENTER ,VALUE='Plot')


  WID_BUTTON_1 = Widget_Button(WID_BASE_0, UNAME='WID_BUTTON_1'  $
      ,XOFFSET=5 ,YOFFSET=408 ,SCR_XSIZE=183 ,SCR_YSIZE=28  $
      ,/ALIGN_CENTER ,VALUE='Vz')


  WID_BUTTON_2 = Widget_Button(WID_BASE_0, UNAME='WID_BUTTON_2'  $
      ,XOFFSET=5 ,YOFFSET=442 ,SCR_XSIZE=183 ,SCR_YSIZE=28  $
      ,/ALIGN_CENTER ,VALUE='Vz Mod')


  WID_BUTTON_3 = Widget_Button(WID_BASE_0, UNAME='WID_BUTTON_3'  $
      ,XOFFSET=99 ,YOFFSET=375 ,SCR_XSIZE=88 ,SCR_YSIZE=28  $
      ,/ALIGN_CENTER ,VALUE='Oplot')


  WID_BUTTON_4 = Widget_Button(WID_BASE_0, UNAME='WID_BUTTON_4'  $
      ,XOFFSET=5 ,YOFFSET=476 ,SCR_XSIZE=183 ,SCR_YSIZE=28  $
      ,/ALIGN_CENTER ,VALUE='Vz Polynomial')


  WID_BUTTON_5 = Widget_Button(WID_BASE_0, UNAME='WID_BUTTON_5'  $
      ,XOFFSET=4 ,YOFFSET=510 ,SCR_XSIZE=88 ,SCR_YSIZE=28  $
      ,/ALIGN_CENTER ,VALUE='x = UT')


  WID_BUTTON_6 = Widget_Button(WID_BASE_0, UNAME='WID_BUTTON_6'  $
      ,XOFFSET=100 ,YOFFSET=510 ,SCR_XSIZE=88 ,SCR_YSIZE=28  $
      ,/ALIGN_CENTER ,VALUE='x = Latitude')

  WID_BUTTON_7 = Widget_Button(WID_BASE_0, UNAME='WID_BUTTON_7'  $
      ,XOFFSET=100 ,YOFFSET=540 ,SCR_XSIZE=88 ,SCR_YSIZE=28  $
      ,/ALIGN_CENTER ,VALUE='YRange')

  WID_BUTTON_8 = Widget_Button(WID_BASE_0, UNAME='WID_BUTTON_8'  $
      ,XOFFSET=5 ,YOFFSET=540 ,SCR_XSIZE=88 ,SCR_YSIZE=28  $
      ,/ALIGN_CENTER ,VALUE='XRange')


  Widget_Control, /REALIZE, WID_BASE_0

  XManager, 'WID_BASE_0', WID_BASE_0, /NO_BLOCK

end
;
; Empty stub procedure used for autoloading.
;
pro cal_plot_de, GROUP_LEADER=wGroup, _EXTRA=_VWBExtra_

	common data
	loadct, 39, /silent

	plot_data = {plot:1, oplot:0, xut:0, xlat:1, $
				 yrange:[-100.,100.], $
				 xrange:[-90., 90.]}

   	WID_BASE_0_GUI, GROUP_LEADER=wGroup, _EXTRA=_VWBExtra_

end
