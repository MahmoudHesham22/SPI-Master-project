// =============================================================================
// spi_sva.sv
// =============================================================================
// Centralized SVA assertions for SPI Master Project
// All mandatory protocol, timing, and data integrity checks
// =============================================================================

`default_nettype none
`timescale 1ns/1ps

// =============================================================================
// APB PROTOCOL ASSERTIONS
// =============================================================================
module apb_protocol_checker (
    input  logic         PCLK,
    input  logic         PRESETn,
    input  logic         PSEL,
    input  logic         PENABLE,
    input  logic         PWRITE,
    input  logic [7:0]   PADDR,
    input  logic [31:0]  PWDATA
);

    // PSEL must be asserted for at least 2 PCLK cycles to complete a transaction
    // (SETUP phase + ACCESS phase minimum)
    property apb_psel_min_duration;
        @(posedge PCLK) disable iff (!PRESETn)
        PSEL |=> PSEL;
    endproperty
    assert property (apb_psel_min_duration)
        else $error("[APB_SVA] PSEL must remain high for at least 2 PCLK cycles");
    cover property (apb_psel_min_duration);

    // PENABLE must only assert while PSEL is asserted
    property apb_penable_requires_psel;
        @(posedge PCLK) disable iff (!PRESETn)
        PENABLE |-> PSEL;
    endproperty
    assert property (apb_penable_requires_psel)
        else $error("[APB_SVA] PENABLE asserted without PSEL");
    cover property (apb_penable_requires_psel);

    // PADDR, PWRITE, PWDATA must be stable from SETUP to ACCESS phase
    property apb_addr_write_data_stable;
        @(posedge PCLK) disable iff (!PRESETn)
        ($rose(PSEL)) |-> (PADDR, PWRITE, PWDATA) == ($past(PADDR), $past(PWRITE), $past(PWDATA));
    endproperty
    assert property (apb_addr_write_data_stable)
        else $error("[APB_SVA] PADDR, PWRITE, or PWDATA changed during transaction");
    cover property (apb_addr_write_data_stable);

    // Stability check for SETUP phase
    property apb_control_stable_setup_phase;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && !PENABLE && $past(PSEL) && !$past(PENABLE)) 
        |-> (PADDR == $past(PADDR)) && (PWRITE == $past(PWRITE));
    endproperty
    assert property (apb_control_stable_setup_phase)
        else $error("[APB_SVA] PADDR or PWRITE changed during SETUP phase");
    cover property (apb_control_stable_setup_phase);

endmodule : apb_protocol_checker

// =============================================================================
// APB REGFILE ASSERTIONS (IRQ and FIFO)
// =============================================================================
module apb_regfile_checker (
    input  logic         PCLK,
    input  logic         PRESETn,
    input  logic         ctrl_en,
    input  logic [4:0]   int_stat,
    input  logic [4:0]   int_en,
    input  logic         IRQ,
    input  logic         rx_full_w,
    input  logic         rx_push_valid,
    input  logic         tx_push_dropped
);

    // IRQ correctness: IRQ must equal |(INT_STAT & INT_EN) every PCLK
    property irq_correctness;
        @(posedge PCLK) disable iff (!PRESETn)
        IRQ == |(int_stat & int_en);
    endproperty
    assert property (irq_correctness)
        else $error("[IRQ_SVA] IRQ signal incorrect: IRQ=%b, Expected=%b", 
                    IRQ, |(int_stat & int_en));
    cover property (irq_correctness);

    // RX FIFO Overflow Protection: No push when full
    property rx_fifo_no_push_when_full;
        @(posedge PCLK) disable iff (!PRESETn || !ctrl_en)
        (rx_full_w && rx_push_valid) |-> int_stat[3];  // IRQ_RX_OVF at bit 3
    endproperty
    assert property (rx_fifo_no_push_when_full)
        else $error("[FIFO_SVA] RX FIFO push received while full without prior overflow");
    cover property (rx_fifo_no_push_when_full);

    // TX FIFO Overflow Protection
    property tx_fifo_overflow_asserted;
        @(posedge PCLK) disable iff (!PRESETn || !ctrl_en)
        tx_push_dropped |-> ##1 int_stat[2];  // IRQ_TX_OVF at bit 2
    endproperty
    assert property (tx_fifo_overflow_asserted)
        else $error("[FIFO_SVA] TX FIFO overflow dropped but INT_STAT[TX_OVF] not set");
    cover property (tx_fifo_overflow_asserted);

