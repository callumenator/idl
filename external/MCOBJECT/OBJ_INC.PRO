;================================================================================================
;   This include file contains a code fragment needed to execute the list of commands needed to 
;   declare common blocks that will globally registered objects available to any program module:

    obj_reginfo, obj_names, obj_declns
    for j=0,n_elements(obj_declns)-1 do status = execute(obj_declns(j))
