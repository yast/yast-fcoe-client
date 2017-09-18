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
    context "for odd cases" do
      before do
        interfaces = [
          { "fcoe_vlan" => "not available" },
          { "fcoe_vlan" => "not configured" },
        ]
        expect(subject).to receive(:GetNetworkCards).and_return(interfaces)
      end

      it "smokes not" do
        expect { subject.WriteSysconfigFiles }.to_not raise_error
      end
    end

    context "for a small FCoE setup" do
      before do
        interfaces = [
          { "fcoe_vlan" => "eth1.500" }
        ]
        expect(subject).to receive(:GetNetworkCards).and_return(interfaces)
        allow(Yast::SCR).to receive(:Write).and_return(true)
        allow(Yast::FileUtils).to receive(:Exists).and_return(false)
      end

      it "smokes not" do
        expect { subject.WriteSysconfigFiles }.to_not raise_error
      end
    end
  end
end
