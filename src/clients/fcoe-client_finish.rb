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

# File:
#  fcoe-client_finish.ycp
#
# Module:
#  Step of base installation finish
#
# Authors:
#  Gabriele Mohr <gs@suse.de>
#
require "yast2/systemd/socket"

module Yast
  class FcoeClientFinishClient < Client
    def main
      Yast.import "UI"

      textdomain "fcoe-client"

      Yast.import "Directory"
      Yast.import "String"
      Yast.import "FcoeClient"
      Yast.import "Service"
      Yast.include self, "installation/misc.rb"

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

      Builtins.y2milestone("starting fcoe-client_finish")
      Builtins.y2debug("func=%1", @func)
      Builtins.y2debug("param=%1", @param)

      if @func == "Info"
        return {
          "steps" => 1,
          # progress step title
          "title" => _("Saving fcoe configuration..."),
          "when"  => [:installation, :update, :autoinst]
        }
      elsif @func == "Write"
        @start_services = false
        @command = ""
        @netcards = FcoeClient.GetNetworkCards

        if @netcards != []
          Builtins.y2milestone("Copying files /etc/fcoe/* to destination")
          # copy fcoe config files to destdir
          WFM.Execute(
            path(".local.bash"),
            Ops.add(
              Ops.add(
                Ops.add(
                  Ops.add(
                    "test -d /etc/fcoe/ && mkdir -p '",
                    String.Quote(Installation.destdir)
                  ),
                  "/etc/fcoe' && cp -a /etc/fcoe/* '"
                ),
                String.Quote(Installation.destdir)
              ),
              "/etc/fcoe/'"
            )
          )
        else
          Builtins.y2milestone("Nothing to do")
        end

        Builtins.foreach(@netcards) do |card|
          command = ""
          file_name = ""
          if Ops.get_string(card, "fcoe_vlan", "") != FcoeClient.NOT_AVAILABLE &&
              Ops.get_string(card, "fcoe_vlan", "") != FcoeClient.NOT_CONFIGURED
            # FCoE VLAN interface is configured -> start services
            @start_services = true

            # copy sysconfig files
            file_name = Builtins.sformat(
              "/etc/sysconfig/network/ifcfg-%1.%2",
              Ops.get_string(card, "dev_name", ""),
              Ops.get_string(card, "vlan_interface", "")
            )
            command = Builtins.sformat(
              "cp -a %1 '%2/etc/sysconfig/network'",
              file_name,
              String.Quote(Installation.destdir)
            )
            Builtins.y2milestone("Executing command: %1", command)
            WFM.Execute(path(".local.bash"), command)

            file_name = Builtins.sformat(
              "/etc/sysconfig/network/ifcfg-%1",
              Ops.get_string(card, "dev_name", "")
            )
            command = Builtins.sformat(
              "cp -a %1 '%2/etc/sysconfig/network'",
              file_name,
              String.Quote(Installation.destdir)
            )
            Builtins.y2milestone("Executing command: %1", command)
            WFM.Execute(path(".local.bash"), command)
          end
        end

        if @start_services
          Builtins.y2milestone("Enabling socket start of fcoe and lldpad")
          # enable socket lldpad first
          lldpad_socket = Yast2::Systemd::Socket.find("lldpad")
          if lldpad_socket
            lldpad_socket.enable
          else
            Builtins.y2error("lldpad.socket not found")
          end
          # and enable the service (needed during boot)
          Service.Enable("lldpad")

          # enable fcoemon socket
          fcoemon_socket = Yast2::Systemd::Socket.find("fcoemon")
          if fcoemon_socket
            fcoemon_socket.enable
          else
            Builtins.y2error("fcoemon.socket not found")
          end
          # and enable the service (needed during boot)
          Service.Enable("fcoe")
        end
      else
        Builtins.y2error("unknown function: %1", @func)
        @ret = nil
      end

      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("fcoe-client_finish finished")
      deep_copy(@ret)
    end
  end
end

Yast::FcoeClientFinishClient.new.main
