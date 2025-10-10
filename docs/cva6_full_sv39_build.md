# CVA6 构建与修改说明

## 构建准备
- 安装依赖：`cmake (>= 3.14)`、`help2man`、`device-tree-compiler`，以及 Python 打包工具用于 `verif/sim/dv/requirements.txt`。
- 安装 RISC-V 交叉编译链，并设置环境变量 `RISCV=/path/to/toolchain`（建议使用仓库提供的 `util/toolchain-builder` 自动脚本）。
- 可选：通过 `NUM_JOBS=<并行数>` 控制 `make` 的并行度。

## 仓库初始化
```sh
git clone https://github.com/openhwgroup/cva6.git
cd cva6
git submodule update --init --recursive
```

## 构建 Verilator 模型
我们新增了 `cv64a6_full_sv39` 硬件配置（见 `Bender.yml:47` 以及 `core/include/cv64a6_full_sv39_config_pkg.sv:1`）。要在 Verilator 构建中启用该配置，需要在执行 `make` 时显式指定 `target`（或等效的 `TARGET_CFG`）：
```sh
make verilate target=cv64a6_full_sv39
```
命令会生成带有 DPI ELF 装载器的仿真可执行体 `work-ver/Variane_testharness`。首次运行会触发完整编译，后续如需更新可再次调用同一命令。

若不显式指定 `target`，构建将沿用默认的 `cv64a6_imafdc_sv39` 配置，因此无法加载我们新增的 `cv64a6_full_sv39` 参数。

## `example_skip` 快速验证
目录 `example_skip/` 提供了一个跳过异常指令的最小示例：
1. 使用 `example_skip/Makefile` 编译 `skip_trap.elf`（脚本会自动调用）。
2. 运行脚本演示：
   ```sh
   ./example_skip/run_sim.sh
   ```
   - 若未设置 `RISCV`，脚本会直接报错提醒。
   - 脚本会自动构建 Verilator 模型，并借助改进后的 `elfloader` 解析 ELF 符号，获取 `tohost` 地址后再启动仿真。
   - 生成的 `trace_rvfi_hart_*.dasm`、`trace_hart_*.dasm` 与 `iti.trace` 日志默认保存在 `example_skip/logs/`，可通过环境变量 `TRACE_LOG_DIR` 覆盖。

可以通过向 `run_sim.sh` 追加 `+wave`、`+trace` 等 Verilator 参数，进一步调试。

## 主要代码改动
- **新硬件配置**：`core/include/cv64a6_full_sv39_config_pkg.sv:1` 描述了启用 F16/F8/CVXIF 等特性的 64 位 SV39 配置，并在 `Bender.yml:47` 注册。
- **构建流程**：`Makefile:681` 将 `corev_apu/tb/dpi/elfloader.cc` 纳入 Verilator 可执行体，确保默认流程即可使用改进后的加载器。
- **ELF 加载能力**：`corev_apu/tb/dpi/elfloader.cc:6` 增补 `read_section_void`、`read_symbol` 与缓存清理逻辑，支持符号解析以及重复加载。
- **示例工程**：`example_skip/` 下新增汇编程序、链接脚本与仿真脚本，展示如何触发并越过异常指令。
- **杂项**：`.gitignore:55` 新增 `iti.trace` 忽略规则，避免生成的跟踪文件误提交。

## 后续建议
- 如需切换其他硬件变体，可继续使用 `make verilate target=<目标>`。
- 运行 `example_skip/run_sim.sh` 或自定义程序前，请确认 `tohost` 符号存在于目标 ELF 中。
- 在提交前可运行 `make verilate target=cv64a6_full_sv39 NUM_JOBS=<n>` 以验证构建链路是否畅通。
