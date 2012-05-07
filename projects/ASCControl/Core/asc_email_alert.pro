
pro asc_email_alert, subject=subject, $
                     body=body                     

  if not keyword_set(subject) then subject = 'ASC COntrol Email Alert'
  if not keyword_set(body) then body = 'No message body supplied'
  
  address = ['9076870046@txt.att.net', $
             'dhampton@gi.alaska.edu', $
             'callumenator@gmail.com']
             
  for k = 0, n_elements(address) - 1 do begin
    cmd = 'CD C:\Program Files\bmail\ &'
    cmd += ' bmail.exe -s fuzz.gi.alaska.edu -t ' + address[k] 
    cmd += ' -f solis@gi.alaska.edu '
    cmd += '-a "' + subject + '"'
    cmd += ' -b "' + body + '"'
    spawn, cmd, /nowait
  endfor

end