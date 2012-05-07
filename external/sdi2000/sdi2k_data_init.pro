;========================================================================
;  Initialise the program's global state, which is stored in common blocks:

pro sdi2k_data_init, culz
@sdi2kinc.pro

    whoami, dir, file
    disk = strmid(dir, 0,2)

    xfer_flag= 0L
    scale    = fix(1)
    viewscale= 2

;========================================================================
; NetCDF properties:
  netcdf = {s_ncdf,           ncid: -1L, $
                          ncrecord: 0, $
                          ncmaxrec: 0, $
                          ncnzones: 0, $
                           ncstime: 0L, $
                           ncetime: 0L, $
                 menu_configurable: 0}

;========================================================================
; Hardware properties:
    etalon = {etalon,          gap: 20., $
                parallelism_offset: [0, 30, 200], $
                     scan_channels: 128, $
                   current_channel: 0, $
                     start_spacing: 0, $
                   current_spacing: 0, $
                      dwell_frames: 1, $
                       dwell_count: 0, $
                       nm_per_step: 0.46021818, $
                         scan_gain: 0., $
              gap_refractive_index: 1., $
                etalon_8255_number: 0b, $
                 menu_configurable: 1, $
                     user_editable: [0,1,2,4,6,8,10,11]}

shutters = {shutters,laser_8255_number: 4b, $
                camera_8255_number: 8b, $
                  camera_open_bits: 2b, $
;                 camera_close_bits: 3b, $
                 camera_close_bits: 1b, $
                   laser_open_bits: 0b, $
                  laser_close_bits: 255b, $
                 menu_configurable: 1, $
                     user_editable: [0, 1, 2, 3, 4, 5]}

 video = {video,              rows: '1e4'X/viewscale, $
                           columns: ('300'X - '80'x)/viewscale, $
                              gain: 1.5, $
                            offset: -0.3, $
                        clamp_mode: 0, $
                       clamp_level: 5, $
                     top_level_a2d: 255, $
                  bottom_level_a2d: 89, $
                  frequency_cutoff: 127, $
              high_frequency_boost: 0, $
                  external_trigger: 1, $
             external_trigger_high: 0, $
                      rebin_sample: 0, $
                  interrupt_driven: 1, $
                   LED_8255_number: 12b, $
                camera_config_file: 'd:\\users\\sdi2000\\sdi2000_camera.ini', $
                        frame_time: systime(1), $
                        frame_rate: 0., $
                       frame_count: 0, $
                       scene_stamp: bytarr(5) + [1, 253, 7, 167, 77], $
                      offset_table: [[0., 1.2], [-0.3, 0.9], [-0.3, 0.9]], $
                 menu_configurable: 1, $
                     user_editable: [2,3,4,5,6,7,8,9,10,11,12,13,14]}

;========================================================================
; Operation properties:
    header = {header,      records:  0, $
                    file_specifier: 'None', $
                              site: 'Poker Flat', $
                         site_code: 'pf', $
                         longitude: -147.4303, $
                          latitude: 65.1192, $
                              year:  dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='Y$'), $
                               doy:  dt_tm_mk(js2jd(0d)+1, dt_tm_tojs(systime()), format='doy$'), $
                          operator: 'Mark Conde', $
                           comment: 'Routine Operation', $
                          software: 'September 2000: IDL v5.2, MS-Visual C DLL, Win-RT 3.5 R1, MV-1000', $
                             notes:  replicate(string(' ', format='(a80)'), 32), $
                 menu_configurable: 1, $
                     user_editable: [2,3,4,5,6,7,8,9,10]}

         zones = {zones, fov_rings:  9, $ ;  was 6 for 47 zones, 9 for sodium #######
;                        ring_radii: [17, 33, 48, 62, 75,  87, 98, 100], $
;                           sectors: [1,   4,  6, 8, 12,  16, 20,  0], $
                        ring_radii: [10, 22, 33, 44, 55,  66, 77, 88, 99, 100], $ ; #####
                           sectors: [1,   4, 8, 12, 16, 20, 24, 28, 32, 0], $ ; ######
;                        ring_radii: [17, 33, 48, 62, 75,  87, 98, 100], $
;                           sectors: [1,   4,  6, 8, 12,  16, 20,  0], $
                          x_center: 121., $
                          y_center: 160., $
                 menu_configurable: 1, $
                     user_editable: [0, 1, 2, 3, 4]}

    calibration = $
            {calibration, sky_mass: 16., $
                          cal_mass: 20., $
                   cal_temperature: 0.1, $
                   sky_ref_finesse: 30., $
                   cal_ref_finesse: 30., $
;                    sky_wavelength: 557.7,    $ ;######
;                    sky_wavelength: 630.0311, $ ;######
                    sky_wavelength: 589.0, $ 
                    cal_wavelength: 632.8165, $
                           sky_fov: 72., $
                 menu_configurable: 1, $
                     user_editable: [0,1,2,3,4,5,6]}

    times = {times,      sea_limit: -3., $ ; Use -3. for sodium, -6. for 5577 or 6300 ######
               safe_moon_elevation: 40., $ ; 45., $   ; ####22., $
                   safe_moon_phase: 0.90, $
               reboot_decimal_hour: '21.', $
                   observing_times: [0d, 0d], $
                 calibration_times: [0d, 0d], $
                 menu_configurable: 1, $
                     user_editable: [0,1,2,3]}

    logging = {logging,     record: 0, $
                     log_directory: disk + '\users\sdi2000\data\', $
                  time_name_format: 'Y$doy$', $
                        log_append: 1, $
                     log_overwrite: 0, $
                    enable_logging: 1, $
                 logging_off_alarm: 0, $
                preallocated_notes: 32, $
                       note_number: 0, $
                 menu_configurable: 1, $
                     user_editable: [1,2,3,4,5,6,7]}

