#!/usr/bin/env rspec
require_relative '../src/modules/FcoeClient'

describe Yast::FcoeClientClass do
  before :each do
    @fcoe = Yast::FcoeClientClass.new
    @fcoe.main()
  end
  
  describe "#GetVlanInterfaces" do
    context "with valid arguments" do
      it "returns map containing info about vlan interfaces per netcard" do
        expect(@fcoe.GetVlanInterfaces(["eth0", "eth1", "eth2"],
                                       ["eth0     | 200  | 00:0d:ec:a2:ef:00",
                                        "eth0     | 300  | 00:0d:ec:a2:ef:01",
                                        "eth2     | 200  | 00:0d:ec:a2:ef:02" ])).to eq(
                      {"eth0" => [{ "vlan" => "200", "fcf" => "00:0d:ec:a2:ef:00" },
                                  { "vlan" => "300", "fcf" => "00:0d:ec:a2:ef:01" }],
                       "eth2" => [{ "vlan" => "200", "fcf" => "00:0d:ec:a2:ef:02" }]
                      })
      end
    end
  end
  describe "#GetVlanInterfaces" do
    context "with an empty list as argument" do
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

