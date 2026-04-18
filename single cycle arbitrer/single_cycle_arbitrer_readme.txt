# 📘 Single Cycle Fixed-Priority Arbiter

## 📌 Overview

This module implements a **parameterized single-cycle arbiter** used to resolve simultaneous requests from multiple SoC peripherals.

The arbiter selects **exactly one winner per cycle (if any request exists)** using a **fixed priority scheme**, ensuring deterministic and conflict-free access to shared resources.

In this design, **Port[0] has the highest priority**, and priority decreases monotonically with increasing port index.

---

## ⚙️ Key Features

* Parameterized request width (`req_i`)
* **Single-cycle arbitration decision**
* One-hot encoded grant output (`gnt_o`)
* **Fixed priority scheme (Port 0 highest priority)**
* At most **one grant asserted per cycle**
* Handles multiple simultaneous requests deterministically
* Fully synchronous design with:

  * Positive edge-triggered flops (if registered version is used)
  * Asynchronous reset support (if applicable)
* Combinational priority resolution for minimum latency
* Ensures fair, predictable SoC interconnect behavior
