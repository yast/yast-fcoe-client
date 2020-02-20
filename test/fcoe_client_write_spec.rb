#!/usr/bin/env rspec
require_relative "test_helper"
Yast.import "FcoeClient"

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
    before do
      allow(subject).to receive(:GetNetworkCards).and_return(interfaces)
    end


    context "when no VLAN was created for any of the interfaces" do
      let(:interfaces) do
        [
          { "dev_name" => "eth0", "fcoe_vlan" => "not available" },
          { "dev_name" => "eth1", "fcoe_vlan" => "not configured" }
        ]
      end

      it "smokes not" do
        expect { subject.WriteSysconfigFiles }.to_not raise_error
      end

      it "writes nothing into /etc/sysconfig/network" do
        expect(Yast::SCR).to_not receive(:Write)
          .with(path_matching(/^\.network\..*/), anything)

        subject.WriteSysconfigFiles
      end
    end

    context "if an FCoE VLAN is created for some interface" do
      let(:interfaces) do
        [
          { "dev_name" => "eth0", "fcoe_vlan" => "not available" },
          { "dev_name" => "eth1", "fcoe_vlan" => "eth1.500-fcoe" },
        ]
      end

      before do
        allow(Yast::SCR).to receive(:Write).and_return(true)
        allow(Yast::FileUtils).to receive(:Exists).and_return(false)
      end

      it "smokes not" do
        expect { subject.WriteSysconfigFiles }.to_not raise_error
      end

      it "writes the sysconfig configuration for the interface and its FCoE VLAN" do
        expect(Yast::SCR).to receive(:Write)
          .with(path_matching(/^\.network\.value\.\"eth1.500-fcoe\"\.*/), anything)
        expect(Yast::SCR).to receive(:Write)
          .with(path_matching(/^\.network\.value\.\"eth1\"\.*/), anything)
        # A final call is also needed to flush the content
        expect(Yast::SCR).to receive(:Write).with(Yast::Path.new(".network"), nil)

        subject.WriteSysconfigFiles
      end

      it "writes nothing in /etc/sysconfig/network for interfaces without FCoE VLAN" do
        allow(Yast::SCR).to receive(:Write) do |path, value|
          # All calls to SCR.Write must contain a path starting with ".network.value.\"eth1"
          # or exactly the path ".network" (for flushing)
          expect(path.to_s).to match("(^\.network$)|(^\.network\.value\.\"eth1(\.|\"))")
        end

        subject.WriteSysconfigFiles
      end
    end
  end
end
