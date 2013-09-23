require '../src/modules/FcoeClient'

describe Yast::FcoeClientClass do
  before :each do
    @fcoe = Yast::FcoeClientClass.new
    @fcoe.main()
    @fcoe.SetWriteOnly(true)
  end
  
  describe "#WriteOnly" do
    it "returns true" do
      expect(@fcoe.WriteOnly).to be_true
    end
  end

  describe "#GetVlanInterfaces" do
    it "returns correct map" do
      expect(@fcoe.GetVlanInterfaces(["eth0", "eth1", "eth2"],
                                     ["eth0     | 200  | 00:0d:ec:a2:ef:00",
                                      "eth0     | 300  | 00:0d:ec:a2:ef:01",
                                      "eth2     | 200  | 00:0d:ec:a2:ef:02" ])).to eq(
        { "eth0" => [{ "vlan" => "200", "fcf" => "00:0d:ec:a2:ef:00" },
                     { "vlan" => "300", "fcf" => "00:0d:ec:a2:ef:01" }],
          "eth2" => [{ "vlan" => "200", "fcf" => "00:0d:ec:a2:ef:02" }]
        })
    end
  end
  describe "#GetVlanInterfaces" do
    it "returns empty map" do
      expect(@fcoe.GetVlanInterfaces(["eth0", "eth1", "eth2"], [])).to eq({})  
    end
  end

  describe "#GetVlanInterfaces" do
    it "also returns empty map" do
      expect(@fcoe.GetVlanInterfaces([], [])).to eq({})  
    end
  end
  
end

