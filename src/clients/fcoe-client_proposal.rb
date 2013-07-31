# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2006 Novell, Inc. All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

# File:	clients/fcoe-client_proposal.ycp
# Package:	Configuration of fcoe-client
# Summary:	Proposal function dispatcher.
# Authors:	Gabriele Mohr <gs@suse.de>
#
#
# Proposal function dispatcher for fcoe-client configuration.
# See source/installation/proposal/proposal-API.txt
module Yast
  class FcoeClientProposalClient < Client
    def main

      textdomain "fcoe-client"

      Yast.import "FcoeClient"
      Yast.import "Progress"

      # The main ()
      Builtins.y2milestone("----------------------------------------")
      Builtins.y2milestone("FcoeClient proposal started")

      @func = Convert.to_string(WFM.Args(0))
      @param = Convert.to_map(WFM.Args(1))
      @ret = {}

      # create a textual proposal
      if @func == "MakeProposal"
        @proposal = ""
        @warning = nil
        @warning_level = nil
        @force_reset = Ops.get_boolean(@param, "force_reset", false)

        if @force_reset || !FcoeClient.ProposalValid
          FcoeClient.SetProposalValid(true)
          @progress_orig = Progress.set(false)
          FcoeClient.Read
          Progress.set(@progress_orig)
        end
        @sum = FcoeClient.Summary
        @proposal = Ops.get_string(@sum, 0, "")

        @ret = {
          "preformatted_proposal" => @proposal,
          "warning_level"         => @warning_level,
          "warning"               => @warning
        }
      # run the module
      elsif @func == "AskUser"
        @stored = FcoeClient.Export
        @seq = Convert.to_symbol(
          WFM.CallFunction("fcoe-client", [path(".propose")])
        )
        FcoeClient.Import(@stored) if @seq != :next
        Builtins.y2debug("stored=%1", @stored)
        Builtins.y2debug("seq=%1", @seq)
        @ret = { "workflow_sequence" => @seq }
      # create titles
      elsif @func == "Description"
        @ret = {
          # Rich text title for FcoeClient in proposals
          "rich_text_title" => _(
            "FcoeClient"
          ),
          # Menu title for FcoeClient in proposals
          "menu_title"      => _(
            "&FcoeClient"
          ),
          "id"              => "fcoe-client"
        }
      # write the proposal
      elsif @func == "Write"
        FcoeClient.Write
      else
        Builtins.y2error("unknown function: %1", @func)
      end

      # Finish
      Builtins.y2debug("ret=%1", @ret)
      Builtins.y2milestone("FcoeClient proposal finished")
      Builtins.y2milestone("----------------------------------------")
      deep_copy(@ret) 

      # EOF
    end
  end
end

Yast::FcoeClientProposalClient.new.main
