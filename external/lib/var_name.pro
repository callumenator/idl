function var_name, invar
   dummy = 1
   status = execute('dummy = invar(-1)')
   name = str_sep(!err_string, ' ')
   name = strcompress(name(3), /remove_all)
   return, name   
end