
;\\ Usually used for Doppler scaling (say between -300 and 300)
;\\ Scale min and max are the min and max values to consider (saturates outside this range)
;\\ Scale middle is mean(scaleToMin, scaleToMax) by default, but can be set via keyword.
;\\ ScaleTo is the output range, by default is 0-255
;\\ Missing is a 2 element array, with value indicating missing data and the value it should be mapped to.
pro scale_to_range, inArr, inScaleMin, inScaleMax, outScaledArr, $
					scaleMiddle = scaleMiddle, scaleTo = scaleTo, $
					missing=missing

	if keyword_set(scaleMiddle) then scaleCenter = scaleMiddle else $
		scaleCenter = mean([inScaleMin, inScaleMax])

	if not keyword_set(scaleTo) then scaleTo = [0.,255.]

	outScaledArr = inArr

	ptsl = where(inArr le inScaleMin, nl)
	ptsg = where(inArr ge inScaleMax, ng)
	if nl gt 0 then outScaledArr[ptsl] = inScaleMin
	if ng gt 0 then outScaledArr[ptsg] = inScaleMax

	scaleToRange = scaleTo[1] - scaleTo[0]

	if inScaleMin lt 0 then begin

		ptsl = where(outScaledArr lt scaleCenter, nl)
		ptsg = where(outScaledArr ge scaleCenter, ng)
		if nl gt 0 then outScaledArr[ptsl] = scaleTo[0] + (scaleToRange/2.)*(1 - (outScaledArr[ptsl]/inScaleMin))
		if ng gt 0 then outScaledArr[ptsg] = scaleTo[0] + (scaleToRange/2.)*(1 + (outScaledArr[ptsg]/inScaleMax))

	endif else begin

		;outScaledArr = scaleToRange*(outScaledArr - inScaleMin)/(inScaleMax - inScaleMin) + scaleTo[0]
		outScaledArr = bytscl(outScaledArr, min=inScaleMin, max=inScaleMax)
		outScaledArr = (outScaledArr/255.)*scaleToRange + scaleTo[0]

	endelse

	if n_elements(missing) eq 2 then begin
		ptsMissing = where(inArr eq missing[0], nmissing)
		if nmissing gt 0 then outScaledArr[ptsMissing] = missing[1]
	endif

end