// Copyright 2024 Thales DIS France SAS
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: Yannick Casamatta - Thales
// Date: 09/01/2024


module cva6_rvfi_probes
  import ariane_pkg::*;
#(
    parameter config_pkg::cva6_cfg_t CVA6Cfg = config_pkg::cva6_cfg_empty,
    parameter type exception_t = logic,
    parameter type scoreboard_entry_t = logic,
    parameter type lsu_ctrl_t = logic,
    parameter type bp_resolve_t = logic,
    parameter type rvfi_probes_instr_t = logic,
    parameter type rvfi_probes_csr_t = logic,
    parameter type rvfi_probes_t = logic

) (

    input logic                                  clk_i,
    input logic                                  rst_ni,
    input logic                                  flush_i,
    input logic [CVA6Cfg.NrIssuePorts-1:0]       issue_instr_ack_i,
    input logic [CVA6Cfg.NrIssuePorts-1:0]       fetch_entry_valid_i,
    input logic [CVA6Cfg.NrIssuePorts-1:0][31:0] instruction_i,
    input logic [CVA6Cfg.NrIssuePorts-1:0]       is_compressed_i,

    input logic [CVA6Cfg.NrIssuePorts-1 : 0][CVA6Cfg.TRANS_ID_BITS-1:0] issue_pointer_i,
    input logic [ CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.TRANS_ID_BITS-1:0] commit_pointer_i,

    input logic flush_unissued_instr_i,
    input logic [CVA6Cfg.NrIssuePorts-1:0] decoded_instr_valid_i,
    input logic [CVA6Cfg.NrIssuePorts-1:0] decoded_instr_ack_i,
    input scoreboard_entry_t [CVA6Cfg.NrIssuePorts-1:0] decoded_instr_i,

    input logic [CVA6Cfg.NrIssuePorts-1:0][CVA6Cfg.XLEN-1:0] rs1_i,
    input logic [CVA6Cfg.NrIssuePorts-1:0][CVA6Cfg.XLEN-1:0] rs2_i,

    input scoreboard_entry_t [CVA6Cfg.NrCommitPorts-1:0] commit_instr_i,
    input logic [CVA6Cfg.NrCommitPorts-1:0] commit_drop_i,
    input exception_t ex_commit_i,
    input riscv::priv_lvl_t priv_lvl_i,

    input lsu_ctrl_t                                               lsu_ctrl_i,
    input logic      [    CVA6Cfg.NrWbPorts-1:0][CVA6Cfg.XLEN-1:0] wbdata_i,
    input logic      [CVA6Cfg.NrCommitPorts-1:0]                   commit_ack_i,
    input logic      [         CVA6Cfg.PLEN-1:0]                   mem_paddr_i,
    input logic                                                    debug_mode_i,
    input logic      [CVA6Cfg.NrCommitPorts-1:0][CVA6Cfg.XLEN-1:0] wdata_i,

    input rvfi_probes_csr_t csr_i,
    input logic [1:0] irq_i,
    input bp_resolve_t resolved_branch_i,
    input [CVA6Cfg.TRANS_ID_BITS-1:0] flu_trans_id_ex_id_i,

    output rvfi_probes_t rvfi_probes_o
);


  rvfi_probes_csr_t   csr;
  rvfi_probes_instr_t instr;
  logic [63:0] trace_cycle_q;
  logic [63:0] next_trace_token_q;
  logic [63:0] issue_start_cycles_q [CVA6Cfg.NR_SB_ENTRIES];
  logic [63:0] issue_trace_tokens_q [CVA6Cfg.NR_SB_ENTRIES];
  logic issue_start_valid_q [CVA6Cfg.NR_SB_ENTRIES];
  logic macro_trace_active_q;
  logic [63:0] macro_trace_start_cycle_q;
  logic [63:0] macro_trace_token_q;

  always_comb begin
    csr = '0;
    instr = '0;

    instr.flush = flush_i;
    instr.issue_instr_ack = issue_instr_ack_i;
    instr.fetch_entry_valid = fetch_entry_valid_i;
    instr.instruction = instruction_i;
    instr.is_compressed = is_compressed_i;

    instr.issue_pointer = issue_pointer_i;

    instr.flush_unissued_instr = flush_unissued_instr_i;
    instr.decoded_instr_valid = decoded_instr_valid_i;
    instr.decoded_instr_ack = decoded_instr_ack_i;

    instr.rs1 = rs1_i;
    instr.rs2 = rs2_i;

    instr.ex_commit_cause = ex_commit_i.cause;
    instr.ex_commit_valid = ex_commit_i.valid;
    if (CVA6Cfg.TvalEn) begin
      instr.tval = ex_commit_i.tval;
    end else begin
      instr.tval = '0;
    end

    instr.priv_lvl = priv_lvl_i;

    instr.lsu_ctrl_vaddr = lsu_ctrl_i.vaddr;
    instr.lsu_ctrl_fu = lsu_ctrl_i.fu;
    instr.lsu_ctrl_be = lsu_ctrl_i.be;
    instr.lsu_ctrl_trans_id = lsu_ctrl_i.trans_id;

    instr.wbdata = wbdata_i;
    instr.mem_paddr = mem_paddr_i;
    instr.debug_mode = debug_mode_i;

    instr.commit_pointer = commit_pointer_i;

    for (int i = 0; i < CVA6Cfg.NrCommitPorts; i++) begin
      instr.commit_instr_pc[i] = commit_instr_i[i].pc;
      instr.commit_instr_op[i] = commit_instr_i[i].op;
      instr.commit_instr_rs1[i] = commit_instr_i[i].rs1;
      instr.commit_instr_rs2[i] = commit_instr_i[i].rs2;
      instr.commit_instr_rd[i] = commit_instr_i[i].rd;
      instr.commit_instr_result[i] = commit_instr_i[i].result;
      instr.commit_instr_valid[i] = commit_instr_i[i].valid;
    end

    instr.commit_drop = commit_drop_i;
    instr.commit_ack = commit_ack_i;
    instr.wdata = wdata_i;

    instr.branch_valid = resolved_branch_i.valid;
    instr.is_taken = resolved_branch_i.is_taken;
    instr.branch_trans_id = flu_trans_id_ex_id_i;

    for (int i = 0; i < CVA6Cfg.NrCommitPorts; i++) begin
      instr.commit_start_cycle[i] = issue_start_cycles_q[commit_pointer_i[i]];
      instr.commit_end_cycle[i] = trace_cycle_q + 64'd1;
      instr.commit_trace_token[i] = issue_trace_tokens_q[commit_pointer_i[i]];
      instr.commit_start_valid[i] = issue_start_valid_q[commit_pointer_i[i]];
    end

    csr = csr_i;
    csr.mip_q = csr_i.mip_q | ({{CVA6Cfg.XLEN - 1{1'b0}}, CVA6Cfg.RVS && irq_i[1]} << riscv::IRQ_S_EXT);

  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      trace_cycle_q <= 64'd0;
      next_trace_token_q <= 64'd0;
      macro_trace_active_q <= 1'b0;
      macro_trace_start_cycle_q <= 64'd0;
      macro_trace_token_q <= 64'd0;
      for (int entry = 0; entry < CVA6Cfg.NR_SB_ENTRIES; entry++) begin
        issue_start_cycles_q[entry] <= 64'd0;
        issue_trace_tokens_q[entry] <= 64'd0;
        issue_start_valid_q[entry] <= 1'b0;
      end
    end else begin
      trace_cycle_q <= trace_cycle_q + 64'd1;
      // Invalidate a sidecar exactly when its architectural macro commits.
      // Allocation below has priority if an implementation ever reuses the
      // same scoreboard slot on the same edge.
      for (int commit = 0; commit < CVA6Cfg.NrCommitPorts; commit++) begin
        if (commit_ack_i[commit]) begin
          issue_start_valid_q[commit_pointer_i[commit]] <= 1'b0;
        end
      end
      if (flush_i) begin
        // A frontend redirect only squashes younger entries; older scoreboard
        // entries remain live and must keep their allocation metadata.  Stale
        // slots are harmless because allocation overwrites the whole sidecar.
        macro_trace_active_q <= 1'b0;
      end else begin
        logic [63:0] next_trace_token;
        logic macro_trace_active;
        logic [63:0] macro_trace_start_cycle;
        logic [63:0] macro_trace_token;

        next_trace_token = next_trace_token_q;
        macro_trace_active = macro_trace_active_q;
        macro_trace_start_cycle = macro_trace_start_cycle_q;
        macro_trace_token = macro_trace_token_q;

        for (int issue = 0; issue < CVA6Cfg.NrIssuePorts; issue++) begin
          if (decoded_instr_valid_i[issue] && decoded_instr_ack_i[issue] && !flush_unissued_instr_i) begin
            logic [63:0] allocated_start_cycle;
            logic [63:0] allocated_token;

            if (CVA6Cfg.RVZCMP && decoded_instr_i[issue].is_macro_instr && macro_trace_active) begin
              allocated_start_cycle = macro_trace_start_cycle;
              allocated_token = macro_trace_token;
            end else begin
              allocated_start_cycle = trace_cycle_q + 64'd1;
              allocated_token = next_trace_token;
              next_trace_token = next_trace_token + 64'd1;
              if (CVA6Cfg.RVZCMP && decoded_instr_i[issue].is_macro_instr) begin
                macro_trace_start_cycle = allocated_start_cycle;
                macro_trace_token = allocated_token;
                macro_trace_active = 1'b1;
              end
            end

            issue_start_cycles_q[issue_pointer_i[issue]] <= allocated_start_cycle;
            issue_trace_tokens_q[issue_pointer_i[issue]] <= allocated_token;
            issue_start_valid_q[issue_pointer_i[issue]] <= 1'b1;

            if (CVA6Cfg.RVZCMP && decoded_instr_i[issue].is_macro_instr &&
                decoded_instr_i[issue].is_last_macro_instr) begin
              macro_trace_active = 1'b0;
            end
          end
        end

        next_trace_token_q <= next_trace_token;
        macro_trace_active_q <= macro_trace_active;
        macro_trace_start_cycle_q <= macro_trace_start_cycle;
        macro_trace_token_q <= macro_trace_token;
      end
    end
  end


  always_comb begin
    rvfi_probes_o = '0;

    if ($bits(rvfi_probes_o.instr) == $bits(instr)) begin
      rvfi_probes_o.instr = instr;
    end

    if ($bits(rvfi_probes_o.csr) == $bits(csr)) begin
      rvfi_probes_o.csr = csr;
    end

  end


endmodule
