<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the default width is 300 px.

-->

## How it works

This project implements a hardware pseudo-random dice roller with exponential slowdown and chiptune square-wave sound effects on a 10 MHz clock:

- **Input Synchronization:** A 2-stage D flip-flop synchronizer debounces and synchronizes the external pushbutton (`ui_in[0]`) to the 10 MHz system clock (`clk`) to prevent metastability.
- **Pseudo-Random Number Generation:** An 8-bit Linear Feedback Shift Register (LFSR) with polynomial $x^8 + x^6 + x^5 + x^4 + 1$ cycles through 255 states every clock tick. The bottom 3 bits are mapped without division into integers `1` through `6`.
- **Exponential Slowdown & FSM:** Holding `ui_in[0]` high spins the dice rapidly. Releasing `ui_in[0]` enters a slowdown state where the step delay increases by 25% per tick (`step_threshold + (step_threshold >> 2)`) until halting on a final roll.
- **Chiptune Audio & 7-Segment Output:** A programmable square-wave tone generator drives a piezo buzzer on `uo_out[7]` with pitch-dropping roll blips and an ~880 Hz landing chime, while a combinational decoder drives a 7-segment display on `uo_out[6:0]`.

## How to test

1. Supply a 10 MHz clock on `clk` and pulse `rst_n` low (`0`) then high (`1`) to initialize the LFSR seed and state machine.
2. Pull `ui_in[0]` high (`1`) to start rolling the dice; verify that `uo_out[6:0]` cycles through valid 7-segment digits (`1`–`6`) and `uo_out[7]` toggles to produce audio blips.
3. Release `ui_in[0]` to `0` and wait ~3.5 million clock cycles (~350 ms) for the roll rate to slow down exponentially, play the high-pitched landing chime, and settle on a steady 7-segment digit between `1` and `6`.

## External hardware

- **Pushbutton:** Connected between `3.3V` and `ui_in[0]` (with a pull-down resistor if not internally pulled down).
- **7-Segment Display (Common Cathode):** Segments `a`–`g` connected to `uo_out[0]` through `uo_out[6]` via current-limiting resistors (e.g., 330 Ω).
- **Piezo Buzzer:** Connected between `uo_out[7]` and `GND`.
