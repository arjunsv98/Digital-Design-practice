Sequence Generator
Design the following sequence generator module:

0 → 1 → 1 → 1 → 2 → 2 → 3 → 4 → 5 → 7 → 9 → 12 → 16 → 21 → 28 → 37 → ...

Assume the sequence goes on forever until the circuit is reset. All the flops should be positive edge triggered with asynchronous resets (if any).

Interface Definition
seq_o : Sequence output on every cycle
Interface Requirements
The generator should produce output every cycle
You can assume that the sequence generator would never overflow