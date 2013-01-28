
;\\ ASC control program entry point. Should be called with the following arguments:
;\\
;\\ External_dll = the dll containing wrapped camera calls, etc
;\\
;\\ Camera_profile = the initial set of camera settings to upload to the camera.
;\\
;\\ Schedule = a file containing a schedule script.
;\\


DCAI_Control_Main, settings_file = 'dcai_settings', $
				   external_dll = 'SDI_External.dll', $
				   camera_settings = 'DCAI_CameraProfile', $
				   drivers = 'DCAI_Drivers', $
				   schedule = '', $
				   /simulate