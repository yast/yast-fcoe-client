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

# File:	modules/FcoeClient.ycp
# Package:	Configuration of fcoe-client
# Summary:	FcoeClient settings, input and output functions
# Authors:	Gabriele Mohr <gs@suse.de>
#
#
# Representation of the configuration of fcoe-client.
# Input and output routines.
require "yast"

module Yast
  class FcoeClientClass < Module

    include Yast::Logger

    FCOE_PKG_NAME = "fcoe-utils"

    def main
      Yast.import "UI"
      textdomain "fcoe-client"

      Yast.import "Progress"
      Yast.import "Report"
      Yast.import "Summary"
      Yast.import "Message"
      Yast.import "Stage"
      Yast.import "Mode"
      Yast.import "Package"
      Yast.import "Popup"
      Yast.import "Service"
      Yast.import "NetworkService"
      Yast.import "String"
      Yast.import "FileUtils"
      Yast.import "SystemdSocket"

      # Data

      # data modified?
      @modified = false

      # proposal valid?
      @proposal_valid = false

      # Number of retries for fipvlan (default is 20).
      # The number is reduced to 10 to make detection faster. 10 seconds (10 retries *
      # 1000 ms) should be enough time for most interfaces. If not there is the
      # possibility to retry interface dedection using 'Retry'.
      @number_of_retries = "10"

      # Write only, used during autoinstallation.
      # Don't run services and SuSEconfig, it's all done at one place.
      @write_only = false


      @test_mode = false

      # Abort function
      # return boolean return true if abort
      @AbortFunction = fun_ref(method(:Modified), "boolean ()")

      #   from IscsiClientLib.ycp (line 53) - reading output
      #
      #   string from_bios = ((map<string, any>)SCR::Execute(.target.bash_output, "iscsiadm -m fw"))["stdout"]:"";
      #   foreach(string row, splitstring(from_bios, "\n"), {
      #   list<string> key_val=splitstring(row, "=");
      # //   if (size(key_val[0]:"")>0) ibft[key_val[0]:""] = key_val[1]:"";
      #    string kv = String::CutBlanks(key_val[0]:"");
      #    if (size(kv) > 0) ibft[kv] = String::CutBlanks(key_val[1]:"");
      #    });


      # Define all the variables necessary to hold

      @current_card = 0 # currently selected card, means row in list of cards

      @NOT_CONFIGURED = "not configured"
      @NOT_AVAILABLE = "not available"

      @lldpad_started = false # service lldpad was started
      @fcoe_started = false # service fcoe was started


      # Settings: Define all variables needed for configuration of fcoe-client

      # map containing information about values in /etc/fcoe/config
      @fcoe_general_config = { "DEBUG" => "no", "USE_SYSLOG" => "yes" }

      # list containing information about commands to revert changes
      @revert_list = []

      # map containing information about start of services at boot
      @service_start = { "fcoe" => true, "lldpad" => true }

      # list of maps containing information about networks cards and VLAN, FCoE and DCB status
      @network_interfaces = []

      # systemd sockets
      @fcoemon_socket = nil
      @lldpad_socket = nil

      FcoeClient()
    end

    # Constructor
    def FcoeClient
      if Builtins.getenv("FCOE_CLIENT_TEST_MODE") == "1"
        Builtins.y2milestone("Running in test mode")
        @test_mode = true
      else
        @test_mode = false
      end

      nil
    end

    def fcoemonSocketActive?
      if @fcoemon_socket
        @fcoemon_socket.active?
      else
        log.error("fcoemon.socket not found")
        false
      end
    end

    def fcoemonSocketStart
      if @fcoemon_socket
        @fcoemon_socket.start
      else
        log.error("fcoemon.socket not found")
        false
      end
    end

    def fcoemonSocketStop
      if @fcoemon_socket
        @fcoemon_socket.stop
     else
        log.error("fcoemon.socket not found")
        false
      end
    end

    def fcoemonSocketEnabled?
      if @fcoemon_socket
        @fcoemon_socket.enabled?
      else
        log.error("fcoemon.socket not found")
        false
      end
    end

    def fcoemonSocketDisabled?
      if @fcoemon_socket
        @fcoemon_socket.disabled?
      else
        log.error("fcoemon.socket not found")
        false
      end
    end

    def fcoemonSocketEnable
      if @fcoemon_socket
        @fcoemon_socket.enable
      else
        log.error("fcoemon.socket not found")
        false
      end
    end

    def fcoemonSocketDisable
      if @fcoemon_socket
        @fcoemon_socket.disable
      else
        log.error("fcoemon.socket not found")
        false
      end
    end

    def lldpadSocketActive?
      if @lldpad_socket
        @lldpad_socket.active?
      else
        log.error("lldpad.socket not found")
        false
      end
    end

    def lldpadSocketStart
      if @lldpad_socket
        @lldpad_socket.start
      else
        log.error("lldpad.socket not found")
        false
      end
    end

    def lldpadSocketStop
      if @lldpad_socket
        @lldpad_socket.stop
     else
        log.error("lldpad.socket not found")
        false
      end
    end

    def lldpadSocketEnabled?
      if @lldpad_socket
        @lldpad_socket.enabled?
      else
        log.error("lldpad.socket not found")
        false
      end
    end

    def lldpadSocketDisabled?
      if @lldpad_socket
        @lldpad_socket.disabled?
      else
        log.error("lldpad.socket not found")
        false
      end
    end

    def lldpadSocketEnable
      if @lldpad_socket
        @lldpad_socket.enable
      else
        log.error("lldpad.socket not found")
        false
      end
    end

    def lldpadSocketDisable
      if @lldpad_socket
        @lldpad_socket.disable
      else
        log.error("lldpad.socket not found")
        false
      end
    end

    # Abort function
    # @return [Boolean] return true if abort
    def Abort
      return @AbortFunction.call == true if @AbortFunction != nil
      false
    end

    # Data was modified?
    # @return true if modified
    def Modified
      Builtins.y2debug("get modified = %1", @modified)
      @modified
    end

    # Mark as modified, for Autoyast.
    def SetModified(value)
      Builtins.y2debug("set modified to %1", value)
      @modified = value

      nil
    end

    def ProposalValid
      @proposal_valid
    end

    def SetProposalValid(value)
      @proposal_valid = value

      nil
    end

    # @return true if module is marked as "write only" (don't start services etc...)
    def WriteOnly
      @write_only
    end

    # @return true if test mode is set (environment variable FCOE_CLIENT_TEST_MODE)
    def TestMode
      @test_mode
    end

    # Set write_only flag (for autoinstallation).
    def SetWriteOnly(value)
      @write_only = value

      nil
    end

    def SetAbortFunction(function)
      function = deep_copy(function)
      @AbortFunction = deep_copy(function)

      nil
    end

    # Checks whether an Abort button has been pressed.
    # If so, calls function to confirm the abort call.
    #
    # @return [Boolean] true if abort confirmed
    def PollAbort
      # Do not check UI when running in CommandLine mode
      return false if Mode.commandline

      return Abort() if UI.PollInput == :abort

      false
    end

    # Set value in fcoe_general_config
    def SetFcoeConfigValue(param, value)
      Ops.set(@fcoe_general_config, param, value)

      nil
    end

    # Returns the map containing general FCoE configuration
    def GetFcoeConfig
      deep_copy(@fcoe_general_config)
    end

    # Add a command to the list of revert commands
    def AddRevertCommand(command)
      @revert_list = Builtins.add(@revert_list, command)
      Builtins.y2milestone("Adding revert command: %1", command)

      nil
    end

    # Get the list of revert commands
    def GetRevertCommands
      deep_copy(@revert_list)
    end

    # Reset list of revert commands
    def ResetRevertCommands
      @revert_list = []

      nil
    end

    # Returns the map containing all detected interfaces (possibly including
    # several entries for a network interface if several VLAN interfaces are
    # detected)
    def GetNetworkCards
      deep_copy(@network_interfaces)
    end

    # Get currently selected network card
    def GetCurrentNetworkCard
      Ops.get(@network_interfaces, @current_card, {})
    end

    # Set network card values for given row
    def SetNetworkCardsValue(row, card)
      card = deep_copy(card)
      Ops.set(@network_interfaces, row, card)

      nil
    end

    def SetNetworkCards(netcards)
      netcards = deep_copy(netcards)
      @network_interfaces = deep_copy(netcards)

      nil
    end

    # Reset list of detected cards
    def ResetNetworkCards
      @network_interfaces = []

      nil
    end

    #
    # Check whether fcoe-utils is installed and do installation if user agrees
    # (dependencies: 'open-lldp', 'libhbalinux2' and 'libHBAAPI2')
    #
    def CheckInstalledPackages
      ret = false

      # don't check interactively for packages (bnc#367300) -> comment from iscsi-client
      # skip it during initial and second stage or when create AY profile
      return true if Stage.cont || Stage.initial || Mode.config
      Builtins.y2milestone("Check whether package %1 is installed",
                           FcoeClientClass::FCOE_PKG_NAME)

      if !Package.InstallMsg(
          FcoeClientClass::FCOE_PKG_NAME,
          _(
            "<p>To continue the FCoE configuration, the <b>%1</b> package must be installed.</p>"
          ) +
            _("<p>Install it now?</p>")
        )
        Popup.Error(Message.CannotContinueWithoutPackagesInstalled)
      else
        ret = true
      end
      ret
    end

    #
    # Check whether/which VLAN interfaces are configured for FCoE on the switch
    # (by calling command 'fipvlan').
    # @example
    #   $ fipvlan eth0 eth1 eth2 eth3
    #   Fibre Channel Forwarders Discovered\n
    #   interface      | VLAN | FCF MAC\n
    #   ------------------------------------------\n
    #   eth0           | 200  | 00:0d:ec:a2:ef:00\n
    #   eth3           | 200  | 00:0d:ec:a2:ef:01\n
    #
    # @param  [List] net_devices	detected network cards
    # @return [List] information about FcoE VLAN interfaces
    #
    def GetFcoeInfo(net_devices)
      # Add option -u (or --link_up): don't shut down interfaces
      # to be able to detect DCB state afterwards (see bnc #737683)
      vlan_cmd = "LANG=POSIX fipvlan -u"

      if !Mode.autoinst
        vlan_cmd = Ops.add(Ops.add(vlan_cmd, " -l "), @number_of_retries)
      end # reduce number of retries

      Builtins.foreach(
        Convert.convert(net_devices, :from => "list", :to => "list <string>")
      ) { |dev| vlan_cmd = Ops.add(Ops.add(vlan_cmd, " "), dev) }

      # call fipvlan command for all interfaces (saves time because is executed in parallel)
      Builtins.y2milestone("Executing command: %1", vlan_cmd)
      output = Convert.to_map(
        SCR.Execute(path(".target.bash_output"), vlan_cmd)
      )
      Builtins.y2milestone("Output: %1", output)

      lines = []
      if !TestMode()
        lines = Builtins.splitstring(output["stdout"] || "", "\n")
      else
        # test data
        lines = Builtins.splitstring(
          "Fibre Channel Forwarders\n" +
            "< Discovered\n" +
            "interface       | VLAN | FCF MAC\n" +
            "< \n" +
            "------------------------------------------\n" +
            "eth1           | 500   |54:7f:ee:09:55:9f\n" +
            "eth15          | 2012  |54:7f:ee:04:55:9f\n" +
            "eth15          | 0     |54:7f:ee:04:55:9f\n" +
            "eth15          | 200   |54:7f:ee:04:55:8f\n" +
            "eth1           | 301   |54:7f:ee:06:55:9f\n" +
            "eth1           | 400   |54:7f:ee:07:55:9f\n" +
            "\n",
          "\n"
        )
      end
    end

    #
    # Provide information about FCoE capable VLAN interfaces for each network card
    #
    # @param [List] 	net_devices	network cards
    # @param [List]     fcoe_info       information about FCoE VLAN interfaces
    # @return [Hash]                    assorted FCoE info per network card
    #
    # @example
    #   Param net_devices:
    #   ["eth0", "eth1", "eth2"]
    #   Param fcoe_info:
    #   ["eth0     | 200  | 00:0d:ec:a2:ef:00",
    #    "eth0     | 300  | 00:0d:ec:a2:ef:01",
    #    "eth2     | 200  | 00:0d:ec:a2:ef:02" ]
    #   Return:
    #   { "eth0" => [{ "vlan" => "200", "fcf" => "00:0d:ec:a2:ef:00" },
    #                { "vlan" => "300", "fcf" => "00:0d:ec:a2:ef:01" }],
    #     "eth2" => [{ "vlan" => "200", "fcf" => "00:0d:ec:a2:ef:02" }]
    #   }
    #
    def GetVlanInterfaces(net_devices, fcoe_info)
      net_devices = deep_copy(net_devices)
      fcoe_info = deep_copy(fcoe_info)
      vlan_info = {}

      Builtins.foreach(
        Convert.convert(net_devices, :from => "list", :to => "list <string>")
      ) { |dev| Builtins.foreach(fcoe_info) do |line|
        # Check whether there is a line for the given interface, e.g.
        # eth3            | 200  | 00:0d:ec:a2:ef:00\n
        # Get VLAN channel from second column and FCF MAC from third.
        line = Builtins.deletechars(line, " \t")
        columns = Builtins.splitstring(line, "|")
        if Ops.get(columns, 0, "") == dev
          # get VLAN and FCF MAC and add it to vlan_info
          vlan_interface = { "vlan" => Ops.get(columns, 1, ""), "fcf" => Ops.get(columns, 2, "") }

          Builtins.y2milestone(
            "Interface: %1 VLAN: %2 FCF: %3",
            dev,
            Ops.get(columns, 1, ""),
            Ops.get(columns, 2, "")
          )

          if Ops.get(vlan_info, dev, []) == []
            vlan_info = Builtins.add(vlan_info, dev, [vlan_interface])
          else
            vlans = Convert.convert(
              Ops.get(vlan_info, dev, []),
              :from => "list",
              :to   => "list <map>"
            )

            # add vlan_interface only if no entry with identical FCF MAC exists
            if Builtins.find(vlans) do |vlan|
                (vlan["fcf"] || "") == (vlan_interface["fcf"] || "")
              end == nil
              vlans = Builtins.add(vlans, vlan_interface)
            elsif (vlan_interface["vlan"] || "") == "0" # for VLAN = 0 replace existing entry
              # VLAN = 0 'wins' (see bnc #813621, comment #4)
              vlans = Builtins.maplist(vlans) do |vlan|
                if (vlan["fcf"] || "") == (vlan_interface["fcf"] || "")
                  Builtins.y2milestone("VLAN = 0 is taken")
                  Ops.set(vlan, "vlan", "0")
                end
                deep_copy(vlan)
              end
            end
            Ops.set(vlan_info, dev, vlans)
          end
        end
      end }
      Builtins.y2milestone("VLAN info: %1", vlan_info)
      deep_copy(vlan_info)
    end

    #
    # Check whether the VLAN device is created (check entries in /proc/net/vlan/config)
    #
    # @param  [String] interface network interface card, e.g. eth3
    # @param  [String] vlan_interface	 Vlan Interface configured for FCoE (on switch)
    # @return [String] Vlan device name, e.g. eth3.200
    #
    # # cat /proc/net/vlan/config
    #VLAN Dev name    | VLAN ID
    #Name-Type: VLAN_NAME_TYPE_RAW_PLUS_VID_NO_PAD
    #eth3.200  | 200  | eth3

    def GetFcoeVlanInterface(interface, vlan_interface)
      vlan_device_name = ""

      if TestMode()
        vlan_device_name = "#{interface}.#{vlan_interface}"
        Builtins.y2milestone("Test mode - Returning: %1", vlan_device_name)
        return vlan_device_name
      end

      command = Builtins.sformat(
        "sed -n 's/\\([^ ]*\\) *.*%1*.*%2/\\1/p' /proc/net/vlan/config",
        vlan_interface,
        interface
      )
      Builtins.y2milestone("Executing command: %1", command)

      output = Convert.to_map(SCR.Execute(path(".target.bash_output"), command))
      Builtins.y2milestone("Output: %1", output)
      # read stdout (remove \n and white spaces)
      vlan_device_name = Builtins.deletechars(
        Ops.get_string(output, "stdout", ""),
        " \n\t"
      )

      if vlan_device_name != ""
        Builtins.y2milestone("Returning: %1", vlan_device_name)
      else
        Builtins.y2error("FCoE VLAN not found in /proc/net/vlan/config")
      end
      vlan_device_name
    end

    #
    # Create /etc/fcoe/cfg-<if> or /etc/fcoe/cfg-<if>.<vlan>
    # (depending on AUTO_VLAN setting)
    #
    def CreateFcoeConfig(vlan_device_name, netcard)
      netcard = deep_copy(netcard)
      file_name = ""
      device_name = ""
      file_exists = false
      status_map = {}

      # if AUTO_VLAN is set to "yes" or VLAN is set to "0" (means no VLAN created but FCoE started on device)
      if Ops.get_string(netcard, "auto_vlan", "no") == "yes" ||
          Ops.get_string(netcard, "vlan_interface", "") == "0"
        device_name = Ops.get_string(netcard, "dev_name", "")
        # set file name to cfg-<interface>, e.g. /etc/fcoe/cfg-eth3
        file_name = Builtins.sformat("/etc/fcoe/cfg-%1", device_name)
      else
        device_name = vlan_device_name
        # set file name to cfg-<vlan_device_name>, e.g. /etc/fcoe/cfg-eth3.200
        file_name = Builtins.sformat("/etc/fcoe/cfg-%1", vlan_device_name)
      end

      # read default values
      content = Convert.to_string(
        SCR.Read(path(".target.string"), "/etc/fcoe/cfg-ethx")
      )

      # and prepare content
      if content != "" && content != nil
        lines = Builtins.splitstring(content, "\n")
        lines = Builtins.maplist(lines) do |line|
          if !String.StartsWith(line, "#")
            line = Builtins.deletechars(line, " \t")
          end
          if String.StartsWith(line, "AUTO_VLAN")
            next Builtins.sformat(
              "AUTO_VLAN=\"%1\"",
              Ops.get_string(netcard, "auto_vlan", "no")
            )
          elsif String.StartsWith(line, "DCB_REQUIRED")
            next Builtins.sformat(
              "DCB_REQUIRED=\"%1\"",
              Ops.get_string(netcard, "dcb_required", "no")
            )
          elsif String.StartsWith(line, "FCOE_ENABLE")
            next Builtins.sformat(
              "FCOE_ENABLE=\"%1\"",
              Ops.get_string(netcard, "fcoe_enable", "yes")
            )
          else
            next line
          end
        end
        content = Builtins.mergestring(lines, "\n")
        Builtins.y2milestone("Writing content: %1 to %2", content, file_name)

        file_exists = SCR.Write(path(".target.string"), file_name, content)

        if file_exists
          AddRevertCommand(Builtins.sformat("rm %1", file_name))
          # fill status map
          status_map = {
            "FCOE_ENABLE"  => netcard["fcoe_enable"] || "yes",
            "DCB_REQUIRED" => netcard["dcb_required"] || "no",
            "AUTO_VLAN"    => netcard["auto_vlan"] || "no",
            "cfg_device"   => device_name
          }
        else
          Builtins.y2error("Cannot create %1", file_name)
        end
      else
        Builtins.y2error("Cannot read /etc/fcoe/cfg-ethx")
      end

      deep_copy(status_map)
    end

    #
    # Get status of FCoE config from /etc/fcoe/cfg-<if>.<vlan> or /etc/fcoe/cfg-<if>
    #
    def GetFcoeStatus(vlan_device_name, device_name)
      status_map = {}
      content = ""
      file_name = ""
      device = vlan_device_name

      if vlan_device_name == "" || device_name == ""
        Builtins.y2error("Interface not valid")
        return {}
      end

      Builtins.y2milestone("Checking configuration for %1", vlan_device_name)

      file_name = Builtins.sformat("/etc/fcoe/cfg-%1", vlan_device_name)

      if !FileUtils.Exists(file_name)
        file_name = Builtins.sformat("/etc/fcoe/cfg-%1", device_name)

        if !FileUtils.Exists(file_name)
          # no config file found - return empty status map
          return deep_copy(status_map)
        else
          # check whether there is a sysconfig file for given vlan_device_name
          file_name = "/etc/sysconfig/network/ifcfg-#{vlan_device_name}"
          # configuration in /etc/fcoe/cfg-<device_name> doesn't belong to vlan_device_name
          if !FileUtils.Exists(file_name)
            return deep_copy(status_map)
          end
        end
        device = device_name
      end
      # for debugging purpose, read only needed values later
      values = SCR.Dir(Ops.add(path(".fcoe.cfg-ethx.value"), device))
      Builtins.y2milestone("Available values in %1: %2", file_name, values)

      Builtins.foreach(["FCOE_ENABLE", "DCB_REQUIRED", "AUTO_VLAN"]) do |var|
        value = Convert.to_string(
          SCR.Read(Ops.add(Ops.add(path(".fcoe.cfg-ethx.value"), device), var))
        )
        if value == nil
          Builtins.y2warning("Cannot read %1", var)
          next
        end
        status_map = Builtins.add(status_map, var, value)
      end

      status_map = Builtins.add(status_map, "cfg_device", device)

      Builtins.y2milestone("Returning: %1", status_map)

      deep_copy(status_map)
    end

    #
    # Check whether the network interface (netcard, e.g. eth0 is DCB capable)
    #
    def DCBCapable(netcard)
      ret = "no"

      # 'lldpad' must be started to be able to use 'dcbtool'
      # -> is started in ServiceStatus() ( called in Read() before DetectNetworkCards() )
      command = Builtins.sformat("LANG=POSIX dcbtool gc %1 dcb", netcard)
      Builtins.y2milestone("Executing command: %1", command)

      output = Convert.to_map(SCR.Execute(path(".target.bash_output"), command))
      Builtins.y2milestone("Output:  %1", output)
      status = ""

      if Ops.get_integer(output, "exit", 255) == 0
        lines = Builtins.splitstring(Ops.get_string(output, "stdout", ""), "\n")
        Builtins.foreach(lines) do |line|
          if String.StartsWith(line, "Status")
            # Status:         Failed		interface not DCB capable
            # Status:         Successful
            line = Builtins.deletechars(line, " \t:")
            status = Builtins.substring(line, 6)
            Builtins.y2milestone("Status: %1", status)
          end
        end
        ret = "yes" if status == "Successful"
      else
        Builtins.y2error(
          "Exit code: %1 Error: %2",
          Ops.get_integer(output, "exit", 255),
          Ops.get_string(output, "stderr", "")
        )
      end

      ret
    end

    #
    # Set start status of 'fcoemon' and 'lldpad' sockets
    #
    # 'Service' tab is only shown in installed system where
    # sockets (and systemd) are available.
    #
    def AdjustStartStatus
      fcoe_start = Ops.get(@service_start, "fcoe", false)
      lldpad_start = Ops.get(@service_start, "lldpad", false)
      Builtins.y2milestone(
        "Setting start of fcoe to %1",
        fcoe_start
      )
      Builtins.y2milestone(
        "Setting start of lldpad to %1",
        lldpad_start
      )

      if fcoe_start && lldpad_start
        lldpadSocketEnable             # enable 'lldpad' first
        fcoemonSocketEnable
      elsif !fcoe_start && lldpad_start
        fcoemonSocketDisable
        lldpadSocketEnable
      elsif !fcoe_start && !lldpad_start
        fcoemonSocketDisable            # disable 'fcoe' first
        lldpadSocketDisable
      end 
      # fcoe_start && !lldpad_start isn't possible -> see complex.ycp StoreServicesDialog

      nil
    end

    #
    # Set status of services
    #
    def SetStartStatus(service, status)
      Builtins.y2milestone("Starting service %1 on boot: %2", service, status)
      Ops.set(@service_start, service, status)

      nil
    end

    #
    # Get status of services
    #
    def DetectStartStatus
      status = false

      status = fcoemonSocketEnabled?
      Builtins.y2milestone("Start status of fcoe: %1", status)
      @service_start = Builtins.add(@service_start, "fcoe", status)

      status = lldpadSocketEnabled?
      Builtins.y2milestone("Start status of lldpad: %1", status)
      @service_start = Builtins.add(@service_start, "lldpad", status)

      nil
    end

    def GetStartStatus
      deep_copy(@service_start)
    end

    #
    # Check status of services 'fcoe' and 'lldpad' and start them if required
    #
    def ServiceStatus
      success = true

      # Loading of modules in Stage::initial() is not required 
      # (like done in IsciClientLib)
      # SLES11 SP3: /etc/init.d/boot.fcoe, line 86 
      #             (modprobe $SUPPORTED_DRIVERS > /dev/null 2>&1)
      #             SUPPORTED_DRIVERS from /etc/fcoe/config
      # SLES12:     Service.Start in inst-sys runs commands from 
      #             /usr/lib/systemd/system/fcoe.service
      #             (including modprobe)
      ret = true

      # start services during installation
      if Stage.initial
        # start service lldpad first
        @lldpad_started = Service.Start("lldpad")
        if @lldpad_started
          log.info("Service lldpad started")
        else
          log.error("Cannot start service lldpad")
          Report.Error(_("Cannot start service 'lldpad'"))
          ret = false
        end

        @fcoe_started = Service.Start("fcoe")
        if @fcoe_started
          log.info("Service fcoe started")
        else
          log.error("Cannot start service fcoe")
          Report.Error(_("Cannot start service 'fcoe'"))
          ret = false
        end

        return ret
      end

      # start sockets in installed system
      @fcoemon_socket = SystemdSocket.find!("fcoemon")
      @lldpad_socket = SystemdSocket.find!("lldpad")

      # first start lldpad
      if !lldpadSocketActive?
        success = lldpadSocketStart
        if success
          log.info("lldpad.socket started")
          @lldpad_started = true
        else
          log.error("Cannot start lldpad.socket")
          Report.Error(_("Cannot start lldpad systemd socket"))
          ret = false
        end
      else
        log.info("lldpad.socket is already active")
      end

      if !fcoemonSocketActive?
        success = fcoemonSocketStart
        if success
          log.info("fcoemon.socket started")
          @fcoe_started = true
        else
          log.error( "Cannot start fcoemon.socket")
          Report.Error(_("Cannot start fcoemon systemd socket."))
          ret = false
        end
      else
        log.info("fcoemon.socket is already active")
      end

      ret
    end

    #
    # Check whether there are configured FCoE VLANs for the given network interface
    # Return list of configured VLANs
    #
    def IsConfigured(device_name)
      configured_vlans = []
      interfaces = GetNetworkCards()

      Builtins.foreach(interfaces) do |interface|
        if device_name == Ops.get_string(interface, "dev_name", "") &&
            Ops.get_string(interface, "fcoe_vlan", "") != @NOT_CONFIGURED &&
            Ops.get_string(interface, "fcoe_vlan", "") != @NOT_AVAILABLE
          configured_vlans = Builtins.add(
            configured_vlans,
            Ops.get_string(interface, "vlan_interface", "")
          )
        end
      end
      deep_copy(configured_vlans)
    end

    #
    # Detect network interface cards (hardware probe)
    #
    def ProbeNetcards
      if !TestMode()
        netcards = Convert.convert(
          SCR.Read(path(".probe.netcard")),
          :from => "any",
          :to   => "list <map>"
        )
      else  # test data
        netcards = [
          {
            "bus"       => "PCI",
            "bus_hwcfg" => "pci",
            "class_id"  => 2,
            "dev_name"  => "eth1",
            "dev_names" => ["eth1"],
            "device"    => "TEST Ethernet Controller",
            "model"     => "Intel PRO/1000 MT Desktop Adapter",
            "resource"  => { "hwaddr" => [{ "addr" => "08:00:27:11:64:e4" }] }
          },
          {
            "bus"       => "PCI",
            "bus_hwcfg" => "pci",
            "class_id"  => 2,
            "dev_name"  => "eth15",
            "dev_names" => ["eth15"],
            "device"    => "TEST Gigabit Ethernet Controller",
            "model"     => "Intel PRO/1000 MT Desktop Adapter",
            "resource"  => { "hwaddr" => [{ "addr" => "08:23:27:11:64:78" }] }
          },
          {
            "bus"       => "PCI",
            "bus_hwcfg" => "pci",
            "class_id"  => 2,
            "dev_name"  => "eth2",
            "dev_names" => ["eth2"],
            "model"     => "Intel PRO/1000 MT Desktop Adapter",
            "resource"  => { "hwaddr" => [{ "addr" => "08:23:27:99:64:78" }] }
          }
        ]
      end
      Builtins.y2milestone("Detected netcards: %1", netcards)

      netcards
    end

    # list <map> network_interfaces
    #
    # dev_name  mac_addr  device     vlan_interface  fcoe_vlan  fcoe_enable dcb_required auto_vlan dcb_capable cfg_device
    # eth3      08:00:... Gigabit... 200             eth3.200   yes/no      yes/no       yes/no    yes/no      eth3.200
    #
    # Get the network cards and check Fcoe status
    #
    def DetectNetworkCards(netcards)
      return [] if netcards == nil

      net_devices = []

      netcards.each do |card|
        net_devices = Builtins.add(
          net_devices,
          card["dev_name"] || ""
        )
      end

      # The 'fipvlan' command which is called in GetVlanInterfaces configures the interfaces itself,
      # therefore it's not needed any longer to call 'ifconfig <if> up' here.
      vlan_info = GetVlanInterfaces(net_devices, GetFcoeInfo(net_devices) )
      network_interfaces = []

      netcards.each do |card|
        device = card["dev_name"] || ""
        dcb_capable = DCBCapable(device) # DCB capable

        if Ops.get(vlan_info, device, []).empty?
          # Interface down or FCoE not enabled on the switch - we can't do anything here.
          fcoe_vlan_interface = @NOT_AVAILABLE

          # add infos about the card
          info_map = {
            "dcb_capable"=> dcb_capable,
            "dev_name"   => device, # network card, e.g. eth3
            "mac_addr"   => Ops.get_string(card, ["resource", "hwaddr", 0, "addr"], ""), # MAC address
            "device"     => card["device"] || card["model"] || "",
            "fcoe_vlan"  => fcoe_vlan_interface
          }

          network_interfaces = network_interfaces << info_map
        else
          # add infos about card and VLAN interfaces
          vlans = Ops.get(vlan_info, device, [])

          vlans.each do |vlan|
            info_map = {}
            status_map = {}
            dcb_default = ""
            vlan_if = vlan["vlan"] || ""

            if vlan_if == "0"
              # VLAN interface "0" means start FCoE on network interface itself (there isn't an entry in
              # /proc/net/vlan/config, check config files instead)
              fcoe_vlan_interface = FcoeOnInterface?(device, vlans)?device:""
            else
              # get FCoE VLAN interface from /proc/net/vlan/config
              fcoe_vlan_interface = GetFcoeVlanInterface(device, vlan_if)
            end

            if !fcoe_vlan_interface.empty?
              status_map = GetFcoeStatus(fcoe_vlan_interface, device)
              if status_map == {}
                # warning if no valid configuration found
                Builtins.y2warning(
                                   "Cannot read config file for %1 in /etc/fcoe",
                                   fcoe_vlan_interface
                                   )
                Report.Warning(
                  Builtins.sformat(
                    _(
                        "Cannot read config file for %1.\n" +
                          "You may edit the settings and recreate the FCoE\n" +
                          "VLAN interface to get a valid configuration."
                      ),
                      fcoe_vlan_interface
                    )
                  )
                # set interface to NOT_CONFIGURED
                fcoe_vlan_interface = @NOT_CONFIGURED
              end # if status_map == {}
            else
              # FCoE VLAN interface not yet configured (status_map remains empty)
              fcoe_vlan_interface = @NOT_CONFIGURED
            end # if !fcoe_vlan_interface.empty?

            # exception for Broadcom cards: DCB_REQUIRED should be set to "no" (bnc #728658)
            if card["driver"] != "bnx2x" && dcb_capable == "yes"
              dcb_default = "yes"
            else
              dcb_default = "no"
            end

            info_map = {
              "dev_name"       => device, # network card, e.g. eth3
              "mac_addr"       => Ops.get_string(card, ["resource", "hwaddr", 0, "addr"], ""), # MAC address
              "device"         => card["device"] || card["model"] || "",
              "fcoe_vlan"      => fcoe_vlan_interface, # FCoE VLAN interface, e.g. eth3.200
              "fcoe_enable"    => status_map["FCOE_ENABLE"] || "yes",  # default for FCoE enable is yes
              "dcb_required"   => status_map["DCB_REQUIRED"] || dcb_default,
              "auto_vlan"      => status_map["AUTO_VLAN"] || "yes", # default is AUTO_VLAN="yes", see bnc #724563
              "dcb_capable"    => dcb_capable, # DCB capable
              "vlan_interface" => vlan["vlan"] || "", # VLAN interface, e.g. 200
              "cfg_device"     => status_map["cfg_device"] || "" # part of cfg-file name, e.g. eth3.200
            }

            network_interfaces = network_interfaces << info_map
          end # do |vlan|
        end # else
      end # do |card|

      # sort the list of interfaces (eth0, eth1, eth2...)
      network_interfaces = Builtins.sort(network_interfaces) do |a, b|
        Ops.less_than(a["dev_name"] || "", b["dev_name"] || "")
      end

      Builtins.y2milestone("Returning: %1", network_interfaces)
      network_interfaces
    end

    #
    # Check configuration for VLAN ID = 0
    #
    def FcoeOnInterface?(device, vlans)
      return false unless FileUtils.Exists("/etc/fcoe/cfg-#{device}")
      ret = true
        vlans.each do |vlan_cfg|
        # no ifcfg-<if>.<vlan> written for vlan = 0 (see WriteSysconfigFiles() )
        if FileUtils.Exists( "/etc/sysconfig/network/ifcfg-#{device}.#{vlan_cfg["vlan"] || ""}" )
          # sysconfig file for an VLAN interface found, i.e. FCoE isn't configured on interface itself
          ret = false
        end
      end
      ret
    end

    #
    # Read /etc/fcoe/config
    #
    def ReadFcoeConfig
      options = SCR.Dir(path(".fcoe.config"))
      Builtins.y2milestone("List of options in /etc/fcoe/config: %1", options)

      return false if options == [] || options == nil

      debug_val = Convert.to_string(
        SCR.Read(Builtins.add(path(".fcoe.config"), "DEBUG"))
      )
      @fcoe_general_config = Builtins.add(
        @fcoe_general_config,
        "DEBUG",
        debug_val
      )

      syslog_val = Convert.to_string(
        SCR.Read(Builtins.add(path(".fcoe.config"), "USE_SYSLOG"))
      )
      @fcoe_general_config = Builtins.add(
        @fcoe_general_config,
        "USE_SYSLOG",
        syslog_val
      )

      Builtins.y2milestone(
        "/etc/fcoe/config read: DEBUG: %1, USE_SYSLOG: %2",
        debug_val,
        syslog_val
      )

      true
    end

    #
    # Write /etc/fcoe/config using fcoe_config.scr
    #
    def WriteFcoeConfig
      success = SCR.Write(
        Builtins.add(path(".fcoe.config"), "DEBUG"),
        Ops.get(GetFcoeConfig(), "DEBUG", "")
      )
      return false if !success

      success = SCR.Write(
        Builtins.add(path(".fcoe.config"), "USE_SYSLOG"),
        Ops.get(GetFcoeConfig(), "USE_SYSLOG", "")
      )
      return false if !success

      # This is very important- it flushes the cache, and stores the configuration on the disk
      success = SCR.Write(path(".fcoe.config"), nil)

      success
    end

    #
    # Write ifcfg-files in /etc/sysconfig/network (for FCoE VLAN interface and underlying interface)
    # using network.scr from yast2/library/network
    #
    def WriteSysconfigFiles
      netcards = GetNetworkCards()
      success = true

      Builtins.foreach(netcards) do |card|
        if Ops.get_string(card, "fcoe_vlan", "") != @NOT_AVAILABLE &&
            Ops.get_string(card, "fcoe_vlan", "") != @NOT_CONFIGURED
          # write ifcfg-<if>.>VLAN> only if VLAN was created (not for VLAN = 0 which means
          # FCoE is started on the network interface itself)
          if Ops.get_string(card, "vlan_interface", "") != "0"
            Builtins.y2milestone(
              "Writing /etc/sysconfig/network/ifcfg-%1",
              Ops.get_string(card, "fcoe_vlan", "")
            )
            # write /etc/sysconfig/network/ifcfg-<fcoe-vlan-interface>, e.g. ifcfg-eth3.200
            SCR.Write(
              Ops.add(
                Ops.add(
                  path(".network.value"),
                  Ops.get_string(card, "fcoe_vlan", "")
                ),
                "BOOTPROTO"
              ),
              "static"
            )
            SCR.Write(
              Ops.add(
                Ops.add(
                  path(".network.value"),
                  Ops.get_string(card, "fcoe_vlan", "")
                ),
                "STARTMODE"
              ),
              "nfsroot"
            )
            SCR.Write(
              Ops.add(
                Ops.add(
                  path(".network.value"),
                  Ops.get_string(card, "fcoe_vlan", "")
                ),
                "ETHERDEVICE"
              ),
              Ops.get_string(card, "dev_name", "")
            )
            SCR.Write(
              Ops.add(
                Ops.add(
                  path(".network.value"),
                  Ops.get_string(card, "fcoe_vlan", "")
                ),
                "USERCONTROL"
              ),
              "no"
            )
          end
          ifcfg_file = Builtins.sformat(
            "/etc/sysconfig/network/ifcfg-%1",
            Ops.get_string(card, "dev_name", "")
          )
          Builtins.y2milestone("Writing %1", ifcfg_file)

          # write /etc/sysconfig/network/ifcfg-<interface> (underlying interface), e.g. ifcfg-eth3
          if !FileUtils.Exists(ifcfg_file)
            SCR.Write(
              Ops.add(
                Ops.add(
                  path(".network.value"),
                  Ops.get_string(card, "dev_name", "")
                ),
                "BOOTPROTO"
              ),
              "static"
            )
            SCR.Write(
              Ops.add(
                Ops.add(
                  path(".network.value"),
                  Ops.get_string(card, "dev_name", "")
                ),
                "STARTMODE"
              ),
              "nfsroot"
            )
            SCR.Write(
              Ops.add(
                Ops.add(
                  path(".network.value"),
                  Ops.get_string(card, "dev_name", "")
                ),
                "NAME"
              ),
              Ops.get_string(card, "device", "")
            )
          else
            # don't overwrite BOOTPROTO !!!
            SCR.Write(
              Ops.add(
                Ops.add(
                  path(".network.value"),
                  Ops.get_string(card, "dev_name", "")
                ),
                "STARTMODE"
              ),
              "nfsroot"
            )
          end
        end
      end
      # This is very important- it flushes the cache, and stores the configuration on the disk
      success = SCR.Write(path(".network"), nil)
      if !success
        Builtins.y2error("Error writing /etc/sysconfig/network/ifcfg-files")
      end
      success
    end

    #
    # Write /etc/fcoe/cfg-ethx files using fcoe_cfg-ethx.scr
    #
    def WriteCfgFiles
      netcards = GetNetworkCards()

      success = false

      Builtins.foreach(netcards) do |card|
        if Ops.get_string(card, "fcoe_vlan", "") != @NOT_AVAILABLE &&
            Ops.get_string(card, "fcoe_vlan", "") != @NOT_CONFIGURED
          command = ""
          output = {}

          Builtins.y2milestone(
            "Writing /etc/fcoe/cfg-%1",
            Ops.get_string(card, "cfg_device", "")
          )
          success = SCR.Write(
            Ops.add(
              Ops.add(
                path(".fcoe.cfg-ethx.value"),
                Ops.get_string(card, "cfg_device", "")
              ),
              "FCOE_ENABLE"
            ),
            Ops.get_string(card, "fcoe_enable", "no")
          )
          if !success
            Builtins.y2error(
              "Writing FCOE_ENABLE=%1 failed",
              Ops.get_string(card, "fcoe_enable", "no")
            )
          end
          success = SCR.Write(
            Ops.add(
              Ops.add(
                path(".fcoe.cfg-ethx.value"),
                Ops.get_string(card, "cfg_device", "")
              ),
              "DCB_REQUIRED"
            ),
            Ops.get_string(card, "dcb_required", "no")
          )
          if !success
            Builtins.y2error(
              "Writing DCB_REQUIRED=%1 failed",
              Ops.get_string(card, "dcb_required", "no")
            )
          end
          success = SCR.Write(
            Ops.add(
              Ops.add(
                path(".fcoe.cfg-ethx.value"),
                Ops.get_string(card, "cfg_device", "")
              ),
              "AUTO_VLAN"
            ),
            Ops.get_string(card, "auto_vlan", "no")
          )
          if !success
            Builtins.y2error(
              "Writing AUTO_VLAN=%1 failed",
              Ops.get_string(card, "auto_vlan", "no")
            )
          end
          if Ops.get_string(card, "dcb_required", "no") == "yes"
            # enable DCB on the interface
            command = Builtins.sformat(
              "dcbtool sc %1 dcb on",
              Ops.get_string(card, "dev_name", "")
            )
            Builtins.y2milestone("Executing command: %1", command)
            output = Convert.to_map(
              SCR.Execute(path(".target.bash_output"), command)
            )
            Builtins.y2milestone("Output: %1", output)
            if Ops.get_integer(output, "exit", 255) != 0
              # only warning, not necessarily an error
              Builtins.y2warning("Command: %1 failed", command)
            end
            # enable App:FCoE on the interface
            command = Builtins.sformat(
              "dcbtool sc %1 app:0 e:1 a:1 w:1",
              Ops.get_string(card, "dev_name", "")
            )
            Builtins.y2milestone("Executing command: %1", command)

            output = Convert.to_map(
              SCR.Execute(path(".target.bash_output"), command)
            )
            Builtins.y2milestone("Output: %1", output)
            if Ops.get_integer(output, "exit", 255) != 0
              # only warning, not necessarily an error
              Builtins.y2warning("Command: %1 failed", command)
            end
          end
        end
      end
      # This is very important- it flushes the cache, and stores the configuration on the disk
      success = SCR.Write(path(".fcoe.cfg-ethx"), nil)

      success
    end

    # restart service fcoe
    def RestartServiceFcoe
      ret = true

      Builtins.y2milestone("Restarting fcoe")
      ret = Service.Restart("fcoe") 

      ret
    end

    # Read all fcoe-client settings
    # @return true on success
    def Read
      # FcoeClient read dialog caption
      caption = _("Initializing fcoe-client Configuration")

      # Set the right number of stages
      steps = 4

      sl = 500
      Builtins.sleep(sl)

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/3
          _("Check installed packages"),
          # Progress stage 2/3
          _("Check services"),
          # Progress stage 3/3
          _("Detect network cards"),
          # Progress stage 4/4
          _("Read /etc/fcoe/config")
        ],
        [
          # Progress step 1/3
          _("Checking for installed packages..."),
          # Progress step 2/3
          _("Checking for services..."),
          # Progress step 3/3
          _("Detecting network cards..."),
          # Progress step 4/4
          _("Reading /etc/fcoe/config"),
          # Progress finished
          _("Finished")
        ],
        ""
      )

      # a check for running network services doesn't make sense (is not needed), the
      # interfaces are set up in FcoeClient::GetVlanInterfaces()

      return false if PollAbort()
      Progress.NextStage

      # checking whether fcoe-utils is installed (requires lldpad, ...)
      installed = CheckInstalledPackages()

      # Error message
      return false if !installed
      Builtins.sleep(sl)

      # read current settings
      return false if PollAbort()
      Progress.NextStage

      # find sockets fcoemon and lldpad, check whether sockets are active, start if required
      start_status = ServiceStatus()

      # Error message
      Report.Error(_("Starting of services failed.")) if !start_status
      Builtins.sleep(sl)

      # check whether auto start of daemon fcoemon and lldpad is enabled or not
      DetectStartStatus()

      return false if PollAbort()
      Progress.NextStage

      # detect netcards
      @network_interfaces = DetectNetworkCards(ProbeNetcards())

      # Error message
      Report.Warning(_("Cannot detect devices.")) if @network_interfaces.empty?
      Builtins.sleep(sl)

      return false if PollAbort()
      Progress.NextStage

      # read general FCoE settings
      success = ReadFcoeConfig()

      # Error message
      Report.Error(_("Cannot read /etc/fcoe/config.")) if !success
      Builtins.sleep(sl)

      Progress.Finish

      return false if PollAbort()
      # modified = false is from CWM template
      @modified = false

      true
    end

    # Write all fcoe-client settings
    # @return true on success
    def Write
      # FcoeClient read dialog caption
      caption = _("Saving fcoe-client Configuration")
      Builtins.y2milestone("Saving fcoe-client Configuration")

      # Set the number of stages
      steps = 3

      sl = 500

      # We do not set help text here, because it was set outside
      Progress.New(
        caption,
        " ",
        steps,
        [
          # Progress stage 1/2
          _("Write the settings"),
          # Progress stage 2/3
          _("Restart FCoE service"),
          # Progress stage 3/3
          _("Adjust start of services")
        ],
        [
          # Progress step 1/2
          _("Writing the settings..."),
          # Progress step 2/3
          _("Restarting FCoE service..."),
          # Progress sstep 3/3
          _("Adjusting start of services..."),
          # Progress finished
          _("Finished")
        ],
        ""
      )

      # iscsi-client prepares for AutoYaST in Mode::autoinst()/autoupgrade()
      # (see IscsiClient.ycp, line 236, 241)
      # These things are done in fcoe-client_auto.ycp (should be sufficient there)

      is_running = Progress.IsRunning
      Builtins.y2debug("**** Progress still running: %1", is_running)

      # write settings
      return false if PollAbort()
      Progress.NextStage

      success = WriteFcoeConfig()
      # Error message
      Report.Error(_("Cannot write settings to /etc/fcoe/config.")) if !success
      Builtins.sleep(sl)

      success = WriteCfgFiles()
      if !success
        Report.Error(
          _(
            "Cannot write settings for FCoE interfaces.\nFor details, see /var/log/YaST2/y2log."
          )
        )
      end

      return false if PollAbort()
      Progress.NextStage

      # restart fcoe to enable changes
      success = RestartServiceFcoe()
      # Error message
      Report.Error(_("Restarting of service fcoe failed.")) if !success
      Builtins.sleep(sl)

      # write ifcfg-files in /etc/sysconfig/network
      success = WriteSysconfigFiles()
      # Error message
      if !success
        Report.Error(_("Cannot write /etc/sysconfig/network/ifcfg-files."))
      end
      Builtins.sleep(sl)

      return false if PollAbort()
      Progress.NextStage

      # adjust start status of services lldpad and fcoe
      AdjustStartStatus()

      # Adding additional package (like in IscsiClient.ycp, line 257)
      # is done in inst_fcoe-client.ycp (PackagesProposal::AddResolvables)
      Builtins.sleep(sl)

      return false if PollAbort()

      true
    end

    # Get all fcoe-client settings from the first parameter
    # (For use by autoinstallation.)
    # @param [Hash] settings The YCP structure to be imported.
    # @return [Boolean] True on success
    def Import(settings)
      settings = deep_copy(settings)
      # fill variables
      @fcoe_general_config = Ops.get_map(settings, "fcoe_cfg", {})
      @network_interfaces = Ops.get_list(settings, "interfaces", [])
      @service_start = Ops.get_map(settings, "service_start", {})

      SetModified(true)
      Builtins.y2milestone("Configuration has been imported")

      true
    end

    # Dump the fcoe-client settings to a single map
    # (For use by autoinstallation.)
    # @return [Hash] Dumped settings (later acceptable by Import ())
    def Export
      # return map containing current settings
      {
        "fcoe_cfg"      => @fcoe_general_config,
        "interfaces"    => @network_interfaces,
        "service_start" => @service_start
      }
    end

    # Create a textual summary and a list of unconfigured cards
    # @return summary of the current configuration
    def Summary
      summary = ""
      fcoe_config = {}
      netcards = []
      service_start = {}

      # Configuration summary text for autoyast
      summary = Summary.AddLine(summary, _("<b>General FCoE configuration</b>"))
      fcoe_config = GetFcoeConfig()
      # options from config file, not meant for translation
      summary = Summary.AddLine(
        summary,
        Builtins.sformat("DEBUG: %1", Ops.get_string(fcoe_config, "DEBUG", ""))
      )
      summary = Summary.AddLine(
        summary,
        Builtins.sformat(
          "USE_SYSLOG: %1",
          Ops.get_string(fcoe_config, "USE_SYSLOG", "")
        )
      )
      summary = Summary.AddLine(summary, _("<b>Interfaces</b>"))
      netcards = GetNetworkCards()
      Builtins.foreach(netcards) do |card|
        summary = Summary.AddLine(
          summary,
          Builtins.sformat(
            "%1: %2 %3: %4",
            # network card, e.g. eth0
            _("<i>Netcard</i>:"),
            Ops.get_string(card, "dev_name", ""),
            # nothing to translate here (abbreviation for
            # Fibre Channel over Ethernet Virtual LAN interface)
            "<i>FCoE VLAN</i>",
            Ops.get_string(card, "fcoe_vlan", "")
          )
        )
      end
      service_start = GetStartStatus()
      summary = Summary.AddLine(summary, _("<b>Starting of services</b>"))

      # starting of service "fcoe" at boot time is enabled or disabled
      summary = Summary.AddLine(
        summary,
        Builtins.sformat(
          "fcoe: %1",
          Ops.get_boolean(service_start, "fcoe", false) ?
            _("enabled") :
            _("disabled")
        )
      )
      # starting of service "lldpad" at boot time is enabled or disabled
      summary = Summary.AddLine(
        summary,
        Builtins.sformat(
          "lldpad: %1",
          Ops.get_boolean(service_start, "lldpad", false) ?
            _("enabled") :
            _("disabled")
        )
      )

      [summary, []]
    end

    # Create an overview table with all configured cards
    # @return table items
    def Overview
      # TODO FIXME: your code here...
      []
    end

    # Return packages needed to be installed and removed during
    # Autoinstallation to insure module has all needed software
    # installed.
    # @return [Hash] with 2 lists.
    def AutoPackages
      # installation of fcoe-utils required
      { "install" => [FcoeClientClass::FCOE_PKG_NAME], "remove" => [] }
    end

    publish :function => :Modified, :type => "boolean ()"
    publish :function => :FcoeClient, :type => "void ()"
    publish :function => :Abort, :type => "boolean ()"
    publish :function => :SetModified, :type => "void (boolean)"
    publish :function => :ProposalValid, :type => "boolean ()"
    publish :function => :SetProposalValid, :type => "void (boolean)"
    publish :function => :WriteOnly, :type => "boolean ()"
    publish :function => :TestMode, :type => "boolean ()"
    publish :function => :SetWriteOnly, :type => "void (boolean)"
    publish :function => :SetAbortFunction, :type => "void (boolean ())"
    publish :function => :PollAbort, :type => "boolean ()"
    publish :variable => :current_card, :type => "integer"
    publish :variable => :NOT_CONFIGURED, :type => "string"
    publish :variable => :NOT_AVAILABLE, :type => "string"
    publish :variable => :lldpad_started, :type => "boolean"
    publish :variable => :fcoe_started, :type => "boolean"
    publish :function => :SetFcoeConfigValue, :type => "void (string, string)"
    publish :function => :GetFcoeConfig, :type => "map <string, string> ()"
    publish :function => :AddRevertCommand, :type => "void (string)"
    publish :function => :GetRevertCommands, :type => "list ()"
    publish :function => :ResetRevertCommands, :type => "void ()"
    publish :function => :GetNetworkCards, :type => "list <map> ()"
    publish :function => :GetCurrentNetworkCard, :type => "map ()"
    publish :function => :SetNetworkCardsValue, :type => "void (integer, map)"
    publish :function => :SetNetworkCards, :type => "void (list <map>)"
    publish :function => :ResetNetworkCards, :type => "void ()"
    publish :function => :GetVlanInterfaces, :type => "map <string, list> (list)"
    publish :function => :GetFcoeVlanInterface, :type => "string (string, string)"
    publish :function => :CreateFcoeConfig, :type => "map <string, string> (string, map)"
    publish :function => :GetFcoeStatus, :type => "map <string, string> (string, string)"
    publish :function => :AdjustStartStatus, :type => "void ()"
    publish :function => :SetStartStatus, :type => "void (string, boolean)"
    publish :function => :GetStartStatus, :type => "map <string, boolean> ()"
    publish :function => :ServiceStatus, :type => "boolean ()"
    publish :function => :IsConfigured, :type => "list (string)"
    publish :function => :DetectNetworkCards, :type => "boolean ()"
    publish :function => :ReadFcoeConfig, :type => "boolean ()"
    publish :function => :WriteFcoeConfig, :type => "boolean ()"
    publish :function => :WriteSysconfigFiles, :type => "boolean ()"
    publish :function => :WriteCfgFiles, :type => "boolean ()"
    publish :function => :RestartServiceFcoe, :type => "boolean ()"
    publish :function => :Read, :type => "boolean ()"
    publish :function => :Write, :type => "boolean ()"
    publish :function => :Import, :type => "boolean (map)"
    publish :function => :Export, :type => "map ()"
    publish :function => :Summary, :type => "list ()"
    publish :function => :Overview, :type => "list ()"
    publish :function => :AutoPackages, :type => "map ()"
  end

  FcoeClient = FcoeClientClass.new
  FcoeClient.main
end
