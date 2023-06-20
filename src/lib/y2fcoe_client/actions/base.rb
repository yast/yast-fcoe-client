require "y2issues"
require "shellwords"

module Y2FcoeClient
  module Actions
    class Base
      include Yast::Logger
      include Yast::I18n

      def initialize(index)
        Yast.import "FcoeClient"
        @index = index
      end

      def card
        @card ||= client.GetNetworkCards[index]
      end

      private

      attr_reader :index

      def dev_name
        card.fetch("dev_name", "")
      end

      def vlan_interface
        card.fetch("vlan_interface", "")
      end

      def fcoe_vlan
        card.fetch("fcoe_vlan", "")
      end

      def cfg_device
        card.fetch("cfg_device", "")
      end

      def client
        Yast::FcoeClient
      end

      def test?
        client.TestMode()
      end

      def call_cmd(command)
        log.info("Executing command: #{command}")
        output = Yast::SCR.Execute(Yast::Path.new(".target.bash_output"), command)
        log.info("Output: #{output}")
        output["exit"] == 0
      end
    end
  end
end
