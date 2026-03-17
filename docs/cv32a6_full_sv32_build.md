# CVA6 32-bit Full-Featured Configuration Build Guide

本文档介绍如何构建和使用 CVA6 的 32 位全功能配置 `cv32a6_full_sv32`。

## 配置概述

`cv32a6_full_sv32` 是 CVA6 的 32 位全功能硬件配置，启用了大部分 RISC-V 扩展和特性：

### 支持的扩展

#### 基础 ISA
- **RV32I**: 32-bit 基础整数指令集
- **M Extension**: 整数乘除法
- **A Extension**: 原子指令
- **C Extension**: 压缩指令（16-bit）

#### 浮点扩展
- **F Extension**: 单精度浮点（32-bit）✅
- **D Extension**: 双精度浮点（64-bit）❌ **不支持**
- **Zfh**: 半精度浮点（16-bit）❌ **不支持**
- **XF16/XF16ALT**: 非标准 16-bit 浮点 ❌ **不支持**
- **XF8**: 非标准 8-bit 浮点 ❌ **不支持**
- **XFVec**: 向量浮点 ❌ **不支持**

**重要说明**: RV32 架构限制
- RV32 的 XLEN=32，只能支持 FLen=32 的浮点配置
- RVD (双精度) 需要 FLen=64，会导致 FLen > XLEN，这在硬件生成时会出现问题
- 因此本配置仅启用 RVF (单精度浮点)，禁用所有需要 64-bit 浮点寄存器的扩展

#### 其他标准扩展
- **B Extension**: 位操作扩展
- **Zicond**: 整数条件操作
- **Zicntr**: 标准计数器（cycle, time, instret）
- **Zihpm**: 硬件性能计数器
- **ZKN**: 密码学扩展（NIST）

#### 代码大小优化扩展
- **Zcb**: 额外的压缩指令
- **Zcmp**: Push/pop 和双移动指令
- **Zcmt**: 表跳转指令

#### 特权模式
- **Machine Mode (M)**: 机器模式
- **Supervisor Mode (S)**: 监督者模式
- **User Mode (U)**: 用户模式
- **Sv32 MMU**: 32-bit 虚拟内存管理

#### 其他特性
- **CV-X-IF**: CoreV eXtension Interface（协处理器接口）
- **PMP**: 物理内存保护（8个条目）
- **性能计数器**: 启用
- **调试支持**: 完整的调试模块支持
- **RVFI Trace**: RISC-V Formal Interface 跟踪支持

### 不支持的扩展（32-bit限制）
- **H Extension (Hypervisor)**: 超级管理员扩展需要64位支持
- **V Extension (Vector)**: 向量扩展（可选，默认关闭）
- **D Extension (Double-precision FP)**: 双精度浮点需要64位浮点寄存器，与RV32冲突
- **非标准浮点扩展**: XF16, XF16ALT, XF8, XFVec 均被禁用以确保兼容性

### 硬件配置参数

#### 缓存配置
- **指令缓存**: 16KB, 4-way 组相联, 128-bit 行宽
- **数据缓存**: 32KB, 8-way 组相联, 128-bit 行宽
- **缓存类型**: Write-Through (WT)

#### 分支预测
- **RAS 深度**: 2
- **BTB 条目**: 32
- **BHT 条目**: 128
- **BHT 历史位**: 3
- **预测器类型**: Bimodal History Table (BHT)

#### 流水线配置
- **记分板条目**: 8
- **Load Pipeline 寄存器**: 1
- **Store Pipeline 寄存器**: 0
- **Load Buffer 条目**: 2
- **最大Outstanding Stores**: 7

#### TLB配置
- **指令TLB条目**: 16
- **数据TLB条目**: 16
- **共享TLB**: 否

## 构建 Verilator 模型

### 基本构建

要构建 `cv32a6_full_sv32` 配置的 Verilator 模型，执行：

```bash
make verilate target=cv32a6_full_sv32
```

该命令会：
1. 生成带有 DPI ELF 装载器的仿真可执行文件 `work-ver/Variane_testharness`
2. 首次运行会触发完整编译（可能需要较长时间）
3. 后续如需更新可再次调用同一命令

### 并行构建（加速）

使用多核并行构建：

```bash
make verilate target=cv32a6_full_sv32 NUM_JOBS=8
```

其中 `NUM_JOBS` 设置为你的 CPU 核心数。

## 运行仿真

### 使用示例程序

构建完成后，可以运行测试程序：

```bash
# 运行 RISC-V 测试套件
cd work-ver
./Variane_testharness <path-to-elf-file>
```

### 运行带跟踪的仿真

启用波形和跟踪：

```bash
./Variane_testharness +trace +wave <path-to-elf-file>
```

这将生成：
- VCD 波形文件
- RVFI 跟踪日志

### 运行示例

假设你有一个编译好的 RISC-V 32-bit ELF 程序 `hello.elf`：

```bash
cd /mnt/disk1/shared/git/cva6
make verilate target=cv32a6_full_sv32
cd work-ver
./Variane_testharness ../path/to/hello.elf
```

