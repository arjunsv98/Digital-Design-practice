# 📘 Atomic 64-bit Counter (Single-Copy Atomic Read)

## 📌 Overview

This module implements a **64-bit event counter** designed for a system where the counter is accessed via a **32-bit bus**.

Since the bus width is smaller than the counter width, reading the full 64-bit value requires **two 32-bit transactions**. The design ensures these two reads are **single-copy atomic**, meaning:

> The upper and lower 32-bit values returned correspond to the **same snapshot** of the 64-bit counter, even if the counter increments in between.

---

## ⚙️ Key Features

* 64-bit counter incremented on `trig_i`
* 32-bit bus interface
* Supports **atomic 64-bit read via two 32-bit accesses**
* Simple **request-acknowledge protocol**
* Handles **back-to-back requests**
* Fully synchronous design with:

  * Positive edge-triggered flops
  * Asynchronous reset
