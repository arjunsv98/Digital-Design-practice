# 📘 Low Power Channel — ARM Q-Channel Quiescence Controller

## 📌 Overview
This module implements the **device side of the ARM Q-Channel protocol**, managing safe clock/power quiescence between an upstream write producer and a downstream reader.

It acts as the **negotiator** that lets an external power controller stop a block's clock without losing in-flight data. When the controller requests low power, the module flushes pending writes, confirms the datapath has drained, and only then asserts quiescence. A wakeup path lets the block request that the controller bring it back online.

The design strictly follows the **Q-Channel handshake** using `QREQn`, `QACCEPTn`, and `QACTIVE`, and guarantees **no data loss** for writes in flight during the flush window.

---

## ⚙️ Key Features
* Implements the **ARM Q-Channel quiescence handshake** (`QREQn` / `QACCEPTn` / `QACTIVE`)
* **3-state FSM**: Run → Request → Stopped
* Drains pending writes before asserting quiescence (`QACCEPTn`), so **no buffered data is stranded** when the clock is gated
* Wakeup support:
  * `if_wakeup_i` in the Stopped state raises `QACTIVE`
  * Device **requests** exit; the controller **grants** it by raising `QREQn`
* Datapath sized for **zero data loss**:
  * Skid buffer registers the valid/ready boundary into the FIFO
  * **6-deep FIFO** absorbs in-flight writes during the flush window
* Each Q-Channel output is driven directly from FSM state:
  * `QACCEPTn` asserted (low) only in Stopped
  * `QACTIVE` follows `if_wakeup_i` in Stopped (separate from `QACCEPTn`)
  * `wr_flush_o` asserted only in Request
* `QACCEPTn` **deasserted out of reset** (device starts in Run, not low power)
* Fully synchronous design with:
  * Positive edge-triggered flops
  * Asynchronous, active-high reset
* Latch-free combinational next-state logic; decoupled valid/ready (no combinational ready→ready path)

---

## 🔌 Interface

Clock / reset:
* `clk`            → clock
* `reset`          → active-high asynchronous reset

Wakeup:
* `if_wakeup_i`    → wakeup request from upstream

Write (into internal FIFO):
* `wr_valid_i`     → valid write
* `wr_payload_i[7:0]` → write data

Flush handshake to upstream:
* `wr_flush_o`     → tell upstream to stop and flush pending writes
* `wr_done_i`      → upstream reports all pending writes complete

Read (drain FIFO):
* `rd_valid_i`     → read valid
* `rd_payload_o[7:0]` → read data out

Q-Channel:
* `qreqn_i`        → quiescence request (active low)
* `qacceptn_o`     → quiescence accept (active low)
* `qactive_o`      → activity / wakeup indication (active high)

---

## 🧠 FSM Behavior

| State        | qacceptn_o | qactive_o    | wr_flush_o | Meaning                          |
|--------------|------------|--------------|------------|----------------------------------|
| RUN (s0)     | 1          | 1            | 0          | Normal traffic                   |
| REQUEST (s1) | 1          | 1            | 1          | Flushing / draining              |
| STOPPED (s2) | 0          | if_wakeup_i  | 0          | Quiescent; clock may be gated    |

Transitions:
* RUN → REQUEST     when `qreqn_i` goes low (controller requests low power)
* REQUEST → STOPPED when `wr_done_i` is high AND the FIFO has drained
* STOPPED → RUN     when `qreqn_i` goes high (controller grants return to run)

The device never wakes itself. In Stopped, a wakeup raises `QACTIVE` to ask the
controller to restore the clock; the controller responds by raising `QREQn`,
which is the authoritative signal the FSM keys on to leave low power.

---

## 🧱 Architecture

```
 wr_valid/payload        e_ready = !full       push        pop    rd_payload
 ----------------> skid buffer ----------------> FIFO (depth 6) ----------------->
                                                  |
        FSM (Run / Request / Stopped)  <----------+  fifo_empty / fifo_full
        drives wr_flush, qacceptn, qactive
```

Modules:
* `low_power_channel.sv` → top-level FSM + datapath integration
* `qs_fifo.sv`           → synchronous FIFO; parameterizable DATA_W / DEPTH; async reset; full usable capacity (extra pointer MSB distinguishes full from empty)
* `qs_skid_buffer.sv`    → single-register valid/ready skid buffer; parameterizable DATA_W

All flops are positive-edge-triggered with asynchronous reset.

---

## ✅ Verification

Simulated with Icarus Verilog (`iverilog -g2012`). Submodules verified
individually, then the full handshake end-to-end.

* FIFO: full usable capacity (holds all DEPTH entries — extra pointer bit avoids
  the lost-slot bug), correct FIFO ordering on drain, correct async reset.
* Skid buffer: lossless valid/ready handshake; combinational pass-through when empty.
* Top level: drove the complete Q-Channel sequence — writes in RUN, `QREQn` low →
  flush asserted, FIFO drained, `QACCEPTn` asserted (entered STOPPED), wakeup
  raised `QACTIVE`, controller raised `QREQn`, returned to RUN. All transitions
  and output values matched the spec.

Run:
```
iverilog -g2012 -o sim low_power_channel.sv qs_fifo.sv qs_skid_buffer.sv lpc_tb.sv
vvp sim
```

---

## 📝 Design Notes & Trade-offs

* Single-register skid buffer: lossless and decoupled (`i_ready_o` depends only
  on a register), but not full-throughput. Under continuous back-to-back traffic
  with a held entry it can insert one recovery cycle. For this use (absorbing
  occasional FIFO-full stalls during flush) that trade-off has no cost; a
  two-register version would remove it at the cost of one cycle of output latency.

* `QACCEPTn` entry waits for FIFO empty: the REQUEST → STOPPED condition is
  `wr_done_i && fifo_empty`, so quiescence is entered only after the reader has
  drained the FIFO. This guarantees no buffered data is stranded when the clock
  is gated. It assumes the reader eventually drains; if reads stall indefinitely,
  `QACCEPTn` would not assert. This matches a "drain before stop" power model.

* No backpressure on the external write port: the write interface has no
  `wr_ready`, so lossless operation relies on the FIFO depth and on `wr_flush_o`
  halting upstream before overflow — not on the skid buffer's `i_ready_o`, which
  has no upstream consumer here.

---

## 📦 Status
Designed and verified in simulation. Reset-polarity consistency and a latch-free
combinational FSM were addressed during development.
