;******************************************************************
function get_scrsize,prt=prt
device,get_screen_size=sc
if keyword_set(prt) then print,' Screen size (pixels): ',sc(0),' x',sc(1)
return,sc
end
