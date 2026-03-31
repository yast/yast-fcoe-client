require "y2fcoe_client/actions/base"

module Y2FcoeClient
  module Actions
    class Remove < Base
      def initialize(*args)
        super
        textdomain "fcoe-client"
      end

      def execute
        issues = Y2Issues::List.new

        # call fcoeadm -d <fcoe_vlan> first (bnc #719443)
        if destroy_instance
          if remove_vlan
            delete_config
            update_card
          else
            log.error("Removing of interface #{fcoe_vlan} failed")
            msg = Yast::Builtins.sformat(_("Removing of interface %1 failed."), fcoe_vlan)
            issues << Y2Issues::Issue.new(msg, severity: :error)
          end
        else
          log.error("Destroying interface #{fcoe_vlan} failed")
          msg = Yast::Builtins.sformat(_("Destroying interface %1 failed."), fcoe_vlan)
          issues << Y2Issues::Issue.new(msg, severity: :error)
        end

        issues
      end

      private

      # @return [Boolean]
      def destroy_instance
        log.info("Removing #{fcoe_vlan}")
        command = "/usr/sbin/fcoeadm -d #{card.fetch("cfg_device", "").shellescape}"
        call_cmd(command) || test?
      end

      def remove_vlan
        command = "/usr/sbin/vconfig rem #{fcoe_vlan.shellescape}"
        call_cmd(command) || test?
      end

      def delete_config
        # check whether /etc/fcoe/cfg-file is also used for another VLAN interface.
        # Example: eth1 have FCoE configured on VLAN 200 and 300 with AUTO_VLAN="yes"
        #          -> /etc/fcoe/cfg-eth1 applies to both.
        interfaces = client.GetNetworkCards()
        del_cfg = interfaces.none? { |i| shared_config?(i) }
        if del_cfg
          command = "/usr/bin/rm /etc/fcoe/cfg-#{cfg_device.shellescape}"
          call_cmd(command)
        else
          log.info("/etc/fcoe/cfg-#{cfg_device} not deleted")
        end

        if vlan_interface != "0"
          command = "/usr/bin/rm /etc/sysconfig/network/ifcfg-#{fcoe_vlan.shellescape}"
          call_cmd(command)
        else
          log.info("/etc/sysconfig/network/ifcfg-#{fcoe_vlan} not deleted")
        end
      end

      def update_card
        # set new values in global map network_interfaces
        card["fcoe_vlan"] = client.NOT_CONFIGURED
        card["fcoe_enable"] = "yes"
        card["dcb_required"] = card["dcb_capable"] == "yes" ? "yes" : "no"
        # exception for Broadcom cards: DCB_REQUIRED should be set to "no" (bnc #728658)
        card["dcb_required"] = "no" if card["driver"] == "bnx2x"
        card["auto_vlan"] = "yes" # default is "yes" (bnc #724563)
        card["cfg_device"] = ""

        client.SetModified(true)
        client.SetNetworkCardsValue(index, card)
      end

      def shared_config?(iface)
        if iface.fetch("dev_name", "") == dev_name &&
            iface.fetch("vlan_interface", "") != vlan_interface &&
            iface.fetch("cfg_device", "") == cfg_device

          log.info("/etc/fcoe/cfg-#{cfg_device} also used for VLAN #{iface['vlan_interface']}")
          return true
        end

        false
      end
    end
  end
end

