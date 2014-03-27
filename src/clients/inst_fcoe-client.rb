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

# File:	clients/inst_fcoe-client.ycp
# Package:	Configuration of fcoe-client
# Summary:	Main file
# Authors:	Gabriele Mohr <gs@suse.de>
#
#
# File called in installation workflow for fcoe-client configuration.
module Yast
  class InstFcoeClientClient < Client
    def main
      Yast.import "UI"

      #**
      # <h3>Configuration of fcoe-client</h3>

      textdomain "fcoe-client"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("FCoEClient module started")

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "ModuleLoading"
      Yast.import "PackagesProposal"
      Yast.import "Installation"
      Yast.import "String"
      Yast.import "FcoeClient"
      Yast.import "NetworkService"

      Yast.include self, "fcoe-client/wizards.rb"

      # main ui function
      @ret = nil
      @success = false

      Builtins.y2milestone("fcoe-client module started during installation")

      # create /etc/fcoe
      SCR.Execute(path(".target.bash"), "mkdir -p /etc/fcoe")

      # FcoeClient::CheckInstalledPackages()  not needed in inst-sys
      # FcoeClient::DetectStartStatus()	 doesn't make sense in inst-sys
      # NetworkService::RunningNetworkPopup() do not check for running network, the
      # interfaces are set up in FcoeClient::GetVlanInterface()

      # reset global values
      FcoeClient.ResetNetworkCards

      # start services fcoe and lldpad
      @success = FcoeClient.ServiceStatus
      if !@success
        Builtins.y2error("Starting of services FAILED")
      end

      # detect netcards
      netcards = FcoeClient.DetectNetworkCards(FcoeClient.ProbeNetcards)
      if netcards.empty?
        Builtins.y2error("Detecting netcards FAILED")
      else
        FcoeClient.SetNetworkCards(netcards)
      end

      # read general FCoE settings
      @success = FcoeClient.ReadFcoeConfig
      if !@success
        Builtins.y2error("Reading /etc/fcoe/config FAILED")
      end

      # run dialog
      @ret = MainSequence()
      Builtins.y2milestone("MainSequence ret=%1", @ret)

      # workflow not aborted
      if @ret == :next
        # add packages fcoe-utils (requires lldpd) and yast2-fcoe-client
        # to the pool that is used by software proposal
        Builtins.y2milestone(
          "Adding packages %1 and yast2-fcoe-client to pool",
           FcoeClientClass::FCOE_PKG_NAME
        )
        PackagesProposal.AddResolvables(
          "fcoe",
          :package,
          [FcoeClientClass::FCOE_PKG_NAME, "yast2-fcoe-client"]
        )
        # write changes to config files
        Builtins.y2milestone("Writing FCoE config files")
        FcoeClient.WriteFcoeConfig
        FcoeClient.WriteCfgFiles
        # restart fcoemon
        Builtins.y2milestone("Restarting FCoE")
        FcoeClient.RestartServiceFcoe
        Builtins.y2milestone("Writing sysconfig files")
        FcoeClient.WriteSysconfigFiles

        # start on boot of services 'fcoe' and 'lldpad'
        # is enabled in fcoe-client_finish.ycp

        # reset modified flag
        FcoeClient.SetModified(false)
      end

      # Finish
      Builtins.y2milestone("fcoe-client module finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::InstFcoeClientClient.new.main
