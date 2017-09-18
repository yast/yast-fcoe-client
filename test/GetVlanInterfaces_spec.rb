#!/usr/bin/env rspec
require_relative "test_helper"
Yast.import "FcoeClient"

describe Yast::FcoeClientClass do
  before :each do
    @fcoe = Yast::FcoeClientClass.new
    @fcoe.main()
  end
  
  describe "#GetVlanInterfaces" do
    context "with a list of netcards and a list of corresponding VLANs as arguments" do
      it "returns info about VLAN interfaces per netcard (without identical VLAN IDs)" do
        expect(@fcoe.GetVlanInterfaces(["eth0", "eth1", "eth2"],
                                       ["eth0     | 200  | 00:0d:ec:a2:ef:00",
                                        "eth0     | 300  | 00:0d:ec:a2:ef:01",
                                        "eth0     | 300  | 00:0d:ec:a2:ef:02",
                                        "eth1     | 400  | 00:ef:af:34:12:ae",
                                        "eth1     | 400  | 00:ef:af:34:12:af",
                                        "eth2     | 200  | 00:0d:ec:a2:ef:03" ])).to eq(
                      {"eth0" => [{ "vlan" => "200", "fcf" => "00:0d:ec:a2:ef:00" },
                                  { "vlan" => "300", "fcf" => "00:0d:ec:a2:ef:01" }],
                       "eth1" => [{ "vlan" => "400", "fcf" => "00:ef:af:34:12:ae" }],
                       "eth2" => [{ "vlan" => "200", "fcf" => "00:0d:ec:a2:ef:03" }]
                      })
      end
    end
  end

  describe "#GetVlanInterfaces" do
    context "with a list of netcards and a list of VLANs including '0' VLAN as arguments" do
      it "returns info about VLAN interfaces per netcard (only '0' VLAN for identical FCFs)" do
        expect(@fcoe.GetVlanInterfaces(["eth0", "eth1", "eth2"],
                                       ["eth0     | 200  | 00:0d:ec:a2:ef:00",
                                        "eth0     | 300  | 00:0d:ec:a2:ef:01",
                                        "eth1     | 2016 | 00:ef:af:34:12:ae",
                                        "eth1     | 0    | 00:ef:af:34:12:ae",
                                        "eth2     | 200  | 00:0d:ec:a2:ef:03" ])).to eq(
                      {"eth0" => [{ "vlan" => "200", "fcf" => "00:0d:ec:a2:ef:00" },
                                  { "vlan" => "300", "fcf" => "00:0d:ec:a2:ef:01" }],
                       "eth1" => [{ "vlan" => "0", "fcf" => "00:ef:af:34:12:ae" }],
                       "eth2" => [{ "vlan" => "200", "fcf" => "00:0d:ec:a2:ef:03" }]
                      })
      end
    end
  end

  describe "#GetVlanInterfaces" do
    context "with a list of netcards and a list of VLANs but not for every netcard" do
      it "returns a map containing info about VLAN interfaces only for netcard having VLANs" do
        expect(@fcoe.GetVlanInterfaces(["eth0", "eth1", "eth2"],
                                       ["eth0     | 200  | 00:0d:ec:a2:ef:00",
                                        "eth0     | 300  | 00:0d:ec:a2:ef:01" ])).to eq(
                      {"eth0" => [{ "vlan" => "200", "fcf" => "00:0d:ec:a2:ef:00" },
                                  { "vlan" => "300", "fcf" => "00:0d:ec:a2:ef:01" }]
                      })
      end
    end
  end

  describe "#GetVlanInterfaces" do
    context "with an empty list of VLANs as argument" do
      it "returns an empty map" do
        expect(@fcoe.GetVlanInterfaces(["eth0", "eth1", "eth2"], [])).to eq({})
      end
    end
  end

  describe "#GetVlanInterfaces" do
    context "with both arguments are empty lists" do
      it "returns an empty map" do
        expect(@fcoe.GetVlanInterfaces([], [])).to eq({})
      end
    end
  end
  
end

