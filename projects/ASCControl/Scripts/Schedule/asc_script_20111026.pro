
@asc_script_utilities

function ASC_Script_20111026, info, reset=reset

  COMMON ASC_Script_20111026_Common, block0_flag
  
  ;\\ Default queue is empty
  queue = ['']
  
  ;\\ Some housekeeping      
    if IsDefined(block0_flag) eq 0 then block0_flag = 0
    if keyword_set(reset) then begin
      block0_flag = 0      
      return, queue
    endif
  
  
  ;\\ Start of the real stuff
  if (HourUT() gt 4.5) and (HourUT() lt 15.0) then begin  
  
    if block0_flag eq 0 then begin
    
      ;\\ Do these things just once for this block of time
      queue = ['init_directories', $          ;\\ Create data directories for the current day
               'shutter, position = open', $  ;\\ Open the shutter
               'filter, home=1', $            ;\\ Home the filter wheel               
               'camera, emGain = 2']          ;\\ Setup the camera
               
      block0_flag = 1
      return, queue
          
    endif else begin   
    
      ;\\ Most of the time we will be doing this
      queue = ['filter, 1', $
               'camera, exposureTime = 0.5', $ 
               'grab_frame, numframes = 1, save_raw = 1, ' + $
                   'inter_frame_delay = 0.1, postprocess = ASC_ImagePostProcess', $              
               
               'filter, 2', $
               'camera, exposureTime = 1.0', $
               'grab_frame, numframes = 1, save_raw = 1, ' + $
                   'inter_frame_delay = 0.1, postprocess = ASC_ImagePostProcess', $
               
               'filter, 3', $
               'camera, exposureTime = 1.5', $
               'grab_frame, numframes = 1, save_raw = 1, ' + $
                   'inter_frame_delay = 0.1, postprocess = ASC_ImagePostProcess', $
               
               'filter, 4', $
               'camera, exposureTime = 1.0', $
               'grab_frame, numframes = 1, save_raw = 1, ' + $
                   'inter_frame_delay = 0.1, postprocess = ASC_ImagePostProcess' $
               ]              
        
      return, queue
    endelse  
          
  endif

  if (HourUT() lt 4.75) or (HourUT() gt 14.25) then begin 
    
    queue = [ 'shutter, position = close', $              
              'idl, wait, .1']
    
    ;\\ Reset the flag(s)
    block0_flag = 0      
    return, queue    
  endif
  
  ;\\ Just in case we missed all the time blocks
  return, queue
end