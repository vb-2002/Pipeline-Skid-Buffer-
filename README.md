# Background 
A **skid buffer** is a a specialized pipeline element used in ready/valid handshake-based pipelined data paths to handle backpressure while maintaining high throughput and avoiding data loss. It registers the ready signal instead of allowing it to propagate combinatorially, thereby easing timing pressure on the ready path.
# pipeline_skid_buffer
Pipeline Skid Buffer functions similar to Skid Buffer, but it provides complete decoupling from Receiver by breaking ready as well as data and valid combinatorial paths, by registering both. It makes the interface fully pipelined with better timing performance.

-----------------

## 📦 Module: `pipe_skid_buffer`
This module ensures robust data transfer between upstream and downstream components, even when backpressure (i.e., `i_ready` going low) occurs mid-transaction.

### 🔧 Parameters
- `DWIDTH`: Data width (default: 8 bits)

### 🔌 Ports

#### Clock and Reset
| Signal | Direction | Description               |
|--------|-----------|---------------------------|
| clk    | input     | Clock                     |
| rstn   | input     | Active-low synchronous reset |

#### Input Interface
| Signal     | Direction | Description        |
|------------|-----------|--------------------|
| i_data     | input     | Data from upstream |
| i_valid    | input     | Valid from upstream|
| o_ready    | output    | Ready to upstream  |

#### Output Interface
| Signal     | Direction | Description         |
|------------|-----------|---------------------|
| o_data     | output    | Data to downstream  |
| o_valid    | output    | Valid to downstream |
| i_ready    | input     | Ready from downstream |

---

## ⚙️ Behavior

This skid buffer handles pipeline stalls caused by downstream backpressure. Internally, it uses:

- **data_rg1**: Holds currently valid data
- **data_rg2**: Temporarily stores old data when a stall occurs
- **2 states**: `PIPE` and `SKID`

### ⏬ Backpressure Scenario

When `i_valid=1`, `i_ready=0`, and valid data is already held in `data_rg1`, the module:

1. Moves `data_rg1` into `data_rg2`
2. Accepts new data into `data_rg1`
3. Transitions to `SKID` state, stalls upstream

---

## 🧪 Testbench

A testbench is included (`pipe_skid_buffer_tb.sv`) to simulate:

- Normal transmission
- Backpressure handling
- Recovery from SKID state

### ✅ How to Run

Using any SystemVerilog simulator (like [Icarus Verilog],VCS etc.:

```bash
# Example using VCS
vcs pipe_skid_buffer.sv pipe_skid_buffer_tb.sv -full64 -sverilog -debug_access+all
./simv

```
### 🔍 Sample Output
```bash
[45000] Received data: 0
[65000] Received data: 1
[85000] Received data: 2
[125000] Received data: 99
[145000] Received data: 4
[165000] Received data: 5
[185000] Received data: 6
Test complete: sent=7 received=7
testbench.sv:95: $finish called at 275000 (1ps)
```
