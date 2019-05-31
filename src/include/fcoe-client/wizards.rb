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

# File:	include/fcoe-client/wizards.ycp
# Package:	Configuration of fcoe-client
# Summary:	Wizards definitions
# Authors:	Gabriele Mohr <gs@suse.de>
#
module Yast
  module FcoeClientWizardsInclude
    def initialize_fcoe_client_wizards(include_target)
      Yast.import "UI"

      textdomain "fcoe-client"

      Yast.import "Mode"
      Yast.import "Sequencer"
      Yast.import "Wizard"
      Yast.import "CWM"
      Yast.import "CWMTab"
      Yast.import "CWMServiceStart"

      Yast.include include_target, "fcoe-client/complex.rb"
      Yast.include include_target, "fcoe-client/dialogs.rb"
    end

    # Main workflow of the fcoe-client configuration
    # @return sequence result

    def GlobalDialog
      widgets = {
        "serv"   => {
          "widget"        => :custom,
          "help"          => Ops.get_string(@HELPS, "services", ""),
          "custom_widget" => ServicesDialogContent(),
          "handle"        => fun_ref(
            method(:HandleServicesDialog),
            "symbol (string, map)"
          ),
          "init"          => fun_ref(
            method(:InitServicesDialog),
            "void (string)"
          ),
          "store"         => fun_ref(
            method(:StoreServicesDialog),
            "void (string, map)"
          )
        },
        "inter"  => {
          "widget"        => :custom,
          "help"          => Ops.get_string(@HELPS, "interfaces", ""),
          "custom_widget" => InterfacesDialogContent(),
          "handle"        => fun_ref(
            method(:HandleInterfacesDialog),
            "symbol (string, map)"
          ),
          "init"          => fun_ref(
            method(:InitInterfacesDialog),
            "void (string)"
          ),
          "store"         => fun_ref(
            method(:StoreInterfacesDialog),
            "void (string, map)"
          )
        },
        "config" => {
          "widget"        => :custom,
          "help"          => Ops.get_string(@HELPS, "configuration", ""),
          "custom_widget" => ConfigurationDialogContent(),
          "init"          => fun_ref(
            method(:InitConfigurationDialog),
            "void (string)"
          ),
          "handle"        => fun_ref(
            method(:HandleConfigurationDialog),
            "symbol (string, map)"
          ),
          "store"         => fun_ref(
            method(:StoreConfigurationDialog),
            "void (string, map)"
          )
        }
      }
      tabs = {}
      tab_order = []
      ini_tab = ""

      if Stage.initial
        tabs = {
          "interfaces"    => {
            # Header of tab in tab widget
            "header"       => _("&Interfaces"),
            "widget_names" => ["inter"],
            "contents"     => InterfacesDialogContent()
          },
          "configuration" => {
            # Header of tab in tab widget
            "header"       => _("&Configuration"),
            "widget_names" => ["config"],
            "contents"     => ConfigurationDialogContent()
          }
        }
        ini_tab = "interfaces"
        tab_order = ["interfaces", "configuration"]
      else
        tabs = {
          "services"      => {
            # Header of tab in tab widget
            "header"       => _("&Services"),
            "widget_names" => ["serv"],
            "contents"     => ServicesDialogContent()
          },
          "interfaces"    => {
            # Header of tab in tab widget
            "header"       => _("&Interfaces"),
            "widget_names" => ["inter"],
            "contents"     => InterfacesDialogContent()
          },
          "configuration" => {
            # Header of tab in tab widget
            "header"       => _("&Configuration"),
            "widget_names" => ["config"],
            "contents"     => ConfigurationDialogContent()
          }
        }

        status_map = FcoeClient.GetStartStatus

        if CWMTab.LastTab == nil || CWMTab.LastTab == "" # first run
          if Ops.get(status_map, "fcoe", false) == true &&
              Ops.get(status_map, "lldpad", false) == true
            ini_tab = "interfaces"
          else
            ini_tab = "services"
          end
        else
          # get correct tab to return after 'Edit'
          ini_tab = CWMTab.LastTab
        end
        tab_order = ["services", "interfaces", "configuration"]
      end

      wd = {
        "tab" => CWMTab.CreateWidget(
          {
            "tab_order"    => tab_order,
            "tabs"         => tabs,
            "widget_descr" => widgets,
            "initial_tab"  => ini_tab
          }
        )
      }

      contents = VBox("tab")

      w = CWM.CreateWidgets(
        ["tab"],
        Convert.convert(
          wd,
          :from => "map <string, any>",
          :to   => "map <string, map <string, any>>"
        )
      )

      # Initialization dialog caption
      caption = _("Fibre Channel over Ethernet Configuration")
      contents = CWM.PrepareDialog(contents, w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        "", #help
        Label.BackButton,
        Label.FinishButton
      )
      Wizard.SetNextButton(:next, Label.OKButton)
      Wizard.SetAbortButton(:abort, Label.CancelButton)
      Wizard.HideBackButton

      # TODO: rename icon to yast-fcoe (yast2-theme package)
      if Mode.normal
        Wizard.SetDesktopTitleAndIcon("org.openSUSE.YaST.FCoEClient")
      else
        Wizard.SetTitleIcon("fcoe")
      end

      CWM.Run(w, { :abort => fun_ref(method(:ReallyAbort), "boolean ()") })
    end

    def EditDialog
      caption = _("Change FCoE Settings")

      widgets = {
        "edit" => {
          "widget"        => :custom,
          "help"          => Ops.get_string(@HELPS, "change", ""),
          "custom_widget" => EditDialogContents(),
          "init"          => fun_ref(method(:InitEditDialog), "void (string)"),
          "handle"        => fun_ref(
            method(:HandleEditDialog),
            "symbol (string, map)"
          ),
          "store"         => fun_ref(
            method(:StoreEditDialog),
            "void (string, map)"
          )
        }
      }

      contents = VBox("edit")

      w = CWM.CreateWidgets(
        ["edit"],
        Convert.convert(
          widgets,
          :from => "map <string, any>",
          :to   => "map <string, map <string, any>>"
        )
      )
      contents = CWM.PrepareDialog(contents, w)

      Wizard.SetContentsButtons(
        caption,
        contents,
        Ops.get_string(@HELPS, "change", ""), # help
        Label.BackButton,
        Label.NextButton
      )

      ret = CWM.Run(
        w,
        { :abort => fun_ref(method(:ReallyAbort), "boolean ()") }
      )

      deep_copy(ret)
    end


    def MainSequence
      aliases = { "global" => lambda { GlobalDialog() }, "edit" => lambda do
        EditDialog()
      end }

      sequence = {
        "ws_start" => "global",
        "global"   => { :abort => :abort, :edit => "edit", :next => :next },
        "edit"     => { :abort => :abort, :next => "global" }
      }

      Wizard.OpenNextBackDialog
      if Mode.normal
        Wizard.SetDesktopTitleAndIcon("org.openSUSE.YaST.FCoEClient")
      else
        Wizard.SetTitleIcon("fcoe")
      end

      ret = Sequencer.Run(aliases, sequence)

      Wizard.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of fcoe-client
    # @return sequence result
    def FcoeClientSequence
      aliases = {
        "read"  => [lambda { ReadDialog() }, true],
        "main"  => lambda { MainSequence() },
        "write" => [lambda { WriteDialog() }, true]
      }

      sequence = {
        "ws_start" => "read",
        "read"     => { :abort => :abort, :next => "main" },
        "main"     => { :abort => :abort, :next => "write" },
        "write"    => { :abort => :abort, :next => :next }
      }

      Wizard.OpenCancelOKDialog
      if Mode.normal
        Wizard.SetDesktopTitleAndIcon("org.openSUSE.YaST.FCoEClient")
      else
        Wizard.SetTitleIcon("fcoe")
      end

      ret = Sequencer.Run(aliases, sequence)

      Wizard.CloseDialog
      deep_copy(ret)
    end

    # Whole configuration of fcoe-client but without reading and writing.
    # For use with autoinstallation.
    # @return sequence result
    def FcoeClientAutoSequence
      # Initialization dialog caption
      caption = _("FcoeClient Configuration")
      # Initialization dialog contents
      contents = Label(_("Initializing..."))

      Wizard.CreateDialog
      Wizard.SetContentsButtons(
        caption,
        contents,
        "",
        Label.BackButton,
        Label.NextButton
      )

      ret = MainSequence()

      UI.CloseDialog
      deep_copy(ret)
    end
  end
end
