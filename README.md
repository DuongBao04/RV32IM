# RV32_IM
**Overall Architecture**
------------------------

**Single-Cycle RV32IM:**The single-cycle architecture executes every instruction completely within one clock cycle. Fetch, decode, execute, memory access, and write-back all occur in one long combinational path. This design is simple, easy to understand, and suitable for teaching or small embedded systems, but the cycle time must be long enough to accommodate the slowest instruction.

**Pipeline RV32IM:**The pipelined architecture divides instruction execution into multiple stages (IF, ID, EX, MEM, WB). Different instructions execute in different stages at the same time, increasing instruction throughput. It requires additional hardware like pipeline registers, hazard detection units, and forwarding logic to maintain correctness.



## Resource Utilization (RV32IM)
| Resource Type | Single Cycle | Pipelined |
| :--- | :---: | :---: |
| **Slice LUTs** | 8,546 | 5,012 |
| **Flip-Flops (FF)** | 1,052 | 2,446 |
