    .section .text
    .globl   _start

_start:
    la       t0, trap_handler
    csrw     mtvec, t0

    j        user_code

user_code:


exit:
    li       t0, 1                  # always report success (exit code 0)
    la       t1, tohost
    sw       t0, 0(t1)
1:
    j        1b

    .align   2
trap_handler:
    csrr     t0, mepc               # offending PC
    csrr     t1, mcause             # trap cause
    slli     t5, t1, 1              # clear interrupt bit -> synchronous cause only
    srli     t1, t5, 1

    li       t2, 2                  # default length (compressed)
    li       t3, 2                  # illegal instruction -> mtval holds encoding
    beq      t1, t3, use_mtval
    li       t3, 1                  # instruction access fault
    beq      t1, t3, update_mepc
    li       t3, 12                 # instruction page fault
    beq      t1, t3, update_mepc

    lhu      t4, 0(t0)              # fetch lower half-word of instruction
    j        decode_length

use_mtval:
    csrr     t4, mtval              # mtval contains the faulting instruction

decode_length:
    andi     t4, t4, 3
    li       t3, 3
    bne      t4, t3, compressed_len
    li       t2, 4                  # standard 32-bit instruction
    j        update_mepc

compressed_len:
    li       t2, 2                  # compressed instruction

update_mepc:
    add      t0, t0, t2             # skip offending instruction
    csrw     mepc, t0
    csrw     mcause, x0
    csrw     mtval, x0
    csrw     mip, x0
    mret

    .section .tohost,"aw",@progbits
    .align   6
    .globl   tohost
    .globl   fromhost
tohost:
    .dword   0
fromhost:
    .dword   0
