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

# File:	clients/fcoe-client_auto.ycp
# Package:	Configuration of fcoe-client
# Summary:	Client for autoinstallation
# Authors:	Gabriele Mohr <gs@suse.de>
#
#
# This is a client for autoinstallation. It takes its arguments,
# goes through the configuration and return the setting.
# Does not do any changes to the configuration.

# @param function to execute
# @param map/list of fcoe-client settings
# @return [Hash] edited settings, Summary or boolean on success depending on called function
# @example map mm = $[ "FAIL_DELAY" : "77" ];
# @example map ret = WFM::CallFunction ("fcoe-client_auto", [ "Summary", mm ]);
module Yast
  class FcoeClientAutoClient < Client
    def main
      Yast.import "UI"

      textdomain "fcoe-client"

      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("FcoeClient auto started")

      Yast.import "FcoeClient"
      Yast.include self, "fcoe-client/wizards.rb"

      @ret = nil
      @func = ""
      @param = {}

      # Check arguments
      if Ops.greater_than(Builtins.size(WFM.Args), 0) &&
          Ops.is_string?(WFM.Args(0))
        @func = Convert.to_string(WFM.Args(0))
        if Ops.greater_than(Builtins.size(WFM.Args), 1) &&
            Ops.is_map?(WFM.Args(1))
          @param = Convert.to_map(WFM.Args(1))
        end
      end
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      # Create a summary
      if @func == "Summary"
        @ret = Ops.get_string(FcoeClient.Summary, 0, "")
      # Reset configuration
      elsif @func == "Reset"
        FcoeClient.Import({})
        @ret = {}
      # Change configuration (run AutoSequence)
      elsif @func == "Change"
        @ret = FcoeClientAutoSequence()
      # Import configuration
      elsif @func == "Import"
        @ret = FcoeClient.Import(@param)
      # Return actual state
      elsif @func == "Export"
        @ret = FcoeClient.Export
      # Return needed packages
      elsif @func == "Packages"
        @ret = FcoeClient.AutoPackages
      # Read current state
      elsif @func == "Read"
        Yast.import "Progress"
        @progress_orig = Progress.set(false)
        @ret = FcoeClient.Read
        Progress.set(@progress_orig)
      # Write given settings
      elsif @func == "Write"
        Yast.import "Progress"
        @progress_orig = Progress.set(false)

        @success = true
        @start_fcoe = false
        @detected_netcards = []
        @index = 0

        # prepare for AutoYaST
        @imported_netcards = FcoeClient.GetNetworkCards
        Builtins.y2milestone(
          "Imported information about netcards: %1",
          @imported_netcards
        )

        # AutoYaST will install package 'fcoe-utils' ( checks AutoPackages() )

        # Start services 'fcoe' and 'lldpad'
        @success = FcoeClient.ServiceStatus
        if @success
          Builtins.y2milestone("Services fcoe and lldpad started")
        else
          Builtins.y2error("Cannot start services - stopping auto installation")
          return false
        end
        # Reset info about netcards and get current values
        FcoeClient.ResetNetworkCards
        @detected_netcards = FcoeClient.DetectNetworkCards(FcoeClient.ProbeNetcards)

        if @detected_netcards.empty?
          Builtins.y2error(
            "Cannot detect network cards - stopping auto installation"
          )
          return false
        else
           Builtins.y2milestone(
            "Information about detected netcards: %1",
            @detected_netcards
          )
        end

        # Check imported data
        Builtins.foreach(@imported_netcards) do |card|
          if Ops.get_string(card, "fcoe_vlan", "") != FcoeClient.NOT_AVAILABLE &&
              Ops.get_string(card, "fcoe_vlan", "") != FcoeClient.NOT_CONFIGURED
            # any FCoE VLAN interface is configured
            @start_fcoe = true
          end
        end

        # If any FcoE interface is found in imported data we try to start FCoE
        # for all interfaces which are not yet configured, i.e. where starting of
        # FCoE is possible. We can not start exactly the interface from imported
        # data because the numeration of interfaces (eth0, eth1...) may differ.
        Builtins.foreach(@detected_netcards) do |card|
          vlan_interface = ""
          fcoe_vlan_interface = ""
          command = ""
          output = {}
          ifcfg_file = ""
          status_map = {}
          if Ops.get_string(card, "fcoe_vlan", "") == FcoeClient.NOT_CONFIGURED
            command = Builtins.sformat(
              "fipvlan -c -s %1",
              Ops.get_string(card, "dev_name", "")
            )
            ifcfg_file = Builtins.sformat(
              "/etc/sysconfig/network/ifcfg-%1.%2",
              Ops.get_string(card, "dev_name", ""),
              Ops.get_string(card, "vlan_interface", "")
            )
            # if /etc/sysconfig/network/ifcfg-<vlan-interface> already exists
            # call 'ifup' for the interface (creates /proc/net/vlan/<vlan-interface>)
            if FileUtils.Exists(ifcfg_file)
              cmd_ifup = Builtins.sformat(
                "ifup %1.%2",
                Ops.get_string(card, "dev_name", ""),
                Ops.get_string(card, "vlan_interface", "")
              )
              Builtins.y2milestone("Executing command: %1", cmd_ifup)
              output = Convert.to_map(
                SCR.Execute(path(".target.bash_output"), cmd_ifup)
              )
              Builtins.y2milestone("Output: %1", output)

              if Ops.get_integer(output, "exit", 255) == 0
                # start FCoE
                command = Builtins.sformat(
                  "fipvlan -s %1",
                  Ops.get_string(card, "dev_name", "")
                )
              end
            end

            Builtins.y2milestone("Executing command: %1", command)
            output = Convert.to_map(
              SCR.Execute(path(".target.bash_output"), command)
            )
            Builtins.y2milestone("Output: %1", output)

            if Ops.get_integer(output, "exit", 255) != 0
              Builtins.y2error(
                "Cannot create and start FCoE on %1",
                Ops.get_string(card, "dev_name", "")
              ) # get FCoE VLAN interface
            else
              if Ops.get_string(card, "vlan_interface", "") == "0"
                # VLAN interface "0" means start FCoE on network interface
                fcoe_vlan_interface = Ops.get_string(card, "dev_name", "")
              else
                fcoe_vlan_interface = FcoeClient.GetFcoeVlanInterface(
                  Ops.get_string(card, "dev_name", ""),
                  Ops.get_string(card, "vlan_interface", "")
                )
              end
              if fcoe_vlan_interface != ""
                Builtins.y2milestone(
                  "FCoE VLAN interface %1 created/started",
                  fcoe_vlan_interface
                )
                # create /etc/fcoe/ethx file and get values
                status_map = FcoeClient.CreateFcoeConfig(
                  fcoe_vlan_interface,
                  card
                )
                # apply modified data
                Ops.set(
                  @detected_netcards,
                  [@index, "fcoe_vlan"],
                  fcoe_vlan_interface
                )
                Ops.set(
                  @detected_netcards,
                  [@index, "cfg_device"],
                  Ops.get_string(status_map, "cfg_device", "")
                )
                Ops.set(
                  @detected_netcards,
                  [@index, "fcoe_enable"],
                  Ops.get_string(status_map, "FCOE_ENABLE", "")
                )
                Ops.set(
                  @detected_netcards,
                  [@index, "dcb_required"],
                  Ops.get_string(status_map, "DCB_REQUIRED", "")
                )
              else
                Builtins.y2error(
                  "FCoE VLAN interface not configured for %1",
                  Ops.get_string(card, "dev_name", "")
                )
              end
            end
          end
          @index = Ops.add(@index, 1)
        end if @start_fcoe
        Builtins.y2milestone(
          "Set NEW information about network cards: %1",
          @detected_netcards
        )
        # Set new information about netcards
        FcoeClient.SetNetworkCards(@detected_netcards)

        # FcoeClient::SetModified(true) is called in FcoeClient::Import(),
        # i.e. modified is set before calling FcoeClient::Write()
        @ret = FcoeClient.Write

        Progress.set(@progress_orig)
      # did configuration changed
      # return boolean
      elsif @func == "GetModified"
        @ret = FcoeClient.Modified
      # set configuration as changed
      # return boolean
      elsif @func == "SetModified"
        FcoeClient.SetModified(true)
        @ret = true
      else
        Builtins.y2error("Unknown function: %1", @func)
        @ret = false
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("FcoeClient auto finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::FcoeClientAutoClient.new.main
