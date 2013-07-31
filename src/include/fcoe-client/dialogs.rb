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

# File:	include/fcoe-client/dialogs.ycp
# Package:	Configuration of fcoe-client
# Summary:	Dialogs definitions
# Authors:	Gabriele Mohr <gs@suse.de>
#
module Yast
  module FcoeClientDialogsInclude
    def initialize_fcoe_client_dialogs(include_target)
      textdomain "fcoe-client"

      Yast.import "Label"
      Yast.import "Wizard"
      Yast.import "FcoeClient"

      Yast.include include_target, "fcoe-client/helps.rb"

      @mbox_x = 1
      @mbox_y = Convert.convert(0.5, :from => "float", :to => "integer")

      @items_fcoe = VBox(
        VSpacing(0.4),
        Left(
          RadioButton(
            Id("fcoe_startup_auto"),
            Opt(:notify),
            # radio button: start service on boot
            _("When Booting")
          )
        ),
        Left(
          RadioButton(
            Id("fcoe_startup_manual"),
            Opt(:notify),
            # radio button: start service manually
            _("Manually")
          )
        ),
        VSpacing(0.4)
      )

      @items_lldpad = VBox(
        VSpacing(0.4),
        Left(
          RadioButton(
            Id("lldpad_startup_auto"),
            Opt(:notify),
            # radio button: start service on boot
            _("When Booting")
          )
        ),
        Left(
          RadioButton(
            Id("lldpad_startup_manual"),
            Opt(:notify),
            # radio button: start service manually
            _("Manually")
          )
        ),
        VSpacing(0.4)
      )
    end

    def EditDialogContents
      VBox(
        VStretch(),
        VSpacing(1),
        # heading is replaced later (InitEditDialog)
        Label(
          Id(:heading),
          "Configuration of Interface ......................."
        ),
        VSpacing(1),
        HBox(
          HStretch(),
          Frame(
            "",
            MarginBox(
              10,
              2,
              VBox(
                # combo box label: enable FCoE (yes/no)
                ComboBox(
                  Id(:fcoe),
                  _("&FCoE Enable"),
                  [Item(Id("yes"), "yes"), Item(Id("no"), "no", true)]
                ),
                VSpacing(1),
                # combo box label: require DCB (yes/no)
                ComboBox(
                  Id(:dcb),
                  Opt(:notify),
                  _("&DCB Required"),
                  [Item(Id("yes"), "yes"), Item(Id("no"), "no", true)]
                ),
                VSpacing(1),
                # combo box label: AUTO_VLAN setting (yes/no)
                ComboBox(
                  Id(:auto),
                  _("&AUTO_VLAN"),
                  [Item(Id("yes"), "yes"), Item(Id("no"), "no", true)]
                )
              )
            )
          ),
          HStretch()
        ),
        VStretch()
      )
    end

    # Services dialog
    # @return [Yast::Term]

    def ServicesDialogContent
      MarginBox(
        @mbox_x,
        @mbox_y,
        VBox(
          VSpacing(2.0),
          # frame containing radio buttons for fcoe service start
          Frame(
            _("FCoE Service Start"),
            VBox(RadioButtonGroup(Id("fcoe_service_startup"), @items_fcoe))
          ),
          VStretch(),
          # frame containing radio buttons for lldpad service start
          Frame(
            _("Lldpad Service Start"),
            VBox(RadioButtonGroup(Id("lldpad_service_startup"), @items_lldpad))
          ),
          VStretch()
        )
      )
    end

    # Interfaces dialog
    # @return [Yast::Term]
    def InterfacesDialogContent
      MarginBox(
        @mbox_x,
        @mbox_y,
        VBox(
          Table(
            Id(:interfaces),
            Opt(:notify, :immediate, :keepSorting),
            # column headers of a table with network interfaces (keep them short)
            Header(
              _("Device"),
              _("MAC Address"),
              _("Model"),
              _("VLAN"),
              _("FCoE VLAN Interface"),
              # continue column headers
              _("FCoE Enable"),
              _("DCB Required"),
              _("AUTO VLAN"),
              _("DCB capable")
            ),
            []
          ),
          # button labels
          Left(
            HBox(
              PushButton(Id(:retry), _("Retry &Detection")),
              PushButton(Id(:edit), _("Change &Settings")),
              PushButton(Id(:create), _("Create &FCoE Interface")),
              PushButton(Id(:remove), _("&Remove Interface"))
            )
          )
        )
      )
    end

    # Configuration dialog
    # @return [Yast::Term]
    def ConfigurationDialogContent
      MarginBox(
        @mbox_x,
        @mbox_y,
        VBox(
          VSpacing(2.0),
          Frame(
            # frame label - configuration settings of FCoE
            _("Configuration Settings"),
            VBox(
              # combo box label
              Left(
                ComboBox(
                  Id("debug"),
                  _("&Debug"),
                  [Item(Id("yes"), "yes"), Item(Id("no"), "no", true)]
                )
              ),
              # combo box label
              Left(
                ComboBox(
                  Id("syslog"),
                  _("&Use syslog"),
                  [Item(Id("yes"), "yes", true), Item(Id("no"), "no")]
                )
              )
            )
          ),
          VStretch()
        )
      )
    end
  end
end
