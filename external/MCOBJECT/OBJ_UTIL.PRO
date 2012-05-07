;==========================================================================================
;
; This is a set of routines for creating, storing and loading "McObject"s.
; McObjects are "Mark Conde's Objects".  They are simple files, that contain arrays of
; IDL data structures, together with IDL source code for manipulating the structures.
; That is, each object file has a header section, a code section, and a data section.
;
; The system is very simple, and is intended to work with older versions of IDL (pre-V4).
;
; Mark Conde, Bromley, August 1999.

;==========================================================================================
; Search the current IDL paths for an instance of a file defined by codespec, and return 
; a full path to it. fexist is returned 0 if no instance is found, otherwise its 1:
pro get_mccode, codespec, fullcode, fexist
    fexist = 0
    j      = 0
    places = expand_path(!path)
    if strpos(places, "]") ge 0 then sep = "" 
    if strpos(places, "/") ge 0 then sep = "/" 
    if strpos(places, "\") ge 0 then sep = "\" 
    places = expand_path(!path, /array)
    while j lt n_elements(places) and not(fexist) do begin
          fullcode = findfile(places(j) + sep + codespec)
          if fullcode(0) ne '' then fexist = 1
          j = j + 1
    endwhile
    fullcode = places(j-1) + sep + fullcode
end

;==========================================================================================
; Replace single ' characters with pairs ('') in a string:
pro obj_dquote, instr, outstr
    for j=0,strlen(instr) do begin
        chr = strmid(instr, j, 1)
        if j eq 0 then outstr = chr else outstr = outstr + chr
        if chr eq string(39b) then outstr = outstr + string(39b)
    endfor
end

;==========================================================================================
;   This procedure reads declarations in an object's .pro file to build the required 
;   parts of an object's constructor command:

pro obj_reqfields, myname, cmd, dynamic=dyn
    find_obj, myname, obj_names, class_names, descriptions, count, /code_only
    get_header, obj_names(0), header, status=sts, /code_only
    
;   Now, define the required header properties:
    cmd = cmd + 'id: 0L,' 
    cmd = cmd + 'idl_version: !version,' 
    matched = where(strpos(strupcase(header(0,*)), 'CLASS_NAME') ge 0, nmat)
    if nmat gt 0 then cmd = cmd +       'class_name: ' + string(39b) + header(1, matched(0)) + string(39b) + ',' 
    matched = where(strpos(strupcase(header(0,*)), 'DESCRIPTION') ge 0, nmat)
    if nmat gt 0 then cmd = cmd +      'description: ' + string(39b) + header(1, matched(0)) + string(39b) + ',' 
    matched = where(strpos(strupcase(header(0,*)), 'PURPOSE') ge 0, nmat)
    if nmat gt 0 then cmd = cmd +          'purpose: ' + string(39b) + header(1, matched(0)) + string(39b) + ',' 
;    matched = where(strpos(strupcase(header(0,*)), 'IDL_VERSION') ge 0, nmat)
;    if nmat gt 0 then cmd = cmd +      'idl_version: ' + string(39b) + header(1, matched(0)) + string(39b) + ',' 
;    matched = where(strpos(strupcase(header(0,*)), 'OPERATING_SYSTEM') ge 0, nmat)
;    if nmat gt 0 then cmd = cmd + 'operating_system: ' + string(39b) + header(1, matched(0)) + string(39b) + ',' 
    matched = where(strpos(strupcase(header(0,*)), 'AUTHOR') ge 0, nmat)
    if nmat gt 0 then cmd = cmd +           'author: ' + string(39b) + header(1, matched(0)) + string(39b) + ',' 
;   And, add structure specified by the dynamic keyword, (if any):                        
    if not(keyword_set(dyn)) then dyn = 'None'
    if dyn eq ''             then dyn = 'None'
    obj_dquote, dyn, ddn
    cmd = cmd +          'dynamic: ''' + ddn + ''' '
    if  dyn ne 'None' then cmd = cmd + ',' + dyn 

;   Finally, add the closing bracket:
    cmd = cmd + '}'

end

;==========================================================================================
; Insert methods from the class file to the code section of the object file:
pro write_methods, class_name, objun
    oneline = 'Dummy'
    get_mccode, class_name+'.pro', fullcode, fexist
    openr, codun, fullcode(0), /get_lun
    while not(eof(codun)) do begin
          readf,  codun, oneline
          writeu, objun, oneline
    endwhile
    close, codun
    free_lun, codun
end

;==========================================================================================
; Read the code section of a McObject file, and write a .pro file for use by the 
; currently executing IDL program:
pro load_code, objun, class_name, overwrite=ovr
    oneline = 'Empty'
    while strpos(oneline, 'class_name') lt 0 do readu, objun, oneline
    class_name = str_sep(oneline, '=')
    class_name = strlowcase(strcompress(class_name(1), /remove_all))
    while strpos(oneline, '>>>> begin methods') lt 0 do readu, objun, oneline
    
    get_mccode, class_name + '.pro', fullcode, fexist
    if not(fexist) then begin
       fullcode = 'c:\' + class_name + '.pro'
       !path    = !path + ";c:\"
    endif
    if keyword_set(overwrite) then fexist = 0
    if not(fexist) then openw, codun, fullcode(0), /get_lun

    readu,  objun, oneline
    repeat begin
          if not(fexist) then printf, codun, oneline
          readu,  objun, oneline
    endrep until strpos(oneline, '>>>> end methods') ge 0 
    while strpos(oneline, '>>>> begin data') lt 0 do readu, objun, oneline
    if not(fexist) then close,    codun
    if not(fexist) then free_lun, codun
end

;========================================================================================================
;
; Routines below here are intended as the public interface to create, store, and load "McObject"s:
;
;========================================================================================================

;==========================================================================================
; Create a new instance of a McObject of the specified class. "Dynamic" is a keyword that 
; can be used to add fields to the object dynamically.  It is a string that specifies the
; extra fields. "Creator" is a returned string.  It is the actual command used to
; create the instance.
pro new_obj, class_name, instance, dynamic=dyn, creator=cmd
    call_procedure, class_name
    status = execute(class_name + '_new, instance, dynamic=dyn, creator=cmd')
end

;==========================================================================================
; Given a header array that was read from a McObject with 'get_header', this will print 
; it nicely on the console:
pro print_header, header
    keylen = max(strlen(header(0,*)))
    hfmt = '(a' + strcompress(string(keylen), /remove_all) + ', a,a)'
    for j=0,n_elements(header(0,*))-1 do print, header(0,j), ' = ', header(1,j), format=hfmt
end

function checkobj, objfile
   status = 1
   if not(fexist(objfile)) then return, status
   on_ioerror, OBJFAIL
   openr, objun, objfile, /get_lun
   xx = 0b
   attempts = 0
   while  string(xx) ne '>' and not(eof(objun)) and attempts lt 20 do begin
          xx = 0b
          readu, objun, xx
          attempts = attempts + 1
   endwhile
   htest = string(xx)
   for j = 0,30 do begin
       xx = 0b
       readu, objun, xx
       htest = htest + string(xx)
   endfor
   close, objun
   free_lun, objun
   if strpos(strupcase(htest), strupcase('>> begin comments')) ge 0 then status = 0
OBJFAIL: close, objun
   free_lun, objun
   return, status
   end

;==========================================================================================
; Read the header fields from a McObject, returning a (2, n) string array. The first 
; column is the header keywords, the second is the header settings.
pro get_header, objfile, header, status=sts, code_only=code_only
    newflag = 1
    xdr=1
    if keyword_set(code_only) then xdr=0
    sts = 1
    if checkobj(objfile) then return
    if fexist(objfile) then begin
       openr, objun, objfile, /get_lun, xdr=xdr
       oneline = 'Empty'
       attempts = 0
       while strpos(oneline, '>>>> begin declarations') lt 0 and $
             not(eof(objun)) and $
             attempts lt 64 do begin
             if xdr then readu, objun, oneline else readf, objun, oneline
             attempts = attempts + 1
        endwhile
       
       if not(eof(objun)) and attempts lt 64 then begin
          if xdr then readu, objun, oneline else readf, objun, oneline
          while strpos(oneline, '>>>> end declarations') lt 0 do begin
                parts    = str_sep(oneline, ';')
                parts    = parts(n_elements(parts)-1)
                parts    = str_sep(oneline, '=')
                parts    = strtrim(parts, 2)
                if (n_elements(header) lt 1 or newflag) then begin
                   header = parts 
                endif else begin
                   header = [[header], [parts]]
                endelse
                newflag=0
                if xdr then readu, objun, oneline else readf, objun, oneline
          endwhile
          sts = 0
       endif else begin
          sts = 1
       endelse
       close, objun
       free_lun, objun
    endif
end

;==========================================================================================
; Given a header array, read from a McObject with 'get_header', this will extract the 
; setting for a specified field.
function get_field, header, keystring
    setting = 'unknown'
    nsets   = 0
    idx = where(strpos(strupcase(header(0,*)), strupcase(keystring)) ge 0, nsets)
    idx = idx(0)
    if nsets gt 0 then setting = header(1, idx)
    return, setting
end

;========================================================================================================
; This routine can 'build' the dynamic specification string, field by field, for a McObject.
pro obj_dynbuild, dynspec, field
    if n_elements(dynspec) lt 1 then dynspec = field else dynspec = dynspec + ',' + field    
end

;==========================================================================================
; This routine will look for McObject files matching the 'fspec' and 'purpose' 
; parameters. It returns lists of object file names, class names and descriptions, 
; along with a count of matches.
pro find_obj, fspec, obj_names, class_names, descriptions, count, purpose=pps, code_only=code_only
    candidates =  findfile(fspec)
    count      =  0
    if candidates(0) eq '' then return
    for j=0,n_elements(candidates)-1 do begin
        get_header, candidates(j), header, status=badone, code_only=code_only
        if not badone then begin
           purpose = get_field(header, 'purpose')
           if keyword_set(pps) then keystring = pps else keystring = purpose
           if strpos(strupcase(purpose), strupcase(keystring)) ge 0 then begin
              if count eq 0 then obj_names    = candidates(j) $
                            else obj_names    = [obj_names, candidates(j)]
              if count eq 0 then class_names  = get_field(header, 'class_name') $
                            else class_names  = [class_names, get_field(header, 'class_name')]
              if count eq 0 then descriptions = get_field(header, 'description') $
                            else descriptions = [descriptions, get_field(header, 'description')]
              count = count + 1
           endif
        endif
    endfor
end

;==========================================================================================
; This will load a McObject from disk file 'objfile', returning it as 'instance'. Also,
; it will create an IDL methods file. If the methods file already exists, it will not 
; replace it unless 'overwrite' is specified.
pro load_obj, instance, overwrite=ovr, file=objfile, code_only=code_only
    if not(keyword_set(objfile)) then objfile=pickfile(title='Choose an object to load:')
    get_header, objfile, header, status=load_err, code_only=code_only
    if (not(load_err)) then begin
        dimz = fix(str_sep(get_field(header, 'dimensions'), ','))
        dyn  = get_field(header, 'dynamic')
        if not(keyword_set(code_only)) then begin
           openr, objun, objfile, /get_lun, /xdr
           load_code, objun, class_name, overwrite=ovr 
           new_obj, class_name, instance, dynamic=dyn
           instance = make_array(value=instance, dimension=dimz)
           readu, objun, instance
           close,    objun
           free_lun, objun    
        endif else call_procedure, class_name
        call_procedure, class_name + '_autorun', instance
    endif
end

;==========================================================================================
; Save a McObject to disk. Saves both the data (instance) and the methods - which are 
; determined from the class_name field in the instance.
pro save_obj, objfile, instance
    dimz = size(instance)
    for j=1,dimz(0) do begin
        if j eq 1 then begin 
           dimspec = strcompress(string(dimz(j)), /remove_all)
        endif else begin
           dimspec = dimspec + ',' + strcompress(string(dimz(j)), /remove_all)
        endelse
    endfor
    
    openw,  objun, objfile, /get_lun, /xdr

    writeu, objun, '>>>> begin comments'
    writeu, objun, 'This is a McObject: An XDR file containing both binary data and IDL code to manipulate it.'
    writeu, objun, 'Open with IDL using the LOAD_OBJ routine.'
    writeu, objun, 'McObjects were created by Mark Conde, in Bromley, during August 1999. (Email: Mark.Conde@gi.alaska.edu)'
    writeu, objun, '>>>> end comments'
    writeu, objun, '>>>> begin declarations'
    writeu, objun, 'class_name = ' + instance(0).class_name
    writeu, objun, 'description = ' + instance(0).description
    writeu, objun, 'purpose = ' + instance(0).purpose
    writeu, objun, 'dimensions = ' + dimspec
    writeu, objun, 'dynamic = ' + instance(0).dynamic
    writeu, objun, 'write_date = ' + systime()
    writeu, objun, 'IDL_version = ' + instance(0).idl_version
    writeu, objun, 'operating_system = ' + instance(0).operating_system
    if strpos(tag_names(instance(0)), 'MENU_NAME') ge 0 then $
    writeu, objun, 'menu_name = ' + instance(0).menu_name
    if strpos(tag_names(instance(0)), 'REFRESH_NAME') ge 0 then $
    writeu, objun, 'menu_name = ' + instance(0).refresh_name
    if strpos(tag_names(instance(0)), 'SETTINGS_FUNCTION') ge 0 then $
    writeu, objun, 'menu_name = ' + instance(0).settings_function
    writeu, objun, '>>>> end declarations'
    writeu, objun, '>>>> begin methods'
    write_methods, instance(0).class_name, objun
    writeu, objun, '>>>> end methods'
    writeu, objun, '>>>> begin data'
    writeu, objun, instance
    writeu, objun, '>>>> end data'
    close,    objun
    free_lun, objun    
end

function obj_namelook, obj_arr, namez
    ncount = 0
    for j=0,n_elements(namez)-1 do begin
        spot = where(strupcase(obj_arr.name) eq strupcase(namez(j)), ncount)
        if ncount gt 0 then spot = spot(0) else spot = -1
        if n_elements(result) eq 0 then result = spot else result = [result, spot]
    endfor
    return, result
end

function obj_parlook, obj_arr, namez, par, missing=missing
    if not(keyword_set(missing)) then missing = 'Unknown'
    spots = obj_namelook(obj_arr, namez)
    ns    = 0
    goods       = where(spots ge 0, ns)
    if ns lt 1 then return, missing
    spots = spots(goods)
    partag = where(tag_names(obj_arr(0)) eq strupcase(par), ns)
    if ns lt 1 then return, missing
    return, obj_arr(spots).(partag(0))
end

