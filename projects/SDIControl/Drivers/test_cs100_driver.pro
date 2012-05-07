
pro test_cs100_driver

	dll = 'c:\cal\dllstore\sdi_external.dll'
	comms_wrapper, 7L, dll, type='com', /open, err=err

	sdi_cs100_etalon_driver, 'initialise', {port:7L, dll:dll, comms:'com'}, out, err

	comms_wrapper, 7L, dll, type='com', /close, err=err

end