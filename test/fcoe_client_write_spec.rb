#!/usr/bin/env rspec
require_relative "test_helper"
Yast.import "FcoeClient"
Yast.import "Lan"

describe Yast::FcoeClientClass do
  subject { Yast::FcoeClient }

  describe "#ProbeNetcards" do
    before do
      expect(subject).to receive(:TestMode).and_return true
    end

    it "returns an array" do
      expect(subject.ProbeNetcards).to be_an Array
    end
  end

  describe "#WriteSysconfigFiles" do
    let(:config) { stub_const("Y2Network::Config", double.as_null_object) }

    before do
      allow(subject).to receive(:GetNetworkCards).and_return(interfaces)
      allow(Yast::Lan).to receive(:yast_config).and_return(config)
      allow(Yast::Lan).to receive(:read_config)
      allow(Yast::Lan).to receive(:write_config)
    end


    context "when no VLAN was created for any of the interfaces" do
      let(:interfaces) do
        [
          { "dev_name" => "eth0", "fcoe_vlan" => "not available" },
          { "dev_name" => "eth1", "fcoe_vlan" => "not configured" },
          { "dev_name" => "eth2", "fcoe_vlan" => "" },
        ]
      end

      it "smokes not" do
        expect { subject.WriteSysconfigFiles }.to_not raise_error
      end

      it "does not nodify the network configuration" do
        expect(Yast::Lan).to_not receive(:write_config)

        subject.WriteSysconfigFiles
      end
    end

    context "if an FCoE VLAN is created for some interface" do
      let(:interfaces) do
        [
          { "dev_name" => "eth0", "fcoe_vlan" => "not available" },
          { "dev_name" => "eth1", "fcoe_vlan" => "eth1.500-fcoe" },
          { "dev_name" => "eth2", "fcoe_vlan" => "" },
        ]
      end

      before do
        allow(Yast::FileUtils).to receive(:Exists).and_return(false)
      end

      it "calls the FCoE connection generator to add or update the device and VLAN connections" do
        expect_any_instance_of(Y2Network::FcoeConnGenerator)
          .to receive(:update_connections_for).once.with(interfaces[1])

        subject.WriteSysconfigFiles
      end

      it "writes the modified network connections configuration" do
        expect(Yast::Lan).to receive(:write_config).with(only: [:connections])

        subject.WriteSysconfigFiles
      end

      it "smokes not" do
        expect { subject.WriteSysconfigFiles }.to_not raise_error
      end
    end
  end
end
