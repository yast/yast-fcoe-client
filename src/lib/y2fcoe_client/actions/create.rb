require "y2fcoe_client/actions/base"

module Y2FcoeClient
  module Actions
    # haendel:~/:[0]# fipvlan -c -s eth3
    # Fibre Channel Forwarders Discovered
    # interface       | VLAN | FCF MAC
    # ------------------------------------------
    # eth3            | 200  | 00:0d:ec:a2:ef:00
    # Created VLAN device eth3.200
    # Starting FCoE on interface eth3.200
    class Create < Base
      def initialize(*args)
        super
        textdomain "fcoe-client"
      end

      def validate
        issues = Y2Issues::List.new
        configured_vlans = client.IsConfigured(dev_name)
        log.info "Configured VLANs on #{dev_name}: #{configured_vlans}"
        return issues if configured_vlans.empty?

        issues << issue_for_check(configured_vlans)
        issues
      end

      def execute
        issues = Y2Issues::List.new

        # In first stage of installation (and also in the installed existed if the VLAN is not
        # there yet) - create and start FCoE VLAN interface
        command =
          if card["auto_vlan"] == "yes" || vlan_interface == "0"
            "/usr/sbin/fipvlan -c -s -f '-fcoe' #{dev_name.shellescape}"
          else
            "/usr/sbin/fipvlan -c -s #{dev_name.shellescape}"
          end

        if !Yast::Stage.initial
          # If VLAN (ie. /etc/sysconfig/network/ifcfg-<if>.<vlan>) already exists, only start FCoE
          # by calling 'ifup' for the interface (creates /proc/net/vlan/<if>.<vlan>)
          ifcfg_file = "/etc/sysconfig/network/ifcfg-#{dev_name}.#{vlan_interface}"
          if Yast::FileUtils.Exists(ifcfg_file)
            if execute_ifup
              # only start FCoE
              command = "/usr/sbin/fipvlan -s #{dev_name.shellescape}"
            end
          end
        end

        if !call_cmd(command)
          msg = Yast::Builtins.sformat(_("Command \"%1\" on %2 failed."), command, dev_name)
          issues << Y2Issues::Issue.new(msg, severity: :error)
          return issues unless test?
        end

        status_map = {}
        if fcoe_vlan_interface != ""
          status_map = client.CreateFcoeConfig(fcoe_vlan_interface, card)
          log.info("GOT status map: #{status_map}")

          # command to be able to revert the creation of FCoE VLAN interface in case of 'Cancel'
          # FcoeClient::AddRevertCommand(
          #   sformat(
          #     "fcoeadm -d %1 && vconfig rem %2", status_map["cfg_device"]:"", fcoe_vlan_interface
          #   )
          # );
          # 'fcoeadm -d <if>/<if>.<vlan>' fails here, 'vconfig rem <if>.<vlan>' succeeds
          # and removes the interface properly (tested on SP2 RC1)
          # TODO: Retest for SLES12
          client.AddRevertCommand("/usr/sbin/vconfig rem #{fcoe_vlan_interface.shellescape}")
        end

        update_card(status_map)

        issues
      end

      private

      def issue_for_check(configured_vlans)
        if Yast::Builtins.contains(configured_vlans, "0")
          msg = Yast::Builtins.sformat(
            _("Cannot start FCoE on VLAN interface %1\n" +
              "because FCoE is already configured on\n" +
              "network interface %2 itself."),
              vlan_interface, dev_name
          )
          return Y2Issues::Issue.new(msg, severity: :error)
        end

        if vlan_interface == "0"
          msg = Yast::Builtins.sformat(
            _("Cannot start FCoE on network interface %1 itself\n" +
              "because FCoE is already configured on\n" +
              "VLAN interface(s) %2."),
          dev_name, configured_vlans
          )
          return Y2Issues::Issue.new(msg, severity: :error)
        end

        msg = Yast::Builtins.sformat(
          "FCoE VLAN interface(s) %1 already configured on %2.",
          configured_vlans, dev_name
        )
        Y2Issues::Issue.new(msg)
      end

      def fcoe_vlan_interface
        # for VLAN interface "0" there isn't an entry in /proc/net/vlan/config
        if vlan_interface == "0"
          return dev_name # get interface from /proc/net/vlan/config
        end

        Yast::FcoeClient.GetFcoeVlanInterface(dev_name, vlan_interface)
      end

      def update_card(status_map)
        # set new values in global map network_interfaces
        card["fcoe_vlan"] = fcoe_vlan_interface.empty? ? client.NOT_CONFIGURED : fcoe_vlan_interface
        card["fcoe_enable"] = status_map.fetch("FCOE_ENABLE", "")
        card["dcb_required"] = status_map.fetch("DCB_REQUIRED", "")
        card["auto_vlan"] = status_map.fetch("AUTO_VLAN", "")
        card["cfg_device"] = status_map.fetch("cfg_device", "")
        client.SetModified(true)
        client.SetNetworkCardsValue(index, card)
      end

      def execute_ifup
        command = "/usr/sbin/ifup #{dev_name.shellescape}.#{vlan_interface.shellescape}"
        call_cmd(command)
      end
    end
  end
end

