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

# File:	include/fcoe-client/complex.ycp
# Package:	Configuration of fcoe-client
# Summary:	Dialogs definitions
# Authors:	Gabriele Mohr <gs@suse.de>
#
module Yast
  module FcoeClientComplexInclude
    def initialize_fcoe_client_complex(include_target)
      Yast.import "UI"

      textdomain "fcoe-client"

      Yast.import "Label"
      Yast.import "Popup"
      Yast.import "Wizard"
      Yast.import "Confirm"
      Yast.import "FcoeClient"
      Yast.import "Service"
      Yast.import "Stage"
      Yast.import "FileUtils"

      Yast.include include_target, "fcoe-client/helps.rb"
      Yast.include include_target, "fcoe-client/dialogs.rb"

      @yes_no_mapping = {
        # setting of config value is 'yes'
        "yes" => _("yes"),
        # setting of config value is 'no'
        "no"  => _("no"),
        nil   => ""
      }
    end

    # Show a popup on abort if data are modified and
    # check list of commands to revert changes done to the system.
    # This function is also called during installation if user aborts
    # the 'FCoE client configuration', i.e. commands from revert list
    # are executed and list is reset.
    # @return true if users aborts installation
    def ReallyAbort
      Builtins.y2milestone("Aborting FCoE configuration")

      # Services started at installation time are stopped on reboot.
      # Revert start of 'fcoemon' or 'lldpad' socket if started but not needed.
      if !Stage.initial
        if FcoeClient.fcoe_started && !FcoeClient.fcoemonSocketEnabled?
          FcoeClient.fcoemonSocketStop
          Service.Stop("fcoe")
        end
        if FcoeClient.lldpad_started && !FcoeClient.lldpadSocketEnabled?
          FcoeClient.lldpadSocketStop
          Service.Stop("lldpad")
        end
      end
      return true if !FcoeClient.Modified

      abort = Popup.ReallyAbort(true)

      if abort
        # check revert list
        revert_list = FcoeClient.GetRevertCommands
        if revert_list == []
          Builtins.y2milestone("Nothing to revert")
        else
          Builtins.foreach(
            Convert.convert(
              revert_list,
              :from => "list",
              :to   => "list <string>"
            )
          ) do |command|
            Builtins.y2milestone("Calling %1", command)
            output = Convert.to_map(
              SCR.Execute(path(".target.bash_output"), command)
            )
            Builtins.y2milestone("Output: %1", output)
            if Ops.get_integer(output, "exit", 255) != 0
              # text of an error popup
              Popup.Error(
                Builtins.sformat(
                  _("Cannot remove the FCoE interface.\nCommand %1 failed."),
                  command
                )
              )
            end
          end
          FcoeClient.ResetRevertCommands # important during installation
        end
      end
      abort
    end

    # Read settings dialog
    # @return `abort if aborted and `next otherwise
    def ReadDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "read", ""))

      return :abort if !Confirm.MustBeRoot
      ret = FcoeClient.Read
      ret ? :next : :abort
    end

    # Write settings dialog
    # @return `abort if aborted and `next otherwise
    def WriteDialog
      Wizard.RestoreHelp(Ops.get_string(@HELPS, "write", ""))
      Builtins.y2milestone("Writing configuration")

      ret = FcoeClient.Write
      ret ? :next : :abort
    end

    # Init
    #
    def InitServicesDialog(id)
      Builtins.y2milestone("Init services dialog")
      Builtins.y2milestone("Data modified: %1", FcoeClient.Modified)
      status_map = FcoeClient.GetStartStatus

      if Ops.get_boolean(status_map, "fcoe", false) == true
        UI.ChangeWidget(Id("fcoe_startup_auto"), :Value, true)
        UI.ChangeWidget(Id("fcoe_startup_manual"), :Value, false)
      else
        UI.ChangeWidget(Id("fcoe_startup_auto"), :Value, false)
        UI.ChangeWidget(Id("fcoe_startup_manual"), :Value, true)
      end

      if Ops.get_boolean(status_map, "lldpad", false) == true
        UI.ChangeWidget(Id("lldpad_startup_auto"), :Value, true)
        UI.ChangeWidget(Id("lldpad_startup_manual"), :Value, false)
      else
        UI.ChangeWidget(Id("lldpad_startup_auto"), :Value, false)
        UI.ChangeWidget(Id("lldpad_startup_manual"), :Value, true)
      end

      nil
    end

    #
    # Adjust buttons, means set 'Change Settings' and 'Create VLAN' sensitive or insensitive
    #
    def AdjustButtons
      card = FcoeClient.GetCurrentNetworkCard

      # check VLAN status
      if Ops.get_string(card, "fcoe_vlan", "") == FcoeClient.NOT_CONFIGURED
        UI.ChangeWidget(Id(:edit), :Enabled, true)
        UI.ChangeWidget(Id(:create), :Enabled, true)
        UI.ChangeWidget(Id(:remove), :Enabled, false)
      elsif Ops.get_string(card, "fcoe_vlan", "") == FcoeClient.NOT_AVAILABLE
        UI.ChangeWidget(Id(:edit), :Enabled, false)
        UI.ChangeWidget(Id(:create), :Enabled, false)
        UI.ChangeWidget(Id(:remove), :Enabled, false)
      else
        UI.ChangeWidget(Id(:edit), :Enabled, true)
        UI.ChangeWidget(Id(:create), :Enabled, false)
        UI.ChangeWidget(Id(:remove), :Enabled, true)
      end

      nil
    end

    def ShowInterfaces
      row = 0

      netcards = FcoeClient.GetNetworkCards
      Builtins.y2milestone("Got netcards: %1", netcards)

      table_items = []

      fcoe_vlan_mapping = {
        # FCoE is not available on the interface
        @NOT_AVAILABLE  => _("not available"),
        # the interface is not configured for FCoE
        @NOT_CONFIGURED => _("not configured"),
        nil             => ""
      }

      flags_mapping = {
        # the flag is 'true'
        true => _("true"),
        # the flag is 'false'
        false  => _("false"),
        # the flag is not set at all
        nil   => _("not set")
      }
      Builtins.foreach(netcards) do |card|
        table_items = Builtins.add(
          table_items,
          Item(
            Id(row),
            card["dev_name"] || "",
            card["mac_addr"] || "",
            card["device"] || "",
            card["vlan_interface"] || "",
            fcoe_vlan_mapping[card["fcoe_vlan"]] || card["fcoe_vlan"],
            @yes_no_mapping[card["fcoe_enable"]],
            @yes_no_mapping[card["dcb_required"]],
            @yes_no_mapping[card["auto_vlan"]],
            @yes_no_mapping[card["dcb_capable"]],
            card["driver"] || "",
            flags_mapping[card["fcoe_flag"]],
            flags_mapping[card["iscsi_flag"]],
            flags_mapping[card["storage_only"]]
          )
        )
        row = Ops.add(row, 1)
      end

      UI.ChangeWidget(Id(:interfaces), :Items, table_items)
      # set current item
      UI.ChangeWidget(Id(:interfaces), :CurrentItem, Id(0))

      FcoeClient.current_card = 0

      nil
    end

    def InitInterfacesDialog(id)
      Builtins.y2milestone("Init interfaces dialog")

      ShowInterfaces()
      AdjustButtons()

      nil
    end

    #
    #
    #
    def InitConfigurationDialog(id)
      Builtins.y2milestone("Init configuration dialog")

      fcoe_config = FcoeClient.GetFcoeConfig
      Builtins.y2milestone("Fcoe configuration %1", fcoe_config)

      if fcoe_config != {}
        if Ops.get(fcoe_config, "DEBUG", "") == "yes"
          UI.ChangeWidget(Id("debug"), :Value, "yes")
        else
          UI.ChangeWidget(Id("debug"), :Value, "no")
        end

        if Ops.get(fcoe_config, "USE_SYSLOG", "") == "yes"
          UI.ChangeWidget(Id("syslog"), :Value, "yes")
        else
          UI.ChangeWidget(Id("syslog"), :Value, "no")
        end
      end

      nil
    end

    #
    # InitEditDialog
    #
    def InitEditDialog(id)
      Builtins.y2milestone("Init edit dialog")
      cards = FcoeClient.GetNetworkCards
      card = Ops.get(cards, FcoeClient.current_card, {})

      # set values for 'FCoE Enabled' and 'DCB Required'
      UI.ChangeWidget(
        Id(:fcoe),
        :Value,
        Ops.get_string(card, "fcoe_enable", "")
      )
      UI.ChangeWidget(
        Id(:dcb),
        :Value,
        Ops.get_string(card, "dcb_required", "")
      )
      UI.ChangeWidget(Id(:auto), :Value, Ops.get_string(card, "auto_vlan", ""))
      if Ops.get_string(card, "fcoe_vlan", "") != FcoeClient.NOT_CONFIGURED
        # don't allow to change AUTO_VLAN for a configured interface
        # (would require new /etc/fcoe/cfg-file)
        UI.ChangeWidget(Id(:auto), :Enabled, false)
      end
      # headline of the edit dialog - configuration of values for a certain network interface
      UI.ChangeWidget(
        Id(:heading),
        :Value,
        Builtins.sformat(
          _("Configuration of VLAN interface %1 on %2"),
          Ops.get_string(card, "vlan_interface", ""),
          Ops.get_string(card, "dev_name", "")
        )
      )

      nil
    end

    # Handle
    #
    def HandleServicesDialog(_id, _event)
      nil
    end

    def HandleInterfacesDialog(id, event)
      event = deep_copy(event)
      action = Ops.get(event, "ID")

      Builtins.y2milestone("Event: %1", event)

      if action == :edit
        Builtins.y2milestone("Action: %1, returning %1", action)
        return :edit
      elsif action == :interfaces
        FcoeClient.current_card = Convert.to_integer(
          UI.QueryWidget(Id(:interfaces), :CurrentItem)
        )
        AdjustButtons()
      elsif action == :retry
        FcoeClient.ResetNetworkCards
        netcards = FcoeClient.DetectNetworkCards(FcoeClient.ProbeNetcards)
        FcoeClient.SetNetworkCards(netcards)
        ShowInterfaces()
      elsif action == :create
        # haendel:~/:[0]# fipvlan -c -s eth3
        # Fibre Channel Forwarders Discovered
        # interface       | VLAN | FCF MAC
        # ------------------------------------------
        # eth3            | 200  | 00:0d:ec:a2:ef:00
        # Created VLAN device eth3.200
        # Starting FCoE on interface eth3.200

        card = FcoeClient.GetCurrentNetworkCard
        Builtins.y2milestone("Selected card: %1", card)
        dev_name = Ops.get_string(card, "dev_name", "")
        vlan_interface = card.fetch("vlan_interface", "") # eg. "200"

        configured_vlans = FcoeClient.IsConfigured(dev_name)

        if configured_vlans != []
          Builtins.y2milestone(
            "Configured VLANs on %1: %2",
            dev_name,
            configured_vlans
          )

          if Builtins.contains(configured_vlans, "0")
            # text of an error popup
            Popup.Error(
              Builtins.sformat(
                _("Cannot start FCoE on VLAN interface %1\n" +
                    "because FCoE is already configured on\n" +
                    "network interface %2 itself."),
                vlan_interface, dev_name
              )
            )
            return nil
          end
          if vlan_interface == "0"
            # text of an error popup
            Popup.Error(
              Builtins.sformat(
                _("Cannot start FCoE on network interface %1 itself\n" +
                    "because FCoE is already configured on\n" +
                    "VLAN interface(s) %2."),
                dev_name, configured_vlans
              )
            )
            return nil
          end
          Popup.Warning(
            Builtins.sformat(
              "FCoE VLAN interface(s) %1 already configured on %2.",
              configured_vlans,
              dev_name
            )
          )
        end

        if card["auto_vlan"] == "yes" || vlan_interface == "0"
          command = "fipvlan -c -s -f '-fcoe' #{dev_name}"
        else
          command = "fipvlan -c -s #{dev_name}"
        end

        output = {}
        fcoe_vlan_interface = ""
        status_map = {}

        ifcfg_file = "/etc/sysconfig/network/ifcfg-#{dev_name}.#{vlan_interface}"

        # headline of a popup: creating and starting Fibre Channel over Ethernet
        ret = Popup.YesNoHeadline(
          _("Creating and Starting FCoE on Detected VLAN Device"),
          # question to the user: really create and start FCoE
          Builtins.sformat(
            _("Do you really want to create a FCoE network\n" +
                "interface for discovered VLAN interface %1\n" +
                "on %2 and start the FCoE initiator?"),
            vlan_interface, dev_name
          )
        )
        if ret == true
          if Stage.initial # first stage of installation - create and start FCoE VLAN interface
            # execute command, e.g. 'fipvlan -c -s eth3'

            Builtins.y2milestone("Executing command: %1", command)
            output = Convert.to_map(
              SCR.Execute(path(".target.bash_output"), command)
            )
            Builtins.y2milestone("Output: %1", output)

            if Ops.get_integer(output, "exit", 255) != 0
              # text of an error popup
              Popup.Error(
                Builtins.sformat(
                  _("Cannot create and start FCoE on %1."),
                  dev_name
                )
              )
              return nil
            end # installed system - if VLAN already exists only start FCoE
          else
            # if /etc/sysconfig/network/ifcfg-<if>.<vlan> already exists
            # call 'ifup' for the interface (creates /proc/net/vlan/<if>.<vlan>)
            if FileUtils.Exists(ifcfg_file)
              cmd_ifup = Builtins.sformat("ifup %1.%2", dev_name, vlan_interface)
              Builtins.y2milestone("Executing command: %1", cmd_ifup)
              output = Convert.to_map(
                SCR.Execute(path(".target.bash_output"), cmd_ifup)
              )
              Builtins.y2milestone("Output: %1", output)

              if Ops.get_integer(output, "exit", 255) == 0
                # only start FCoE
                command = Builtins.sformat("fipvlan -s %1", dev_name)
              end
            end

            Builtins.y2milestone("Executing command: %1", command)
            output = Convert.to_map(
              SCR.Execute(path(".target.bash_output"), command)
            )
            Builtins.y2milestone("Output: %1", output)
            if Ops.get_integer(output, "exit", 255) != 0
              if !FcoeClient.TestMode
                # text of an error popup: command failed on the network interface
                Popup.Error(
                  Builtins.sformat(
                    _("Command \"%1\" on %2 failed."),
                    command,
                    dev_name
                  )
                )
                return nil
              else
                Popup.Warning(
                  _(
                    "Creating FCoE interface failed.\nContinue because running in test mode"
                  )
                )
              end
            end
          end
        else
          Builtins.y2milestone("Starting FCoE canceled")
          return nil
        end

        # Get values and exchange list (table) entries

        if Ops.get_string(card, "vlan_interface", "") == "0"
          # for VLAN interface "0" there isn't an entry in /proc/net/vlan/config
          fcoe_vlan_interface = Ops.get_string(card, "dev_name", "") # get interface from /proc/net/vlan/config
        else
          fcoe_vlan_interface = FcoeClient.GetFcoeVlanInterface(
            Ops.get_string(card, "dev_name", ""),
            Ops.get_string(card, "vlan_interface", "")
          )
        end

        if fcoe_vlan_interface != ""
          # write config for FCoE VLAN interface
          status_map = FcoeClient.CreateFcoeConfig(fcoe_vlan_interface, card)
          Builtins.y2milestone("GOT status map: %1", status_map)

          # command to be able to revert the creation of FCoE VLAN interface in case of 'Cancel'
          # FcoeClient::AddRevertCommand( sformat("fcoeadm -d %1 && vconfig rem %2", status_map["cfg_device"]:"", fcoe_vlan_interface ) );
          # 'fcoeadm -d <if>/<if>.<vlan>' fails here, 'vconfig rem <if>.<vlan>' succeeds
          # and removes the interface properly (tested on SP2 RC1)
          # TODO: Retest for SLES12
          FcoeClient.AddRevertCommand(
            Builtins.sformat("vconfig rem %1", fcoe_vlan_interface)
          )
        else
          fcoe_vlan_interface = FcoeClient.NOT_CONFIGURED
        end

        # set new values in global map network_interfaces
        Ops.set(card, "fcoe_vlan", fcoe_vlan_interface)
        Ops.set(
          card,
          "fcoe_enable",
          Ops.get_string(status_map, "FCOE_ENABLE", "")
        )
        Ops.set(
          card,
          "dcb_required",
          Ops.get_string(status_map, "DCB_REQUIRED", "")
        )
        Ops.set(card, "auto_vlan", Ops.get_string(status_map, "AUTO_VLAN", ""))
        Ops.set(
          card,
          "cfg_device",
          Ops.get_string(status_map, "cfg_device", "")
        )
        FcoeClient.SetModified(true)

        FcoeClient.SetNetworkCardsValue(FcoeClient.current_card, card)
        Builtins.y2milestone(
          "Current network interfaces: %1",
          FcoeClient.GetNetworkCards
        )

        # replace values in table
        UI.ChangeWidget(
          Id(:interfaces),
          Cell(FcoeClient.current_card, 4),
          fcoe_vlan_interface
        )
        UI.ChangeWidget(
          Id(:interfaces),
          Cell(FcoeClient.current_card, 5),
          @yes_no_mapping[status_map["FCOE_ENABLE"]]
        )
        UI.ChangeWidget(
          Id(:interfaces),
          Cell(FcoeClient.current_card, 6),
          @yes_no_mapping[status_map["DCB_REQUIRED"]]
        )
        UI.ChangeWidget(
          Id(:interfaces),
          Cell(FcoeClient.current_card, 7),
          @yes_no_mapping[status_map["AUTO_VLAN"]]
        )
        AdjustButtons()
      elsif action == :remove
        card = FcoeClient.GetCurrentNetworkCard
        output = {}
        command = ""
        # popup text: really remove FCoE VLAN interface
        popup_text = Builtins.sformat(
          _("Do you really want to remove the FCoE interface %1?"),
          Ops.get_string(card, "fcoe_vlan", "")
        )

        if !Stage.initial
          # popup text continues
          popup_text = Ops.add(
            Ops.add(popup_text, "\n"),
            _(
              "Attention:\n" +
                "Make sure the interface is not essential for a used device.\n" +
                "Removing it may result in an unusable system."
            )
          )
        else
          # popup text continues
          popup_text = Ops.add(
            Ops.add(popup_text, "\n"),
            _(
              "Don't remove the interface if it's related\nto an already activated multipath device."
            )
          )
        end

        ret = Popup.AnyQuestion(
          Label.WarningMsg,
          popup_text,
          Label.ContinueButton,
          Label.CancelButton,
          :focus_no
        ) # default: Cancel

        if ret == true
          Builtins.y2milestone(
            "Removing %1",
            Ops.get_string(card, "fcoe_vlan", "")
          )

          # call fcoeadm -d <fcoe_vlan> first (bnc #719443)
          command = Builtins.sformat(
            "fcoeadm -d %1",
            Ops.get_string(card, "cfg_device", "")
          )
          Builtins.y2milestone("Calling %1", command)
          output = Convert.to_map(
            SCR.Execute(path(".target.bash_output"), command)
          )
          Builtins.y2milestone("Output: %1", output)

          if Ops.get_integer(output, "exit", 255) == 0 || FcoeClient.TestMode
            command = Builtins.sformat(
              "vconfig rem %1",
              Ops.get_string(card, "fcoe_vlan", "")
            )
            Builtins.y2milestone("Calling %1", command)
            output = Convert.to_map(
              SCR.Execute(path(".target.bash_output"), command)
            )
            Builtins.y2milestone("Output: %1", output)

            if Ops.get_integer(output, "exit", 255) == 0 || FcoeClient.TestMode
              del_cfg = true
              # check whether /etc/fcoe/cfg-file is also used for another VLAN interface.
              # Example: eth1 have FCoE configured on VLAN 200 and 300 with AUTO_VLAN="yes"
              #          -> /etc/fcoe/cfg-eth1 applies to both.
              interfaces = FcoeClient.GetNetworkCards

              Builtins.foreach(interfaces) do |interface|
                if Ops.get_string(interface, "dev_name", "") ==
                    Ops.get_string(card, "dev_name", "") &&
                    Ops.get_string(interface, "vlan_interface", "") !=
                      Ops.get_string(card, "vlan_interface", "") &&
                    Ops.get_string(interface, "cfg_device", "") ==
                      Ops.get_string(card, "cfg_device", "")
                  Builtins.y2milestone(
                    Builtins.sformat(
                      "/etc/fcoe/cfg-%1 also used for VLAN %2",
                      Ops.get_string(card, "cfg_device", ""),
                      Ops.get_string(interface, "vlan_interface", "")
                    )
                  )
                  del_cfg = false
                end
              end

              if del_cfg
                command = Builtins.sformat(
                  "rm /etc/fcoe/cfg-%1",
                  Ops.get_string(card, "cfg_device", "")
                )
                Builtins.y2milestone("Calling %1", command)
                output = Convert.to_map(
                  SCR.Execute(path(".target.bash_output"), command)
                )
                Builtins.y2milestone("Output: %1", output)
              else
                Builtins.y2milestone(
                  Builtins.sformat(
                    "/etc/fcoe/cfg-%1 not deleted",
                    Ops.get_string(card, "cfg_device", "")
                  )
                )
              end

              if Ops.get_string(card, "vlan_interface", "") != "0"
                command = Builtins.sformat(
                  "rm /etc/sysconfig/network/ifcfg-%1",
                  Ops.get_string(card, "fcoe_vlan", "")
                )
                Builtins.y2milestone("Calling %1", command)
                output = Convert.to_map(
                  SCR.Execute(path(".target.bash_output"), command)
                )
                Builtins.y2milestone("Output: %1", output)
              else
                Builtins.y2milestone(
                  Builtins.sformat(
                    "/etc/sysconfig/network/ifcfg-%1 not deleted",
                    Ops.get_string(card, "fcoe_vlan", "")
                  )
                )
              end
              # set new values in global map network_interfaces
              Ops.set(card, "fcoe_vlan", FcoeClient.NOT_CONFIGURED)
              Ops.set(card, "fcoe_enable", "yes")
              # exception for Broadcom cards: DCB_REQUIRED should be set to "no" (bnc #728658)
              Ops.set(
                card,
                "dcb_required",
                Ops.get_string(card, "driver", "") != "bnx2x" &&
                  Ops.get_string(card, "dcb_capable", "") == "yes" ? "yes" : "no"
              )
              Ops.set(card, "auto_vlan", "yes") # default is "yes" (bnc #724563)
              Ops.set(card, "cfg_device", "")
              FcoeClient.SetModified(true)

              FcoeClient.SetNetworkCardsValue(FcoeClient.current_card, card)
              Builtins.y2milestone(
                "Current network interfaces: %1",
                FcoeClient.GetNetworkCards
              )

              # replace values in table
              UI.ChangeWidget(
                Id(:interfaces),
                Cell(FcoeClient.current_card, 4),
                card["fcoe_vlan"] || ""
              )
              UI.ChangeWidget(
                Id(:interfaces),
                Cell(FcoeClient.current_card, 5),
                @yes_no_mapping[card["fcoe_enable"]]
              )
              UI.ChangeWidget(
                Id(:interfaces),
                Cell(FcoeClient.current_card, 6),
                @yes_no_mapping[card["dcb_required"]]
              )
              UI.ChangeWidget(
                Id(:interfaces),
                Cell(FcoeClient.current_card, 7),
                @yes_no_mapping[card["auto_vlan"]]
              )
              AdjustButtons()
            else
              Popup.Error(
                Builtins.sformat(
                  _("Removing of interface %1 failed."),
                  Ops.get_string(card, "fcoe_vlan", "")
                )
              )
              Builtins.y2error(
                "Removing of interface %1 failed",
                Ops.get_string(card, "fcoe_vlan", "")
              )
            end
          else
            Popup.Error(
              Builtins.sformat(
                _("Destroying interface %1 failed."),
                Ops.get_string(card, "fcoe_vlan", "")
              )
            )
            Builtins.y2error(
              "Destroying interface %1 failed",
              Ops.get_string(card, "fcoe_vlan", "")
            )
          end
        end
      end

      nil
    end

    def HandleConfigurationDialog(_id, _event)
      nil
    end

    def HandleEditDialog(id, event)
      event = deep_copy(event)
      action = Ops.get(event, "ID")
      card = FcoeClient.GetCurrentNetworkCard

      if action == :dcb
        dcb_required = Convert.to_string(UI.QueryWidget(Id(:dcb), :Value))
        if dcb_required == "yes" &&
            Ops.get_string(card, "dcb_capable", "") != "yes"
          # text of a warning popup
          Popup.Warning(
            _(
              "DCB Required is set to \"yes\" but the\ninterface isn't DCB capable."
            )
          )
          Builtins.y2warning(
            "DCB_REQUIRED is set to yes but the interface isn't DCB capable"
          )
        end
      end

      nil
    end

    # Store
    #

    def StoreServicesDialog(id, event)
      event = deep_copy(event)
      Builtins.y2milestone("Store services dialog")

      fcoe_auto = Convert.to_boolean(
        UI.QueryWidget(Id("fcoe_startup_auto"), :Value)
      )
      FcoeClient.SetStartStatus("fcoe", fcoe_auto)

      Builtins.y2milestone(
        "Setting auto start of service 'fcoe' to: %1",
        fcoe_auto
      )

      lldpad_auto = Convert.to_boolean(
        UI.QueryWidget(Id("lldpad_startup_auto"), :Value)
      )

      if fcoe_auto && !lldpad_auto
        # text of an information (notify)  popup
        Popup.Notify(
          _(
            "Service 'fcoe' requires enabled service 'lldpad'.\nEnabling start on boot of service 'lldpad'."
          )
        )
        lldpad_auto = true
      end

      FcoeClient.SetStartStatus("lldpad", lldpad_auto)
      Builtins.y2milestone(
        "Setting auto start of service 'lldpad' to: %1",
        lldpad_auto
      )

      nil
    end

    def StoreInterfacesDialog(id, event)
      event = deep_copy(event)
      Builtins.y2milestone("Store interfaces dialog")

      nil
    end

    def StoreConfigurationDialog(id, event)
      event = deep_copy(event)
      Builtins.y2milestone("Store configuration dialog")

      config = FcoeClient.GetFcoeConfig

      debug_val = Convert.to_string(UI.QueryWidget(Id("debug"), :Value))
      if Ops.get_string(config, "DEBUG", "") != debug_val
        FcoeClient.SetFcoeConfigValue("DEBUG", debug_val)
        FcoeClient.SetModified(true)
      end
      syslog_val = Convert.to_string(UI.QueryWidget(Id("syslog"), :Value))

      if Ops.get_string(config, "USE_SYSLOG", "") != syslog_val
        FcoeClient.SetFcoeConfigValue("USE_SYSLOG", syslog_val)
        FcoeClient.SetModified(true)
      end

      nil
    end

    def StoreEditDialog(id, event)
      event = deep_copy(event)
      Builtins.y2milestone("Store edit dialog")

      card = FcoeClient.GetCurrentNetworkCard

      fcoe_enabled = Convert.to_string(UI.QueryWidget(Id(:fcoe), :Value))
      if Ops.get_string(card, "fcoe_enable", "") != fcoe_enabled
        Ops.set(card, "fcoe_enable", fcoe_enabled)
        FcoeClient.SetModified(true)
      end

      dcb_required = Convert.to_string(UI.QueryWidget(Id(:dcb), :Value))
      if Ops.get_string(card, "dcb_required", "") != dcb_required
        Ops.set(card, "dcb_required", dcb_required)
        FcoeClient.SetModified(true)
      end

      auto_vlan = Convert.to_string(UI.QueryWidget(Id(:auto), :Value))
      if Ops.get_string(card, "auto_vlan", "") != auto_vlan
        Ops.set(card, "auto_vlan", auto_vlan)
        FcoeClient.SetModified(true)
      end

      FcoeClient.SetNetworkCardsValue(FcoeClient.current_card, card)

      Builtins.y2milestone("Current data: %1", FcoeClient.GetNetworkCards)

      nil
    end
  end
end
