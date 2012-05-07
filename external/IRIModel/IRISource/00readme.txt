		International Reference Ionosphere 2007 (IRI2007) Software
		----------------------------------------------------------

================================================================================
IMPORTANT: Updates and new versions of the IRI programs will be reported through 
the IRInfo electronic mailer distribution. To subscribe send e-mail to 
Majordomo@nssdc.gsfc.nasa.gov with the following text in the body of the
message: subscribe iri (use 'unsubscribe' to remove yourself from the list)
================================================================================

The IRI is a joined project of the Committee on Space Research (COSPAR) and the 
International Union of Radio Science (URSI). IRI is an empirical model specifying
monthly averages of electron density, ion composition, electron temperature, and 
ion temperature in the altitude range from 50 km to 1500 km.

This directory includes the FORTRAN program, coefficients, and indices files for 
the latest version of the International Reference Ionosphere model: IRI2007. This
version includes several options for different parts and parameters. A logical
array JF(30) is used to set these options. The IRI-recommended set of options
can be found in the COMMENT section at the beginning of IRISUB.FOR. IRITEST.FOR 
sets these options as the default.

The compilation/link command in Fortran 77 is:
f77 -o iri iritest.for irisub.for irifun.for iritec.for iridreg.for igrf.for cira.for

================================================================================
IMPORTANT: Please note that the following files have NOT been changed and are the
same as for IRI2001: CCIR%%, URSI%%, DGRF45-DGRF95,
================================================================================
 
Directory Contents:
-----------------------------------------------------------------------------------

00_iri2007.tar	TAR file that includes all files from this directory. Was created
				in UNIX using 'tar -cvf 00_iri2007.tar *'. UNIX command to unpack
				is "tar -xvf 00_iri2007.tar". 
				 
irisub.for	    This file contains the main subroutine iri_sub. It computes 
                height profiles if IRI output parameters (Ne, Te, Ti, Ni, vi) 
                for specified date and location. Also included is the 
                subroutine iri_web that computes output parameters versus
                latitude, longitude (geog. or geom.), year, day of year, hour 
                (LT or UT), and month. An example of how to call and use iri_web 
                is shown in iritest.for. Compilation of iritest.for requires
                irisub.for, irifun.for, iritec.for, iridreg.for, igrf.for, and
                cira.for.

irifun.for	    This file contains the subroutines and functions that are 
                required for running IRI.

iridreg.for     Subroutines for the D region models of Friedrich-Torkar
                and of Danilov et al.

iritec.for 	    This file includes the subroutines for computing the ionospheric 
                electron content from 60km up to a specified upper limit. 

cira.for	    This file includes the subroutines and functions for computing 
		        the COSPAR International Reference Ionosphere 1986 (CIRA-86) 
                neutral temperature. 

igrf.for        This file includes the subroutines for the International
                Geomagnetic Reference Field (IGRF).

dgrf%%.dat      Definitive IGRF coefficients for the years 1945 to 2000 in steps
                of 5 years (%%=45, 50, etc.)(ASCII).
igrf05.dat      IGRF coefficients for 2005 (ASCII).
igrf05s.dat     IGRF coefficients for 2005-2010 (ASCII).

iritest.for 	Test program indicating how to use of the IRI subroutines. 
                Requires irisub, irifun, iritec, iridreg, igrf,and cira.

input.txt       Input parameters for a few examples using the iritest.for program.
output.txt 	    Output from the test program for the input.txt input parameters.

ig_rz.dat	    This file contains the solar and ionospheric indices (IG12, Rz12) 
                for the time period from Jan 1958 onward. The file is updated 
                quarterly. It is read by subroutine tcon in irifun.for (ASCII). 

ap.dat		    This file provides the 3-hour ap magnetic index and F10.7 daily
				index from 1960 onward (ASCII).

CCIR%%.ASC,	    Coefficient files for the global representation of the F2 peak
   URSI%%.ASC	peak parameters (foF2, M3000) where %% = Month+10 (ASCII). CCIR is
                the model recommended by the International Committee Consultative  
                on Radiocommunication (CCIR) of the International Union of 
                Telecommunication (ITU). URSI is the model recommended by the 
                International Union of Radio Science. IRI recommends the CCIR
                model for the continents and the URSI model for the ocean areas.
                If a single model is needed globally URSI is recommended.

Stand-alone Programs:

IMAZ			The Ionospheric model for the Auroral Zone (IMAZ) specifies the
				electron density in the auroral E-region using a NeuralNet
				approach and expecting as input (auroral) latitude, longitude, year,
				day of year, hour, 3-hourly Ap, daily F10.7, and riometer 
				absoprtion as an optional input if available. Consist of the
				following files iri_imaz.for, imaztest.for, chapman.prn, 
				press_60deg.txt, press_70deg.txt, and 00readme_imaz.txt.
	
akebono_te.for	Model for the plasmspheric electron temperature based on Akebono 
				measurements. The file includes the model subroutines and 
				coefficients and a simple driver program to illustrate its usage.  
-----------------------------------------------------------------------------------

Please consult the 'listing of changes' in the comments section at the top 
of each one of these programs for recent corrections and improvements.

More information about the IRI project can be found at
	http://modelweb.gsfc.nasa.gov/ionos/iri.html
IRI parameters can be calculated and plotted online at
	http://modelweb.gsfc.nasa.gov/models/iri.html

------------------------ dieter bilitza ------------------ May 2007
