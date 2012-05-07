;==========================================================================================
;
; >>>> McObject Class: McTest 
;
; This file contains the method code for a test McObject class called "McTest".
; Mark Conde (Mc), Bromley, August 1999.

;==========================================================================================
; This is the (required) "new" method for a McTest McObject.

pro McTest_new, instance, dynamic=dyn, creator=cmd

    if not(keyword_set(dyn)) then dyn = 'None'
    obj_dquote, dyn, ddn
    
;   First, define the required header properties:
    cmd = 'instance = {class_name: ''McTest'',' 
    cmd = cmd +      'description: ''An object for tests and for prototyping'','
    cmd = cmd +          'purpose: ''Demonstration'','
    cmd = cmd +      'idl_version: ''3.5.1'','
    cmd = cmd + 'operating_system: ''Windows 2000 Professional'','
    cmd = cmd +          'dynamic: ''' + ddn + ''','
                
;   Next, add hard-coded properties specific to this object:
    cmd = cmd +           'author: ''Mark Conde'',' 
    cmd = cmd +         'an_array: fltarr(4,5)'

;   And, add structure specified by the dynamic keyword, (if any):                        
    if  dyn ne 'None' then cmd = cmd + ',' + dyn 

;   Finally, add the closing bracket:
    cmd = cmd + '}'
    
;   Now, create the instance:
    status = execute(cmd)
end

;==========================================================================================
; This is the (required) "autorun" method for a McTest McObject. If no autorun action is 
; needed, then this routine should simply exit with no action:

pro McTest_autorun, instance
    print, "A new instance of a McTest object has been created. The data structure is:" 
    help, instance, /structure
end

;==========================================================================================
; This is the (required) class method for creating a new instance of the McTest object. It
; would normally be an empty procedure, but it MUST be present, as the last procedure in 
; the methods file:

pro McTest
end