;========================================================================
; Controller properties:
    ticker ={ticker,timer_interval: 1., $
                     timer_ticking: 1, $
                    refresh_frames: 10, $
                     refresh_count: 0, $
                        job_frames: 5, $
                         job_count: 0, $
                 menu_configurable: 1, $
                     user_editable: [0,1,2,4]}

; job_file_table = {job_file_table, phase_map_job: 'acquire_phase_map.sdi', $
;                                     insprof_job: 'acquire_insprofs.sdi', $
;                                 phase_shift_job: 'shift_phase_map.sdi', $
;                             sky_observation_job: 'sky_observations.sdi', $
;                               menu_configurable: 1, $
;                                   user_editable: [0,1,2,3]}

scheduler={scheduler,        active: 1, $  ;######
                      job_directory: 'd:\users\sdi2000\', $
                      phase_map_job: 'acquire_phase_map.sdi', $
                        insprof_job: 'acquire_insprofs.sdi', $
                    phase_shift_job: 'shift_phase_map.sdi', $
                sky_observation_job: 'sky_observations.sdi', $
             external_script_filter: 'sdi2k_script_*.pro', $
                       daily_reboot: 1, $
                      job_semaphore: 'No scheduled job', $
                  menu_configurable: 1, $
                      user_editable: [0,1,2,3,4,5,6,7]}

    behavior = {behavior,menu_font: 'Arial Narrow*20*Bold', $
                       config_file: 'sdi2000.sdi', $
                          dll_file: 'd:\ed\idlinterface\debug\idlinterface.dll', $
                   show_on_refresh: 0, $
                       show_header: 1, $
                     message_lines: 8, $
                    write_log_file: 1, $
                 close_idl_on_exit: 0, $
                 menu_configurable: 1, $
                     user_editable: [0,1,2,3,4,5,6,7]}

;========================================================================
; Programs properties:
 svid = {direct_video, scan_etalon: 1, $
               brightness_function: 'none', $
                    update_divisor: 1, $
                       show_center: 0, $
                      update_count: 0, $
                    cursor_pending: 0, $
                 menu_configurable: 1, $
                     user_editable: [0,1,2,3]}

 pmap = {phase_map,    file_prefix: 'phc', $
                        start_time: 0L, $
               integration_seconds: 180, $
                 angle_coefficient: 0., $
                 menu_configurable: 1, $
                     user_editable: [0,2]}

 spex = {spectra, observation_type: 'sky', $
                      show_spectra: 1, $
                        start_time: 0L, $
               integration_seconds: 180, $
                     auto_exposure: 0, $
           max_integration_seconds: 480, $
           min_integration_seconds: 60, $
             integration_dropwidth: 0.12, $
             calibration_frequency: 5, $
              calibration_exposure: 60, $
                      window_xsize: 800, $
                      window_ysize: 800, $
                      etalon_scans: -1, $
                     channel_shift: 0, $
                 menu_configurable: 1, $
                     user_editable: [0,1,3,4,5,6,7,8,9,10,11,13]}

  fox = {focus,     update_divisor: 20, $
                      update_count: 0, $
                  ccr_displacement: 50, $
                 menu_configurable: 1, $
                     user_editable: [0,2]}

 chrd = {chord,       nominal_chrd: 685.0, $
                chord_search_logap: 610., $
                chord_search_higap: 750., $
                          stepsize: 2., $
                   frames_per_step: 3, $
                  reference_frames: 80, $
               integration_seconds: 900, $
                     apply_results: 1, $
                        fit_degree: 3, $
                        start_time: 0L, $
                         chord_val: 0., $
                       frame_count: 0, $
                          ref_flag: 1, $
                     chord_runtime: 0L, $
                 menu_configurable: 1, $
                     user_editable: [0,1,2,3,4,5,6,7,8]}

 pshf = {phase_shift,  file_prefix: 'phs', $
                      radial_chunk: 60, $
                         smoothing: 25, $
                    display_orders: 7.5, $
                        order_step: 64, $
               prompt_for_filename: 1, $
                exit_on_completion: 0, $
                 menu_configurable: 1, $
                     user_editable: [0,1,2,3,4,5,6]}

;========================================================================
; Collect the properties structures into logigical groups:
    operation = {operation,  times: times, $
                           logging: logging, $
                       calibration: calibration, $
                            header: header, $
                             zones: zones, $
                 menu_configurable: 1}

      hardware = {hardware, etalon: etalon, $
                             video: video, $
                          shutters: shutters, $
                 menu_configurable: 1}

controller = {controller,scheduler: scheduler, $
                          behavior: behavior, $
                            ticker: ticker, $
                 menu_configurable: 1}

programs = {programs, direct_video: svid, $
                         phase_map: pmap, $
                           spectra: spex, $
                             focus: fox, $
                             chord: chrd, $
                       phase_shift: pshf, $
                 menu_configurable: 1}


;========================================================================
; Finally, build a single structure that describes the host environment
; in which we are executing:
    host   = {host,       hardware: hardware, $
                         operation: operation, $
                          programs: programs, $
                        controller: controller, $
                            colors: culz, $
                            netcdf: replicate(netcdf, 2)}

    scene       = bytarr(viewscale*host.hardware.video.columns/scale, viewscale*host.hardware.video.rows/scale)
    view        = bytarr(host.hardware.video.columns, host.hardware.video.rows)
end

