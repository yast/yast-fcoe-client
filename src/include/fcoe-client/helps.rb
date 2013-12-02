# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2006 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	include/fcoe-client/helps.ycp
# Package:	Configuration of fcoe-client
# Summary:	Help texts of all the dialogs
# Authors:	Gabriele Mohr <gs@suse.de>
#
module Yast
  module FcoeClientHelpsInclude
    def initialize_fcoe_client_helps(include_target)
      textdomain "fcoe-client"

      # All helps are here
      @HELPS = {
        # Read dialog help 1/2
        "read"          => _(
          "<p><b><big>Initializing fcoe-client Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ) +
          # Read dialog help 2/2
          _(
            "<p><b><big>Aborting Initialization:</big></b><br>\nSafely abort the configuration utility by pressing <b>Abort</b> now.</p>\n"
          ),
        # Write dialog help 1/2
        "write"         => _(
          "<p><b><big>Saving fcoe-client Configuration</big></b><br>\nPlease wait...<br></p>\n"
        ) +
          # Write dialog help 2/2
          _(
            "<p><b><big>Aborting Saving:</big></b><br>\n" +
              "Abort the save procedure by pressing <b>Abort</b>.\n" +
              "An additional dialog informs whether it is safe to do so.\n" +
              "</p>\n"
          ),
        # Summary dialog help 1/3
        "summary"       => _(
          "<p><b><big>FcoeClient Configuration</big></b><br>\nConfigure fcoe-client here.<br></p>\n"
        ) +
          # Summary dialog help 2/3
          _(
            "<p><b><big>Adding a fcoe-client:</big></b><br>\n" +
              "Choose a fcoe-client from the list of detected fcoe-clients.\n" +
              "If your fcoe-client was not detected, use <b>Other (not detected)</b>.\n" +
              "Then press <b>Configure</b>.</p>\n"
          ) +
          # Summary dialog help 3/3
          _(
            "<p><b><big>Editing or Deleting:</big></b><br>\n" +
              "If you press <b>Edit</b>, an additional dialog in which to change\n" +
              "the configuration opens.</p>\n"
          ),
        # Services dialog help 1/3
        "services"      => _(
          "<p><b><big>Starting of services</big><br></b><br>" +
          "Enable or disable the start of the services <b>fcoe</b> and <b>lldpad</b> at boot time.</p>"
        ) +
          # Services dialog help 2/3
          _(
            "<p>Starting the service <b>fcoe</b> means starting the <i>Fibre Channel over " +
              "Ethernet</i> service daemon <i>fcoemon</i> which controls the FCoE interfaces and " +
              "establishes a connection with the daemon <i>lldpad</i>.</p>"
          ) +
          # Services dialog help 3/3
          _(
            "<p>The <b>lldpad</b> service provides the <i>Link Layer Discovery Protocol</i> agent " +
            "daemon <i>lldpad</i>, which informs <i>fcoemon</i> about DCB (Data Center Bridging) " +
            "features and configuration of the interfaces.</p>"
          ),
        # Interfaces dialog help 1/5
        "interfaces"    => _(
          "<p><b><big>Network interface overview</big></b></p>"
        ) +
          # Interfaces dialog help 2/5
          _(
            "<p>The interfaces dialog shows all detected netcards including the status of VLAN " +
            "and FCoE configuration.<br>FCoE is possible if a VLAN interface is configured for FCoE " +
            "on the switch.<br>" +
            "For every netcard (network interface), this is shown in column <i>FCoE VLAN Interface</i>.</p>"
          ) +
          # Interfaces dialog help 3/5
          _("<p>It's possible to retry the check for FCoE services by using <b>Retry Detection</b>" +
            "(might be required for interfaces needing some time to get up).</p>"
            ) +
          # Interfaces dialog help 4/5
          _(
            "<p>The values for <i>FCoE VLAN Interface</i> in detail:<br>" +
              "<b>not available</b>: Fibre Channel over Ethernet is not possible " +
              "(must be enabled on the switch first).<br>" +
              "<b>not configured</b>: FCoE is possible but not yet activated.<br>" +
              "Press <b>Create FCoE VLAN Interface</b> to activate.<br>" +
              "If the FCoE VLAN interface has already been created, the name " +
              "is shown in the column, e.g. eth3.200.</p>"
          ) +
          # Interfaces dialog help 4/5
          _(
            "<p>To change the configuration of a FCoE VLAN interface, click on <b>Change Settings</b>.</p>"
          ),
        # Configuration dialog help 1/3
        "configuration" => _(
          "<p><b><big>General Configuration of FCoE</big></b></p>"
        ) +
          # Configuration dialog help 2/3
          _(
            "<p>Configure the general settings for the FCoE system service. The settings are written to '/etc/fcoe/config'.</p>"
          ) +
          #  Configuration dialog help 3/3
          _(
            "<p>The values are:<br>\n" +
              "<b>Debug</b>: <i>yes</i> or <i>no</i><br>" +
              "This is used to enable or disable debugging messages from the fcoe service script and <i>fcoemon</i>.<br>" +
              "<b>Use syslog</b>: <i>yes</i> or <i>no</i><br>" +
              "Messages are sent to the system log if set to <i>yes</i> (data are logged to /var/log/messages).</p>"
          ),
        # edit dialog help 1/3
        "change"        => _(
          "<p>Edit Settings in /etc/fcoe/ethx</p>"
        ) +
          # Edit dialog help 2/3
          _(
            "<p>The daemon <i>fcoemon</i> reads these configuration files on initialization.<br>" +
              "There is a file for every interface and the values indicate whether FCoE instances " +
              "should be created and if DCB is required.</p>"
          ) +
          # Edit dialog help 3/3
          _(
            "<p>The values are:<br>" +
              "<b>FCoE Enable</b>: <i>yes</i> or <i>no</i><br>" +
              "Enable or disable the creation of FCoE instances.<br>" +
              "<b>DCB Required</b>: <i>yes</i> or <i>no</i><br>" +
              "The default is <i>yes</i>, DCB is usually required.<br>" +
              "<b>AUTO VLAN</b>: <i>yes</i> or <i>no</i><br>" +
              "If set to <i>yes</i> 'fcoemon' will create the VLAN interfaces automatically.</p>"
          )
      } 

      # EOF
    end
  end
end
