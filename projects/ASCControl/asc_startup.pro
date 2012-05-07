
;\\ ASC control program entry point. Should be called with the following arguments:
;\\
;\\ External_dll = the dll containing wrapped camera calls, etc
;\\
;\\ Camera_profile = the initial set of camera settings to upload to the camera.
;\\
;\\ Filename_function - instrument specific function used to build a filename string for saved files
;\\
;\\ Site_info = a structure containing at least the following:
;\\ 			{ name:"",	- site name
;\\				  geo_lat:0.0, - site latitude
;\\				  geo_lon:0.0  - site longitude
;\\ 			}
;\\
;\\ Data_info = a structure containing at least the following:
;\\ 			{ prepend:"", - string to prepend to iamge filenames
;\\				  base_dir:"", - base data directory
;\\ 			}
;\\
;\\ Comms_info = a structure containing at least the following:
;\\ 			{ shutter_port:0,
;\\ 			  filter_port:0,
;\\ 			  filter_names: [''] - string array containing names indexed by filter number
;\\				}
;\\
;\\ Schedule = a file containing a schedule script.
;\\



ASC_Control_Main, $ 
          'SDI_External_ASC.dll', $
				  'ASC_CameraProfile', $
				  'ASC_ASC_Filename', $

				  ;\\ SITE INFORMATION
				  { $
				   name:'PKR', $
				   geo_lat:65.1260, $
				   geo_lon:-147.4789 $
				  }, $

				  ;\\ DATA INFORMATION
				  {prepend:'PKR_DASC', $
				   base_dir:'D:\ASCData\'}, $

				  ;\\ HARDWARE COMMS INFO
				  { $
				   shutter_port:1, $
				   filter_port:1, $
				   filter_names:['NONE','0000','0558','0630','L715','0000','0428'] $
				  }, $

				  ;\\ A STARTUP SCHEDULE SCRIPT
				  schedule = ''

