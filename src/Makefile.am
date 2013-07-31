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

scrconf_DATA = \
  scrconf/fcoe_config.scr \
  scrconf/fcoe_cfg-ethx.scr

desktop_DATA = \
  desktop/fcoe-client.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(scrconf_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common