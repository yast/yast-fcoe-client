# encoding: utf-8

module Yast
  class FcoeClientClient < Client
    def main
      # testedfiles: FcoeClient.ycp

      Yast.include self, "testsuite.rb"
      TESTSUITE_INIT([], nil)

      Yast.import "FcoeClient"

      DUMP("FcoeClient::Modified")
      TEST(lambda { FcoeClient.Modified }, [], nil)

      nil
    end
  end
end

Yast::FcoeClientClient.new.main
