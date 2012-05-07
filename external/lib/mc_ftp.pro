;============================================================================
pro mcftp_send_command, sockun, host, cmd, conceal=conceal, quiet=quiet
    printf, sockun, cmd
    printstr = cmd
    if keyword_set(conceal) then printstr = '******'
    if not(keyword_set(quiet)) then print, host.ip_address, '<- ', printstr
    mcftp_get_response, sockun, host, quiet=quiet
end

;============================================================================
pro mcftp_get_response, sockun, host, conceal=conceal, quiet=quiet
    on_ioerror, all_bytes_received
    reply = 'dummy'
    readf, sockun, reply
    repcode = strmid(reply, 0, 3)
    repsep  = strmid(reply, 3, 1)
    printstr = reply
    if keyword_set(conceal) then printstr = '******'
    if not(keyword_set(quiet)) then print, host.ip_address, '-> ', printstr
    if repsep eq ' ' then return
    while repsep eq '-' and strmid(reply, 0, 3) eq repcode do begin
       readf, sockun, reply
       printstr = reply
       if keyword_set(conceal) then printstr = '******'
       if not(keyword_set(quiet)) then print, host.ip_address, '-> ', printstr
       repcode = strmid(reply, 0, 3)
       repsep  = strmid(reply, 3, 1)
    endwhile
all_bytes_received:
end

;============================================================================
pro mcftp_receive_file, host
    socket, recsoc, host.ip_address, 'ftp-data', $
            connect_timeout=5, read_timeout=host.comms_timeout, write_timeout=host.comms_timeout, /get_lun
    on_ioerror, all_replies_are_in
    reply = 0b
receive_a_byte:
wait, 0.01
    readu, recsoc, reply
    print, string(reply)
    goto, receive_a_byte
all_replies_are_in:
    close, recsoc
    free_lun, recsoc
end

;============================================================================
pro mc_ftp, host, files, commands, quiet=quiet, method=method
    if n_elements(host)     eq 0 then host={s_mcftp_host,ip_address: 'carrot.pfrr.alaska.edu', $
                                                           username: 'anonymous', $
                                                           password: 'idl_program@somehost.edu', $
                                                   remote_directory: '.', $
                                                      comms_timeout: 10}
    if n_elements(files)    eq 0 then files    = [getenv('IDL_TMPDIR') + 'bib.txt']
    if n_elements(commands) eq 0 then commands = {s_mcftp_cmd, xfer: 'get', $
                                                       remote_mkdir: 0, $
                                                          xfer_mode: 'ascii'}
    if not(keyword_set(method)) then method = 'SPAWNED'

    xfer_list = mc_fileparse(files)

;---Do the ftp transfer using direct socket connections to the ftp server:
    if strupcase(strcompress(method, /remove_all)) eq 'DIRECT' then begin
       on_ioerror, bail_sock
       socket, sockun, host.ip_address, 'ftp', read_timeout=host.comms_timeout, write_timeout=host.comms_timeout, /get_lun
       on_ioerror, kill_sock
       mcftp_get_response, sockun, host, quiet=quiet
       mcftp_send_command, sockun, host, 'user ' + host.username, quiet=quiet
       mcftp_send_command, sockun, host, 'pass ' + host.password, /conceal, quiet=quiet
       mcftp_send_command, sockun, host, 'cwd '  + host.remote_directory, quiet=quiet
       mcftp_send_command, sockun, host,  commands.xfer_mode, quiet=quiet
       for j=0,n_elements(files)-1 do begin
           if strcompress(strupcase(commands.xfer), /remove_all) eq 'PUT' then begin
              mcftp_send_command, sockun, host, 'stor ' + xfer_list.fullname + ' ' + xfer_list.namepart, quiet=quiet
           endif else begin
   ;           mcftp_send_command, sockun, host, 'retr ' + xfer_list.namepart, quiet=quiet
              printf, sockun, 'retr ' + xfer_list.namepart
              mcftp_receive_file, host
           endelse
       endfor
       mcftp_send_command, sockun, host,  'quit', quiet=quiet
       mcftp_get_response, sockun, host, quiet=quiet

kill_sock:    
       close, sockun, /force
       free_lun, sockun
bail_sock:
    endif

;---Do the ftp transfer using a SPAWNED shell script:    
    if strupcase(strcompress(method, /remove_all)) eq 'SPAWNED' then begin
       ftp_script = getenv('IDL_TMPDIR') + 'idl_ftp_script.scr'
       openw, spunt, ftp_script, /get_lun
       printf, spunt, 'open ' + host.ip_address
       printf, spunt, 'user ' + host.username
       printf, spunt, 'pass ' + host.password
       if commands.remote_mkdir then begin
          mtree = str_sep(host.remote_directory, '/')
          printf, spunt, 'mkdir ' + mtree(0)
          btree = mtree(0) + '/'
          for j=1,n_elements(mtree)-1 do begin
              printf, spunt, 'mkdir ' + btree + mtree(j)
              btree = btree + mtree(j) + '/'
          endfor
       endif
       printf, spunt, 'cd '   + host.remote_directory
       printf, spunt, commands.xfer_mode
       for j=0,n_elements(files)-1 do begin
           if strcompress(strupcase(commands.xfer), /remove_all) eq 'PUT' then begin
              printf, spunt, 'put ' + xfer_list.fullname + ' ' + xfer_list.namepart
           endif else begin
              printf, spunt, 'get ' + xfer_list.namepart + ' ' + xfer_list.fullname 
           endelse
       endfor
       printf, spunt, 'quit'
       close, spunt
       free_lun, spunt
       spawn, 'ftp -n -i -s:' + ftp_script, exit_status=stat
       wait, 0.5
       file_delete, ftp_script
    endif
    
end