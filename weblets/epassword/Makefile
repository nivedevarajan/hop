#*=====================================================================*/
#*    serrano/prgm/project/hop/2.0.x/weblets/epassword/Makefile        */
#*    -------------------------------------------------------------    */
#*    Author      :  Manuel Serrano                                    */
#*    Creation    :  Fri Jan 20 14:35:57 2006                          */
#*    Last change :  Wed Oct 14 11:41:03 2009 (serrano)                */
#*    Copyright   :  2006-09 Manuel Serrano                            */
#*    -------------------------------------------------------------    */
#*    The Makefile of the password weblet                              */
#*=====================================================================*/

#*---------------------------------------------------------------------*/
#*    CONFIG ...                                                       */
#*---------------------------------------------------------------------*/
TITLE = epassword
VERSION = 1.0.0
MINHOP = $(HOPRELEASE) 
MAXHOP =
CATEGORY = hop
DATE = 18 april 2008

#*---------------------------------------------------------------------*/
#*    POPULATION                                                       */
#*---------------------------------------------------------------------*/
SOURCES		= epassword.hss epassword.hop
POPULATION	= Makefile $(SOURCES) \
		  etc/weblet.info.in etc/logo.png etc/favicon.png \
                  etc/epassword.wiki.in

build: etc/weblet.info etc/$(TITLE).wiki .afile

clean:

distclean:
	$(RM) etc/weblet.info etc/$(TITLE).wiki

#*---------------------------------------------------------------------*/
#*    Configuration                                                    */
#*---------------------------------------------------------------------*/
-include ../../etc/Makefile.hopconfig
-include ../../etc/Makefile.version
include ../../etc/Makefile.weblet

