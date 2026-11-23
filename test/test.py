# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

VALID_SEGMENTS = {
    0b0000110,  # 1
    0b1011011,  # 2
    0b1001111,  # 3
    0b1100110,  # 4
    0b1101101,  # 5
    0b1111101,  # 6
}

@cocotb.test()
async def test_dice_roller(dut):
    dut._log.info("Start Chiptune Dice Roller simulation")

    # Set the clock period to 100 ns (10 MHz)
    clock = Clock(dut.clk, 100, units="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 5)

    # Hold roll button (ui_in[0] = 1)
    dut._log.info("Holding roll button")
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 100_000)

    # Release roll button and wait for exponential slowdown + victory chime
    dut._log.info("Releasing roll button")
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 3_500_000)

    final_seg = int(dut.uo_out.value) & 0x7F
    dut._log.info(f"Final 7-segment pattern: {bin(final_seg)}")
    assert final_seg in VALID_SEGMENTS, f"Invalid dice output: {bin(final_seg)}"
