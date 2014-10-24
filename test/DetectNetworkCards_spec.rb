#!/usr/bin/env rspec
require_relative '../src/modules/FcoeClient'

describe Yast::FcoeClientClass do
  before :each do
    @fcoe = Yast::FcoeClientClass.new
    @fcoe.main()

    @test_class = @fcoe

    @test_class.stub(:GetVlanInterfaces).and_return({ "eth1" => [{ "vlan" => "400", "fcf" => "00:0d:ec:a2:ef:00" },
                                                                 { "vlan" => "300", "fcf" => "00:0d:ec:a2:ef:01" }],
                                                      "eth2" => [{ "vlan" => "200", "fcf" => "00:0d:ec:a2:ef:02" }]})

    @test_class.stub(:GetFcoeVlanInterface).with("eth1", "400").and_return("eth1.400")
    @test_class.stub(:GetFcoeVlanInterface).with("eth1", "300").and_return("")
    @test_class.stub(:GetFcoeVlanInterface).with("eth2", "200").and_return("")

    @test_class.stub(:FcoeOnOnterface?).and_return(false)

    @test_class.stub(:GetFcoeStatus).with("eth1.400", "eth1").and_return({
                                                                           "AUTO_VLAN" => "no",
                                                                           "DCB_REQUIRED"=>"yes",
                                                                           "FCOE_ENABLE" => "yes",
                                                                           "cfg_device" => "eth1.400"
                                                                         })
    @test_class.stub(:GetFcoeStatus).with("eth1.300", "eth1").and_return({})
    @test_class.stub(:GetFcoeStatus).with("eth2.200", "eth2").and_return({})

    @test_class.stub(:DCBCapable).and_return("no")
  end

  context "with valid argument (a list of maps containing hwinfo about netcards)" do
    it "#DetectNetworkCards returns a list of maps containing card info extended by vlan/fcoe info" do
      answer = @test_class.DetectNetworkCards([
                                               {
                                                 "bus"       => "PCI",
                                                 "bus_hwcfg" => "pci",
                                                 "class_id"  => 2,
                                                 "dev_name"  => "eth1",
                                                 "driver"    => "fcoe",
                                                 "dev_names" => ["eth1"],
                                                 "device"    => "TEST Ethernet Controller",
                                                 "model"     => "Intel PRO/1000 MT Desktop Adapter",
                                                 "resource"  => { "hwaddr" => [{ "addr" => "08:00:27:11:64:e4" }] }
                                               },
                                               {
                                                 "bus"       => "PCI",
                                                 "bus_hwcfg" => "pci",
                                                 "class_id"  => 2,
                                                 "dev_name"  => "eth2",
                                                 "driver"    => "bnx2x",
                                                 "dev_names" => ["eth2"],
                                                 "model"     => "Intel PRO/1000 MT Desktop Adapter",
                                                 "resource"  => { "hwaddr" => [{ "addr" => "08:23:27:99:64:78" }] },
                                                 "fcoeoffload" => true,
                                                 "storageonly" => true,
                                                 "iscsioffload"=> false
                                               }
                                              ])
      answer.should eq([
                        {
                          "auto_vlan" => "yes", 
                          "cfg_device"=> "", 
                          "dcb_capable" => "no", 
                          "dcb_required" => "no", 
                          "dev_name" => "eth1",
                          "driver" => "fcoe",
                          "device" => "TEST Ethernet Controller", 
                          "fcoe_enable" => "yes", 
                          "fcoe_vlan" => "not configured", 
                          "mac_addr" => "08:00:27:11:64:e4", 
                          "vlan_interface" => "300"
                        }, 
                        {
                          "auto_vlan" => "no", 
                          "cfg_device" => "eth1.400", 
                          "dcb_capable" => "no", 
                          "dcb_required" => "yes",
                          "driver" => "fcoe",
                          "dev_name" => "eth1", 
                          "device" => "TEST Ethernet Controller", 
                          "fcoe_enable" => "yes", 
                          "fcoe_vlan" => "eth1.400", 
                          "mac_addr"  =>  "08:00:27:11:64:e4", 
                          "vlan_interface" => "400"
                        }, 
                        {
                          "auto_vlan" => "yes", 
                          "cfg_device" => "", 
                          "dcb_capable" => "no", 
                          "dcb_required" => "no", 
                          "dev_name" => "eth2", 
                          "driver" => "bnx2x",
                          "device" => "Intel PRO/1000 MT Desktop Adapter", 
                          "fcoe_enable" => "yes", 
                          "fcoe_vlan" => "not configured", 
                          "mac_addr" => "08:23:27:99:64:78", 
                          "vlan_interface" => "200",
                          "fcoe_flag" => true,
                          "iscsi_flag" => false,
                          "storage_only" => true
                        }
                       ])

    end
  end

  context "with empty list as argument" do
    it "#DetectNetworkCards returns empty list" do
      answer = @test_class.DetectNetworkCards([])
      answer.should eq([])
    end
  end

end
