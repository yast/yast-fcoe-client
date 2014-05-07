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
        HBox(
          HStretch(),
          Label(
            Id(:heading), Opt(:hstretch),
            "Configuration of Interface ......................."
          ),
          HStretch()
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
                ComboBox(
                  Id(:fcoe),
                  # combo box label: enable FCoE (yes/no)
                  _("&FCoE Enable"),
                  [Item(Id("yes"), "yes"), Item(Id("no"), "no", true)]
                ),
                VSpacing(1),
                ComboBox(
                  Id(:dcb),
                  Opt(:notify),
                  # combo box label: require DCB (yes/no)
                  _("&DCB Required"),
                  [Item(Id("yes"), "yes"), Item(Id("no"), "no", true)]
                ),
                VSpacing(1),
                ComboBox(
                  Id(:auto),
                  # combo box label: AUTO_VLAN setting (yes/no)
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
          VStretch(),
          HBox(
            HStretch(),
            HSpacing(1),
            VBox(
              # frame containing radio buttons for fcoe service start
              Frame( _("FCoE Service Start"),
                VBox(RadioButtonGroup(Id("fcoe_service_startup"), @items_fcoe))
              ),
              VSpacing(2),
              # frame containing radio buttons for lldpad service start
              Frame( _("Lldpad Service Start"),
                VBox(RadioButtonGroup(Id("lldpad_service_startup"), @items_lldpad))
              )
            ),
            HSpacing(1),
            HStretch()
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
            Header(
              # column headers of table of network interfaces (keep them short)
              _("Device"),
              _("MAC Address"),
              _("Model"),
              _("VLAN"),
              _("FCoE VLAN Interface"),
              _("FCoE Enable"),
              _("DCB Required"),
              _("AUTO VLAN"),
              _("DCB capable"),
              _("Driver"),
              _("Flag FCoE"),
              _("Flag iSCSI"),
              _("Storage Only")
            ),
            []
          ),
          Left(
            HBox(
              # button labels
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
          VStretch(),
          HBox(
            HStretch(),
            HSpacing(1),
            VBox(
              Frame(
                # frame label - configuration settings of FCoE
                _("Configuration Settings"),
                VBox(
                  HBox(
                    HSpacing(2),
                    MinWidth( 6, ComboBox(
                      Id("debug"),
                      # combo box label (debug setting yes/no)
                      _("&Debug"),
                      [Item(Id("yes"), "yes"), Item(Id("no"), "no", true)]
                    )),
                    HSpacing(2)
                  ),
                  VSpacing(2.0),
                  HBox(
                    HSpacing(2),
                    MinWidth( 6, ComboBox(
                    Id("syslog"),
                    # combo box label (use syslog yes/no)
                    _("&Use syslog"),
                    [Item(Id("yes"), "yes", true), Item(Id("no"), "no")]
                    )),
                    HSpacing(2)
                  )
                )
              )
            ),
            HSpacing(1),
            HStretch()
            ),
          VStretch()
        )
      )
    end
  end
end
