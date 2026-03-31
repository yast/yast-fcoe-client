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

require "y2fcoe_client/actions"

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
        FcoeClient.ReadNetworkCards
        ShowInterfaces()
      elsif action == :create
        action = Y2FcoeClient::Actions::Create.new(FcoeClient.current_card)
        card = action.card
        dev_name = card.fetch("dev_name", "")
        Builtins.y2milestone("Selected card: %1", card)

        issues = action.validate
        if issues.error?
          Popup.Error(issues.find(&:error?).message)
          return nil
        elsif issues.any?
          Popup.Warning(issues.first.message)
        end

        # headline of a popup: creating and starting Fibre Channel over Ethernet
        ret = Popup.YesNoHeadline(
          _("Creating and Starting FCoE on Detected VLAN Device"),
          # question to the user: really create and start FCoE
          Builtins.sformat(
            _("Do you really want to create a FCoE network\n" +
                "interface for discovered VLAN interface %1\n" +
                "on %2 and start the FCoE initiator?"),
            card.fetch("vlan_interface", ""), dev_name
          )
        )
        if ret == true
          issues = action.execute
          if issues.any?
            if FcoeClient.TestMode
              Popup.Warning(
                _("Creating FCoE interface failed.\nContinue because running in test mode")
              )
            else
              if Stage.initial
                Popup.Error(
                  Builtins.sformat(_("Cannot create and start FCoE on %1."), dev_name)
                )
              else
                Popup.Error(issues.first.message)
              end
              return nil
            end
          end
        else
          Builtins.y2milestone("Starting FCoE canceled")
          return nil
        end

        Builtins.y2milestone("Current network interfaces: %1", FcoeClient.GetNetworkCards)
        RefreshCurrentCard()
      elsif action == :remove
        card = FcoeClient.GetCurrentNetworkCard
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
          action = Y2FcoeClient::Actions::Remove.new(FcoeClient.current_card)
          issues = action.execute

          if issues.any?
            Popup.Error(issues.first.message)
          else
            Builtins.y2milestone("Current network interfaces: %1", FcoeClient.GetNetworkCards)
            RefreshCurrentCard()
          end
        end
      end

      nil
    end

    # Replace values in table
    def RefreshCurrentCard
      card = FcoeClient.GetCurrentNetworkCard

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
