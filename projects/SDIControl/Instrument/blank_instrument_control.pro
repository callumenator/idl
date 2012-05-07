
@sdi_include

pro blank_instrument_control, command = command, $
							  in = in, $
							  out = out

	common SDIControl

	command = strlowcase(command)

	case command of

		'initialise':begin

			;\\ Initialise the frame buffer
				*sdic_frame_buffer.image = lonarr(400,400)
		end


		'grab_frame':begin

			dims = size(*sdic_frame_buffer.image, /dimension)
			dims = [400,400]
			zerph = float(sdic_scan.channel)/float(sdic_scan.nchannels) + 1.5
			xmag = 0.9e-3
			ymag = 0.9e-4
			zmag = 0.9e-4
			noise = randomu(systime(/sec)*100L, dims[0], dims[1]) - .5
			sdi_synth_frnginit, php, dims[0], dims[1], mag=[xmag,ymag,zmag], center=[dims[0]/2., dims[1]/2.], ordwin=[0.0,5.0], $
	                     			phisq = 1.0, zerph = zerph, R=.9
	        sdi_synth_fringemap, image, pmap, php, field_stop
	        image = abs(image*5. + 2.0*noise)



			;call_procedure, drivers.camera, misc.dll, 'uGrabFrame', $
			;			{mode:hardware.camera.readMode, $
			;				 imageMode:hardware.camera.imageMode}, new_image, result

			out = {image:image, result:'image'}
		end

		'scan_etalon':begin
			print, sdic_scan.channel
		end


		else:
	endcase

end