## 编译目标程序

### GCC 编译选项

为 `cv32a6_full_sv32` 编译程序时，推荐的 GCC 选项：

```bash
# 基础配置（RV32IMAC）
riscv32-unknown-elf-gcc -march=rv32imac -mabi=ilp32 \
    -o program.elf program.c

# 启用单精度浮点（RV32IMAFC）
riscv32-unknown-elf-gcc -march=rv32imafc -mabi=ilp32f \
    -o program.elf program.c

# 启用所有支持的扩展（注意：不包含D扩展）
riscv32-unknown-elf-gcc \
    -march=rv32imafc_zba_zbb_zbc_zbs_zbkb_zbkc_zbkx_zicond \
    -mabi=ilp32f \
    -o program.elf program.c
```

**重要提示**: 
- 使用 `rv32imafc` (包含F) 而不是 `rv32imafdc` (包含D)
- ABI 使用 `ilp32f` (单精度浮点) 而不是 `ilp32d` (双精度浮点)
- D 扩展在 RV32 上不被此配置支持

### Clang 编译选项

使用 Clang：

```bash
clang --target=riscv32 \
    -march=rv32imafdc_zba_zbb_zbc_zbs \
    -mabi=ilp32d \
    -o program.elf program.c
```

## 与 cv64a6_full_sv39 的对比

| 特性 | cv32a6_full_sv32 | cv64a6_full_sv39 |
|------|------------------|------------------|
| **XLEN** | 32-bit | 64-bit |
| **VLEN** | 32-bit | 64-bit |
| **MMU** | Sv32 (2级页表) | Sv39 (3级页表) |
| **虚拟地址空间** | 4 GB (32-bit) | 512 GB (39-bit) |
| **物理地址宽度** | 34-bit | 56-bit |
| **Hypervisor扩展** | ❌ 不支持 | ✅ 支持 |
| **其他扩展** | 基本相同 | 基本相同 |
| **缓存配置** | 相同 | 相同 |

## 验证和调试

### 查看配置

构建后可以查看实际使用的配置：

```bash
grep -A 5 "localparam CVA6Config" \
    core/include/cv32a6_full_sv32_config_pkg.sv
```

### 检查生成的 RTL

Verilator 生成的 C++ 代码位于：

```bash
ls work-ver/
```

### 常见问题

#### 1. 编译错误："XLEN mismatch"

确保你的程序是为 RV32 编译的，而不是 RV64：

```bash
riscv32-unknown-elf-objdump -f program.elf | grep "file format"
# 应该显示: elf32-littleriscv
```

#### 2. 仿真挂起

检查程序是否设置了正确的 `tohost` 地址用于退出：

```bash
riscv32-unknown-elf-nm program.elf | grep tohost
```

#### 3. 未定义指令异常

检查程序使用的扩展是否在配置中启用。

## 配置文件位置

相关的配置文件：

- **主配置**: `core/include/cv32a6_full_sv32_config_pkg.sv`
- **Bender配置**: `Bender.yml` (target: cv32a6_full_sv32)
- **Makefile**: `Makefile` (target 判断逻辑)

## 后续开发

### 自定义配置

如需修改配置，编辑 `core/include/cv32a6_full_sv32_config_pkg.sv`：

1. 修改扩展启用标志（例如启用V扩展）
2. 调整缓存大小
3. 修改分支预测器配置
4. 调整 TLB 大小

修改后重新构建：

```bash
make verilate target=cv32a6_full_sv32
```

### 添加自定义扩展

通过 CV-X-IF 接口可以添加自定义协处理器：

1. 设置 `CVA6ConfigCvxifEn = 1`（已启用）
2. 实现你的协处理器模块
3. 连接到 CVA6 的 CV-X-IF 接口

## 性能考虑

### 与 64-bit 配置对比

32-bit 配置的优势：
- **更小的寄存器文件**: 32-bit vs 64-bit
- **更小的数据路径**: 节省面积和功耗
- **更简单的 MMU**: Sv32 (2级) vs Sv39 (3级)
- **更快的编译时间**: RTL 规模较小

32-bit 配置的限制：
- **地址空间限制**: 4 GB vs 512 GB
- **无 Hypervisor 支持**: H 扩展需要 64-bit

### 适用场景

`cv32a6_full_sv32` 适用于：
- 嵌入式高性能应用
- IoT 网关设备
- 边缘计算节点
- 需要硬件浮点的实时系统
- 需要 MMU 但地址空间需求 < 4GB 的系统

## 参考资料

- [CVA6 官方文档](../../README.md)
- [RISC-V ISA 规范](https://riscv.org/technical/specifications/)
- [cv64a6_full_sv39 构建指南](./cva6_full_sv39_build.md)
- [Verilator 用户手册](https://verilator.org/guide/latest/)

## 许可证

本配置遵循 Solderpad Hardware License v2.0。详见项目根目录的 LICENSE 文件。

---

**版本**: 1.0  
**最后更新**: 2024  
**维护者**: CVA6 Community
