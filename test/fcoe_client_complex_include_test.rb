#!/usr/bin/env rspec
require_relative "test_helper"

Yast.import "Popup"

class ComplexIncludeTest < Yast::Module
  def initialize
    Yast.include self, "fcoe-client/complex.rb"
  end
end

describe "Yast::FcoeClientComplexInclude" do
  subject { ComplexIncludeTest.new }

  describe "#HandleInterfacesDialog" do
    context "when handling :create" do
      let(:event) { { "ID" => :create } }

      before do
        card = {
          "dev_name" => "eth9",
          "fcoe_vlan" => "eth9.500",
          "vlan_interface" => "500"
        }
        expect(Yast::FcoeClient)
          .to receive(:GetCurrentNetworkCard).twice
          .and_return(card)
        expect(Yast::FcoeClient)
          .to receive(:GetNetworkCards).twice
          .and_return([card])
        expect(Yast::Popup).to receive(:YesNoHeadline).and_return(true)
      end

      it "smokes not" do
        expect(Yast::SCR)
          .to receive(:Execute)
                .with(path(".target.bash_output"), "fipvlan -c -s eth9")
                .and_return({"exit" => 0})
        expect(Yast::FcoeClient).to receive(:GetFcoeVlanInterface).and_return("eth9.500")
        expect { subject.HandleInterfacesDialog(nil, event) }.to_not raise_error
      end
    end
  end
end
