README FILE

IMAZ Ð Ionospheric Model for the Auroral Zone

Lee-Anne McKinnell, April 2007

(1) IMAZ has been developed for the purpose of obtaining prediction for the 
electron density in the auroral zone. It is implemented as a
separate option within IRI. 

(2) IMAZ is valid for the Auroral Zone latitudes (around 70 degrees), and for 
the altitude range from 50 km to about 150 km. 

(3) A program, called IMAZTEST.FOR, has been provided for testing the implementation.

(4) The main IMAZ subroutines are contained in a file called IRI_IMAZ.FOR, which
should be linked to IMAZTEST.FOR when compiling. 

(5) The following files are required by IRI_IMAZ.FOR: a) nighttruequiet.txt Ð 
which is required for determining the rest absorption in the case where absorption 
is considered as an input; b) chapman.prn Ð the chapman function is also required 
for determining the rest absorption; c) press_70deg.txt & press_60deg.txt Ð 
required for converting from pressure to altitude and back again, the model is 
developed using the pressure levels as an input, but the user friendly output is by
altitude level; 

(6) The following inputs to the model are required: a) Geographic
Latitude; b) Geographic Longitude; c) Year; d) day number; e) hour, in universal
time (UT); f) the riometer absorption (if this is not available, enter -1 and
the version that does not require this input will be used); g) the 3-hourly
planetary magnetic A index; h) the daily F10.7 solar flux value; i) the altitude 
for which the electron density is required (if the entire profile from 50 km to
about 150 km is required, then enter -1); 

(7) The output file contains 11 columns, the first 8 being the inputs,
then the altitude in km, the predicted electron density and the error on the log
of the predicted electron density. The density is 

(8) Note that the electron density is given as the logarithm (to base 10) of the 
electron density in [cm-3]. 

Reference:
McKinnel, L.A. and M. Friedrich, Results from a new lower ionosphere model, 
Adv. Space Res., 37, #5, 1045-1050, 2006.