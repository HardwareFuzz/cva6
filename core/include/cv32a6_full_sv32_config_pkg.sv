// Copyright 2024 OpenHW Group
//
// Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
// You may obtain a copy of the License at https://solderpad.org/licenses/
//
// Original Author: CVA6 Project
//
// Description: Full-featured 32-bit CVA6 configuration with Sv32 MMU
//              This configuration enables all major RISC-V extensions for 32-bit systems

package cva6_config_pkg;

  localparam CVA6ConfigXlen = 32;

  // Floating Point Extensions
  // Note: RV32 can support RVF (single-precision, 32-bit), but NOT RVD (double-precision, 64-bit)
  // because RVD requires FLen=64 > XLEN=32, which causes hardware generation issues
  localparam CVA6ConfigRVF = 1;  // Single-precision floating-point (32-bit)
  localparam CVA6ConfigRVD = 0;  // Double-precision NOT supported in RV32
  localparam CVA6ConfigF16En = 0;  // Half-precision (disabled for compatibility)
  localparam CVA6ConfigF16AltEn = 0;  // Alternative half-precision (disabled)
  localparam CVA6ConfigF8En = 0;  // 8-bit floating-point (disabled)
  localparam CVA6ConfigFVecEn = 0;  // Vector floating-point (disabled)

  // Extension Enable Flags
  localparam CVA6ConfigCvxifEn = 1;  // CV-X-IF coprocessor interface
  localparam CVA6ConfigCExtEn = 1;  // Compressed instructions (C)
  localparam CVA6ConfigZcbExtEn = 1;  // Code-size reduction (Zcb)
  localparam CVA6ConfigZcmpExtEn = 1;  // Push/pop & double move (Zcmp)
  localparam CVA6ConfigAExtEn = 1;  // Atomic instructions (A)
  localparam CVA6ConfigHExtEn = 0;  // Hypervisor (H) - disabled for 32-bit as it requires 64-bit
  localparam CVA6ConfigBExtEn = 1;  // Bit manipulation (B)
  localparam CVA6ConfigVExtEn = 0;  // Vector extension (V) - can be enabled if needed
  localparam CVA6ConfigRVZiCond = 1;  // Integer conditional operations

  // AXI Parameters
  localparam CVA6ConfigAxiIdWidth = 4;
  localparam CVA6ConfigAxiAddrWidth = 64;  // 64-bit address bus even for 32-bit core
  localparam CVA6ConfigAxiDataWidth = 64;
  localparam CVA6ConfigFetchUserEn = 0;
  localparam CVA6ConfigFetchUserWidth = CVA6ConfigXlen;
  localparam CVA6ConfigDataUserEn = 0;
  localparam CVA6ConfigDataUserWidth = CVA6ConfigXlen;

  // Cache Configuration (larger caches for full-featured config)
  localparam CVA6ConfigIcacheByteSize = 16384;  // 16KB I-cache
  localparam CVA6ConfigIcacheSetAssoc = 4;  // 4-way set associative
  localparam CVA6ConfigIcacheLineWidth = 128;
  localparam CVA6ConfigDcacheByteSize = 32768;  // 32KB D-cache
  localparam CVA6ConfigDcacheSetAssoc = 8;  // 8-way set associative
  localparam CVA6ConfigDcacheLineWidth = 128;

  localparam CVA6ConfigDcacheFlushOnFence = 1'b0;
  localparam CVA6ConfigDcacheInvalidateOnFlush = 1'b0;

  localparam CVA6ConfigDcacheIdWidth = 1;
  localparam CVA6ConfigMemTidWidth = 2;

  localparam CVA6ConfigWtDcacheWbufDepth = 8;

  // Scoreboard and Pipeline Configuration
  localparam CVA6ConfigNrScoreboardEntries = 8;

  localparam CVA6ConfigNrLoadPipeRegs = 1;
  localparam CVA6ConfigNrStorePipeRegs = 0;
  localparam CVA6ConfigNrLoadBufEntries = 2;

  // Branch Prediction Configuration
  localparam CVA6ConfigRASDepth = 2;
  localparam CVA6ConfigBTBEntries = 32;
  localparam CVA6ConfigBHTEntries = 128;

  // Exception Handling
  localparam CVA6ConfigTvalEn = 1;

  // PMP Configuration
  localparam CVA6ConfigNrPMPEntries = 8;

  // Performance Counters
  localparam CVA6ConfigPerfCounterEn = 1;

  // Cache Type: Write-through cache
  localparam config_pkg::cache_type_t CVA6ConfigDcacheType = config_pkg::WT;

  // MMU: Enabled with Sv32 for 32-bit
  localparam CVA6ConfigMmuPresent = 1;

  // RVFI Trace Support
  localparam CVA6ConfigRvfiTrace = 1;

  localparam config_pkg::cva6_user_cfg_t cva6_cfg = '{
      // Base Architecture
      XLEN: unsigned'(CVA6ConfigXlen),
      VLEN: unsigned'(32),  // Virtual address length for 32-bit (Sv32)
      
      // FPGA Configuration
      FpgaEn: bit'(0),  // Set to 1 for FPGA targets
      FpgaAlteraEn: bit'(0),  // Set to 1 for Altera FPGAs
      TechnoCut: bit'(0),
      
      // Superscalar Configuration
      SuperscalarEn: bit'(0),
      ALUBypass: bit'(0),
      NrCommitPorts: unsigned'(2),
      
      // AXI Configuration
      AxiAddrWidth: unsigned'(CVA6ConfigAxiAddrWidth),
      AxiDataWidth: unsigned'(CVA6ConfigAxiDataWidth),
      AxiIdWidth: unsigned'(CVA6ConfigAxiIdWidth),
      AxiUserWidth: unsigned'(CVA6ConfigDataUserWidth),
      MemTidWidth: unsigned'(CVA6ConfigMemTidWidth),
      NrLoadBufEntries: unsigned'(CVA6ConfigNrLoadBufEntries),
      
      // ISA Extensions - Floating Point
      RVF: bit'(CVA6ConfigRVF),
      RVD: bit'(CVA6ConfigRVD),
      XF16: bit'(CVA6ConfigF16En),
      XF16ALT: bit'(CVA6ConfigF16AltEn),
      XF8: bit'(CVA6ConfigF8En),
      
      // ISA Extensions - Standard
      RVA: bit'(CVA6ConfigAExtEn),
      RVB: bit'(CVA6ConfigBExtEn),
      ZKN: bit'(1),  // Cryptography NIST
      RVV: bit'(CVA6ConfigVExtEn),
      RVC: bit'(CVA6ConfigCExtEn),
      RVH: bit'(CVA6ConfigHExtEn),
      
      // ISA Extensions - Code Size Reduction
      RVZCB: bit'(CVA6ConfigZcbExtEn),
      RVZCMT: bit'(1),  // Table jump
      RVZCMP: bit'(CVA6ConfigZcmpExtEn),
      
      // Non-standard Extensions
      XFVec: bit'(CVA6ConfigFVecEn),
      
      // Coprocessor Interface
      CvxifEn: bit'(CVA6ConfigCvxifEn),
      CoproType: config_pkg::COPRO_NONE,
      
      // Other Extensions
      RVZiCond: bit'(CVA6ConfigRVZiCond),
      RVZicntr: bit'(1),  // Standard counters
      RVZihpm: bit'(1),  // Hardware performance counters
      
      // Scoreboard
      NrScoreboardEntries: unsigned'(CVA6ConfigNrScoreboardEntries),
      
      // Performance Counters
      PerfCounterEn: bit'(CVA6ConfigPerfCounterEn),
      
      // MMU and Privilege Levels
      MmuPresent: bit'(CVA6ConfigMmuPresent),
      RVS: bit'(1),  // Supervisor mode
      RVU: bit'(1),  // User mode
      
      // Interrupts
      SoftwareInterruptEn: bit'(1),
      
      // Debug and Exception Addresses
      HaltAddress: 64'h800,
      ExceptionAddress: 64'h808,
      
      // Branch Prediction
      RASDepth: unsigned'(CVA6ConfigRASDepth),
      BTBEntries: unsigned'(CVA6ConfigBTBEntries),
      BPType: config_pkg::BHT,
      BHTEntries: unsigned'(CVA6ConfigBHTEntries),
      BHTHist: unsigned'(3),
      
      // Debug Module
      DmBaseAddress: 64'h0,
      
      // Exception Handling
      TvalEn: bit'(CVA6ConfigTvalEn),
      DirectVecOnly: bit'(0),
      
      // Physical Memory Protection (PMP)
      NrPMPEntries: unsigned'(CVA6ConfigNrPMPEntries),
      PMPCfgRstVal: {64{64'h0}},
      PMPAddrRstVal: {64{64'h0}},
      PMPEntryReadOnly: 64'd0,
      PMPNapotEn: bit'(1),
      
      // NoC Type
      NOCType: config_pkg::NOC_TYPE_AXI4_ATOP,
      
      // Physical Memory Attributes (PMA)
      NrNonIdempotentRules: unsigned'(2),
      NonIdempotentAddrBase: 1024'({64'b0, 64'b0}),
      NonIdempotentLength: 1024'({64'b0, 64'b0}),
      
      NrExecuteRegionRules: unsigned'(3),
      ExecuteRegionAddrBase: 1024'({64'h8000_0000, 64'h1_0000, 64'h0}),
      ExecuteRegionLength: 1024'({64'h40000000, 64'h10000, 64'h1000}),
      
      NrCachedRegionRules: unsigned'(1),
      CachedRegionAddrBase: 1024'({64'h8000_0000}),
      CachedRegionLength: 1024'({64'h40000000}),
      
      // Store Buffer
      MaxOutstandingStores: unsigned'(7),
      
      // Debug
      DebugEn: bit'(1),
      
      // AXI Burst Write
      AxiBurstWriteEn: bit'(0),
      
      // Instruction Cache
      IcacheByteSize: unsigned'(CVA6ConfigIcacheByteSize),
      IcacheSetAssoc: unsigned'(CVA6ConfigIcacheSetAssoc),
      IcacheLineWidth: unsigned'(CVA6ConfigIcacheLineWidth),
      
      // Data Cache
      DCacheType: CVA6ConfigDcacheType,
      DcacheByteSize: unsigned'(CVA6ConfigDcacheByteSize),
      DcacheSetAssoc: unsigned'(CVA6ConfigDcacheSetAssoc),
      DcacheLineWidth: unsigned'(CVA6ConfigDcacheLineWidth),
      DcacheFlushOnFence: unsigned'(CVA6ConfigDcacheFlushOnFence),
      DcacheInvalidateOnFlush: unsigned'(CVA6ConfigDcacheInvalidateOnFlush),
      
      // User Data
      DataUserEn: unsigned'(CVA6ConfigDataUserEn),
      WtDcacheWbufDepth: int'(CVA6ConfigWtDcacheWbufDepth),
      FetchUserWidth: unsigned'(CVA6ConfigFetchUserWidth),
      FetchUserEn: unsigned'(CVA6ConfigFetchUserEn),
      
      // TLB Configuration
      InstrTlbEntries: int'(16),
      DataTlbEntries: int'(16),
      UseSharedTlb: bit'(0),
      SharedTlbDepth: int'(64),
      
      // Pipeline Registers
      NrLoadPipeRegs: int'(CVA6ConfigNrLoadPipeRegs),
      NrStorePipeRegs: int'(CVA6ConfigNrStorePipeRegs),
      DcacheIdWidth: int'(CVA6ConfigDcacheIdWidth)
  };

endpackage
