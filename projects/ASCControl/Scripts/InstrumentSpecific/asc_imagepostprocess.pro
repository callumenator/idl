@asc_script_utilities

function ASC_ImagePostProcess, in_image

	COMMON ASC_Control, info, gui

  COMMON ASC_ImagePostProcess_Common, composite_image, n_channels

  ;\\ Bytscl the image for JPEG
    min_max = intarr(3, 6)
    openr, hnd, 'C:\Users\allsky\ASCControl\JPEG_Scale.txt', /get
    readf, hnd, min_max
    free_lun, hnd

    line = where(min_max[0,*] eq info.comms.filter.current, line_match)
    if line_match eq 1 then begin
      ;\\ Scale read in from the text file
      scale_min = min_max[1,line[0]]
      scale_max = min_max[2,line[0]]
    endif else begin
      ;\\ A default scale
      scale_min = 300
      scale_max = 1500
    endelse
    out_image = bytscl(in_image, min = scale_min, max = scale_max)

    ;\\ Save a jpeg image
      filename = call_function(info.filename_function, 'JPEG', $
                               extra = {date:info.image_exp_start_date, $
                                        time:info.image_exp_start_time} ) + '.JPEG'

      write_jpeg, filename, out_image, quality = 75

	;\\ Create a three channel image from (currently) red and green filter images
	    send_jpeg = 0
      if size(n_channels, /type) eq 0 then begin
        dims = size(*info.image, /dimensions)
        composite_image = bytarr(3, dims[0], dims[1])
        n_channels = 0
      endif      

      if info.comms.filter.lookup[info.comms.filter.current] eq '0630' then begin
        if n_channels eq 0 then begin
          composite_image[0,*,*] = out_image
          n_channels = 1
        endif
      endif

      if info.comms.filter.lookup[info.comms.filter.current] eq '0558' then begin
        if n_channels eq 1 then begin
          composite_image[1,*,*] = out_image
          n_channels = 2	      
        endif
      endif
      
      if info.comms.filter.lookup[info.comms.filter.current] eq '0428' then begin
        if n_channels eq 2 then begin
          composite_image[2,*,*] = out_image
          n_channels = 0

          composite_filename = call_function(info.filename_function, 'JPEG', $
                                        extra = {date:info.image_exp_start_date, $
                                            time:info.image_exp_start_time}, $
                                            filter_name_override = 'RGBR' ) + '.JPEG'
          
          write_jpeg, composite_filename, composite_image, quality = 75, /true
          send_jpeg = 1
        endif
      endif
    

    ;\\ Create the FTP script
    if 1 then begin
      openw, hnd, 'C:\Control\WinSCPScript.txt', /get_lun
        printf, hnd, 'option batch on'
        printf, hnd, 'option confirm off'
        printf, hnd, 'open realtime@optics.gi.alaska.edu'
        printf, hnd, 'cd PKR_DASC/' + DateStringUT_YYYYMMDD_Nosep() + '/'
        printf, hnd, 'put ' + filename
        if send_jpeg eq 1 then printf, hnd, 'put ' + composite_filename
        printf, hnd, 'close'
        printf, hnd, 'exit'
      close, hnd
      free_lun, hnd

      ;\\ Spawn the FPT command
      spawn, 'cmd /D /Q /C WinSCP /console /script=C:\Control\WinSCPScript.txt', /hide, /nowait
    endif



	return, out_image
end