# 📘 Events to APB Converter

## 📌 Overview

This module implements an **event-driven AMBA APB transaction generator** that converts asynchronous event signals into valid **APB write transactions** targeting a single slave.

The design monitors three independent event inputs and generates a corresponding APB write transaction whenever any event is asserted. Each event maps to a dedicated address, and the write data represents the **number of occurrences of that event since the last successful write transaction for that event type**.

The module strictly follows the **AMBA APB protocol timing requirements**, including setup, enable, and ready phases.

---

## ⚙️ Key Features

* Converts event inputs into **APB write transactions**
* Supports three independent event sources:

  * `event_a_i`
  * `event_b_i`
  * `event_c_i`
* Each event maps to a fixed APB address:

  * Event A → `0xABBA0000`
  * Event B → `0xBAFF0000`
  * Event C → `0xCAFE0000`
* **Write-only APB transactions (no read interface)**
* `pwdata_o` carries **event occurrence count since last write**
* Ensures **APB protocol compliance (setup → enable → ready handshake)**
* Guarantees **no back-to-back transactions (mandatory idle cycle between transfers)**
* Handles `pready_i` latency up to 10 cycles
* Supports mutually exclusive event assertion per cycle
* Fully synchronous design with:

  * Positive edge-triggered flops
  * Asynchronous reset (if applicable)
* Fairness-aware event handling (no starvation; bounded pending events per input)
