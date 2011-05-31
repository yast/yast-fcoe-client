# Makefile.am for fcoe-client/src

yncludedir = @yncludedir@/fcoe-client

client_DATA =			\
	fcoe-client.ycp		\
	fcoe-client_auto.ycp	\
	fcoe-client_proposal.ycp        \
        fcoe-client_finish.ycp          \
        inst_fcoe-client.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp

desktop_DATA =			\
	fcoe-client.desktop

module_DATA =			\
	FcoeClient.ycp


# create a symlink for local build, #145327
fcoe-client:
	ln -sf . $@
ycpchook = fcoe-client

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
