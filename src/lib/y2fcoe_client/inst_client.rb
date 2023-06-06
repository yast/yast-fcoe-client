# |***************************************************************************
# |
# | Copyright (c) [2006-2023] SUSE LLC
# | All Rights Reserved.
# |
# | This program is free software; you can redistribute it and/or
# | modify it under the terms of version 2 of the GNU General Public License as
# | published by the Free Software Foundation.
# |
# | This program is distributed in the hope that it will be useful,
# | but WITHOUT ANY WARRANTY; without even the implied warranty of
# | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# | GNU General Public License for more details.
# |
# | You should have received a copy of the GNU General Public License
# | along with this program; if not, contact SUSE LLC
# |
# | To contact Novell about this file by physical or electronic mail,
# | you may find current contact information at www.suse.com
# |
# |***************************************************************************
#
# Original file: clients/inst_fcoe-client.ycp

module Y2FcoeClient
  # Client used to configure FCoE-client during installation
  class InstClient < ::Yast::Client
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
      Yast.import "NetworkService"

      Yast.include self, "fcoe-client/wizards.rb"

      # Initialize FcoeClient
      read

      # main ui function
      @ret = nil
      # run dialog
      @ret = MainSequence()
      Builtins.y2milestone("MainSequence ret=%1", @ret)

      # workflow not aborted
      write if @ret == :next

      # Finish
      Builtins.y2milestone("fcoe-client module finished")
      Builtins.y2milestone("----------------------------------------")

      deep_copy(@ret)

      # EOF
    end

    # Initializes Yast::FcoeClient and perform basic preparations in the int-sys
    def read
      Yast.import "FcoeClient"

      @success = false

      Builtins.y2milestone("fcoe-client module started during installation")

      # create /etc/fcoe
      SCR.Execute(path(".target.bash"), "/usr/bin/mkdir -p /etc/fcoe")

      # FcoeClient::CheckInstalledPackages()  not needed in inst-sys
      # FcoeClient::DetectStartStatus()	 doesn't make sense in inst-sys
      # NetworkService::RunningNetworkPopup() do not check for running network, the
      # interfaces are set up in FcoeClient::GetVlanInterface()

      # start services fcoe and lldpad
      @success = FcoeClient.ServiceStatus
      if !@success
        Builtins.y2error("Starting of services FAILED")
      end

      FcoeClient.ReadNetworkCards

      # read general FCoE settings
      @success = FcoeClient.ReadFcoeConfig
      if !@success
        Builtins.y2error("Reading /etc/fcoe/config FAILED")
      end
    end

    # Writes the changes to the int-sys and to the installer configuration
    def write
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
  end
end
