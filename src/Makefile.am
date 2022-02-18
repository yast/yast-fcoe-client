# Sources for fcoe-client

module_DATA = \
  modules/FcoeClient.rb

client_DATA = \
  clients/fcoe-client_finish.rb \
  clients/inst_fcoe-client.rb \
  clients/fcoe-client_proposal.rb \
  clients/fcoe-client_auto.rb \
  clients/fcoe-client.rb

yncludedir = @yncludedir@/fcoe-client
ynclude_DATA = \
  include/fcoe-client/wizards.rb \
  include/fcoe-client/dialogs.rb \
  include/fcoe-client/complex.rb \
  include/fcoe-client/helps.rb

schemafilesdir = $(schemadir)/autoyast/rnc
schemafiles_DATA = \
  autoyast-rnc/fcoe-client.rnc

scrconf_DATA = \
  scrconf/fcoe_config.scr \
  scrconf/fcoe_cfg-ethx.scr

desktop_DATA = \
  desktop/org.opensuse.yast.FCoEClient.desktop

symbolicdir = @icondir@/hicolor/symbolic/apps
symbolic_DATA = \
  icons/hicolor/symbolic/apps/yast-fcoe-symbolic.svg
scalabledir = @icondir@/hicolor/scalable/apps
scalable_DATA = \
  icons/hicolor/scalable/apps/yast-fcoe.svg

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA)  $(scrconf_DATA) $(desktop_DATA) \
             $(schemafiles_DATA) $(symbolic_DATA) $(scalable_DATA)

include $(top_srcdir)/Makefile.am.common