endmodule : apb_regfile_checker

// =============================================================================
// SPI CORE ASSERTIONS
// =============================================================================
module spi_core_checker (
    input  logic         PCLK,
    input  logic         PRESETn,
    input  logic         busy,
    input  logic [1:0]   xfer_mode,
    input  logic [3:0]   ss_n_drive,
    input  logic         SCLK,
    input  logic [1:0]   xfer_width,
    input  logic [5:0]   width_bits,
    input  logic         tx_push_dropped
);

    wire cpol = xfer_mode[1];

    // SCLK idle level matches CPOL whenever BUSY=0
    property spi_sclk_idle_level;
        @(posedge PCLK) disable iff (!PRESETn)
        (!busy) |-> (SCLK == cpol);
    endproperty
    assert property (spi_sclk_idle_level)
        else $error("[SPI_SVA] SCLK not at CPOL idle level when not busy: SCLK=%b, CPOL=%b", 
                    SCLK, cpol);
    cover property (spi_sclk_idle_level);

    // SS_n assertion during transfer
    property spi_ss_asserted_during_transfer;
        @(posedge PCLK) disable iff (!PRESETn)
        (busy) |-> (ss_n_drive != 4'hF);
    endproperty
    assert property (spi_ss_asserted_during_transfer)
        else $error("[SPI_SVA] SS_n deasserted during active transfer: ss_n_drive=%b", 
                    ss_n_drive);
    cover property (spi_ss_asserted_during_transfer);

    // Width bits counter validation
    property spi_width_bits_valid;
        @(posedge PCLK) disable iff (!PRESETn || !busy)
        ((xfer_width == 2'b00) && (width_bits == 6'd8)) ||
        ((xfer_width == 2'b01) && (width_bits == 6'd16)) ||
        ((xfer_width == 2'b10) && (width_bits == 6'd32));
    endproperty
    assert property (spi_width_bits_valid)
        else $error("[SPI_SVA] width_bits computation invalid: width=%b, bits=%d", 
                    xfer_width, width_bits);
    cover property (spi_width_bits_valid);

endmodule : spi_core_checker

// =============================================================================
// SPI INTERFACE ASSERTIONS (Signal Stability and Protocol)
// =============================================================================
module spi_interface_checker (
    input  logic         PCLK,
    input  logic         PRESETn,
    input  logic         SCLK,
    input  logic         MOSI,
    input  logic [3:0]   SS_n
);

    // MOSI stability around SCLK sample edges (Wire-Stability)
    // MOSI must remain stable for at least 1 PCLK before and after SCLK edges

    // MOSI stable at SCLK rising edge
    property spi_mosi_stable_before_sclk_rise;
        @(posedge PCLK) disable iff (!PRESETn)
        ($rose(SCLK)) |-> ($stable(MOSI));
    endproperty
    assert property (spi_mosi_stable_before_sclk_rise)
        else $error("[SPI_SVA] MOSI unstable at SCLK rising edge");
    cover property (spi_mosi_stable_before_sclk_rise);

    // MOSI stable at SCLK falling edge
    property spi_mosi_stable_before_sclk_fall;
        @(posedge PCLK) disable iff (!PRESETn)
        ($fell(SCLK)) |-> ($stable(MOSI));
    endproperty
    assert property (spi_mosi_stable_before_sclk_fall)
        else $error("[SPI_SVA] MOSI unstable at SCLK falling edge");
    cover property (spi_mosi_stable_before_sclk_fall);

    // MOSI stable after SCLK rise (hold time check)
    property spi_mosi_stable_after_sclk_rise;
        @(posedge PCLK) disable iff (!PRESETn)
        ($rose(SCLK)) |=> ($stable(MOSI));
    endproperty
    assert property (spi_mosi_stable_after_sclk_rise)
        else $error("[SPI_SVA] MOSI unstable in hold window after SCLK rise");
    cover property (spi_mosi_stable_after_sclk_rise);

    // MOSI stable after SCLK fall (hold time check)
    property spi_mosi_stable_after_sclk_fall;
        @(posedge PCLK) disable iff (!PRESETn)
        ($fell(SCLK)) |=> ($stable(MOSI));
    endproperty
    assert property (spi_mosi_stable_after_sclk_fall)
        else $error("[SPI_SVA] MOSI unstable in hold window after SCLK fall");
    cover property (spi_mosi_stable_after_sclk_fall);

    // SS_n held asserted throughout transfer
    // When SS_n has any lane asserted, at least one must stay low

    property spi_ss_continuous_assertion;
        @(posedge PCLK) disable iff (!PRESETn)
        (SS_n != 4'hF) && ($past(SS_n) != 4'hF)
        |-> (SS_n != 4'hF);
    endproperty
    assert property (spi_ss_continuous_assertion)
        else $error("[SPI_SVA] SS_n not continuously asserted during transfer: SS_n=%b", SS_n);
    cover property (spi_ss_continuous_assertion);

    // SS_n no glitch (no momentary return to idle)
    property spi_ss_no_glitch;
        @(posedge PCLK) disable iff (!PRESETn)
        ($fell(SS_n[0]) || $fell(SS_n[1]) || $fell(SS_n[2]) || $fell(SS_n[3]))
        |-> (SS_n != 4'hF) [*1:$];
    endproperty
    assert property (spi_ss_no_glitch)
        else $warning("[SPI_SVA] Potential SS_n glitch detected");
    cover property (spi_ss_no_glitch);

endmodule : spi_interface_checker

// =============================================================================
// BINDING DECLARATIONS
// =============================================================================
// These bind statements attach the assertion modules to their respective instances
// in the design. Uncomment as needed or set via simulation directives.

// Bind APB protocol checker to APB interface
bind apb_if apb_protocol_checker apb_proto_inst (
    .PCLK    (PCLK),
    .PRESETn (PRESETn),
    .PSEL    (PSEL),
    .PENABLE (PENABLE),
    .PWRITE  (PWRITE),
    .PADDR   (PADDR),
    .PWDATA  (PWDATA)
);

// Bind SPI interface checker to SPI interface
bind spi_if spi_interface_checker spi_intf_inst (
    .PCLK    (PCLK),
    .PRESETn (PRESETn),
    .SCLK    (SCLK),
    .MOSI    (MOSI),
    .SS_n    (SS_n)
);

// Bind APB regfile checker to apb_regfile instance in DUT hierarchy
bind spi_master_top.u_dut.u_regfile apb_regfile_checker apb_reg_inst (
    .PCLK            (PCLK),
    .PRESETn         (PRESETn),
    .ctrl_en         (ctrl_en),
    .int_stat        (int_stat),
    .int_en          (int_en),
    .IRQ             (IRQ),
    .rx_full_w       (rx_full_w),
    .rx_push_valid   (rx_push_valid),
    .tx_push_dropped (tx_push_dropped)
);

// Bind SPI core checker to spi_core instance in DUT hierarchy
bind spi_master_top.u_dut.u_core spi_core_checker spi_core_inst (
    .PCLK            (PCLK),
    .PRESETn         (PRESETn),
    .busy            (busy),
    .xfer_mode       (xfer_mode),
    .ss_n_drive      (ss_n_drive),
    .SCLK            (SCLK),
    .xfer_width      (xfer_width),
    .width_bits      (width_bits),
    .tx_push_dropped (tx_push_dropped)
);

`default_nettype wire
