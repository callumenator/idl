@obj_util.pro


ofile = pickfile(title='Specify a McObject file:')
if fexist(ofile) then load_obj, instance, file=ofile else begin
   class = 'Dummy'
   print, 'File does not exist.  So, we''ll make a new object instead:'
   read, class, prompt='Class name: '
   new_obj, class, instance
endelse

top = n_tags(instance) - 1
actn = 'Edit'

if n_elements(instance) eq 0 then begin
   print, "Unable to load a valid McObject. Stopping."
endif

while actn ne 'Quit' do begin
   if actn eq 'Edit' then obj_edt, instance, tagz=indgen(top+1)
   if actn eq 'Add an element' then begin
      new_obj, instance(0).class_name, nob
      instance = [instance, nob]
   endif
   if actn eq 'Delete an element' then begin
      ilist = string(indgen(n_elements(instance))+1)
      mcchoice, 'Delete which one?', 'Element: ' + strcompress(ilist, /remove_all), sel
      veceldel, instance, sel.index
   endif
   if actn eq 'Choose last display tag index' then begin
      ilist = string(indgen(n_tags(instance(0))))
      mcchoice, 'Last element?', 'Tag: ' + strcompress(ilist, /remove_all), sel  
      top = sel.index
   endif
   save_obj, ofile, instance
   mcchoice, 'Now do what?', ['Edit', 'Add an element', 'Delete an element', 'Choose last display element', 'Quit'], choice
   actn = choice.name
endwhile

end

