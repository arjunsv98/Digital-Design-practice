# 📘 3-Bit Palindrome Detector (Serial Stream)

## 📌 Overview

This module implements a **3-bit palindrome detector** for a continuous stream of input bits.

A palindrome is a sequence that reads the same forward and backward. In this design, the circuit observes the **current input bit and the previous two bits**, forming a sliding 3-bit window. On every clock cycle, it checks whether this 3-bit sequence is a palindrome.

The detector operates continuously on a **bit stream**, producing an output every cycle once sufficient bits are received.

---

## ⚙️ Key Features

* Serial input stream (`x_i`) processed every clock cycle
* Detects **3-bit palindrome sequences** (e.g., `000`, `010`, `101`, `111`)
* Uses a **sliding window of 3 bits** (current + last two inputs)
* Output (`palindrome_o`) asserted when the current 3-bit sequence is a palindrome
* **Same-cycle output response** once 3 bits are available
* Minimal hardware using shift-register-style storage
* Fully synchronous design with:

  * Positive edge-triggered flops
  * Asynchronous reset
* Continuous operation with no gaps in input stream
* Output generated every cycle after initialization
