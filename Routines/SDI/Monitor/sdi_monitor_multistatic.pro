
pro sdi_monitor_multistatic

	common sdi_monitor_common, global, persistent

	if ptr_valid(persistent.zonemaps) eq 0 then return
	if ptr_valid(persistent.snapshots) eq 0 then return

end
