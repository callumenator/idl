
function get_moxa_error, err_code

	case err_code of

		0: error = 'SIO_OK'
		-1: error = 'SIO_BADPORT - bad port number'
		-2: error = 'SIO_OUTCONTROL - not moxa compatible board'
		-4: error = 'SIO_NODATA - no data to read'
		-5: error = 'SIO_OPENFAIL - port non existent or busy'
		-6: error = 'SIO_RTS_BY_HW - wrong flow control'
		-7: error = 'SIO_BADPARAM - bad parameter'
		-8: error = 'SIO_WIN32FAIL - win32 function failed'
		-9: error = 'SIO_BOARDNOTSUPPORT - com port does not support function'
		-11: error = 'SIO_ABORT_WRITE - user aborted write'
		-12: error = 'SIO_WRITETIMEOUT - write timed out'

		else: error = 'BYTES ' + string(err_code, f='(i0)')
	endcase

	return, error

end