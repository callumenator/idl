
@asc_script_utilities

function ASC_Script_Scratch, info, reset=reset

  COMMON ASC_Script_Scratch_Common, block0_flag
  
  ;\\ Default queue is empty
  queue = ['']
  
  ;\\ Some housekeeping      
    if IsDefined(block0_flag) eq 0 then block0_flag = 0
    if keyword_set(reset) then begin
      block0_flag = 0
      return, queue
    endif
  
  
  if HourUT() gt 0 and HourUT() lt 24 then begin
    
    if block0_flag eq 0 then begin
    
      ;\\ Do these things just once for this block of time
      queue = ['init_directories']               
               
      block0_flag = 1
      return, queue
          
    endif else begin   
    
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
  
  ;\\ Just in case we missed all the time blocks
  return, queue
end