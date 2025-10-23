make clean
make verilate target=cv64a6_full_sv39
cp ./work-ver/Variane_testharness ./build_result/cva6_rv64
make clean
make verilate target=cv32a6_full_sv32
cp ./work-ver/Variane_testharness ./build_result/cva6_rv32
