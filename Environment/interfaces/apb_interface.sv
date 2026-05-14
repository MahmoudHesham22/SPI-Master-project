`timescale 1ns/1ps

interface apb_if (PCLK);
    input logic PCLK;
    logic       PRESETn;
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [7:0]  PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        PSLVERR;

    // --------------- Driver-side clocking block ----------------------------
    clocking cb_master @(posedge PCLK);
        default input #1step output #1;
        output PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRESETn;
        input PRDATA, PREADY, PSLVERR;
    endclocking

    // --------------- Monitor-side clocking block ----------------------------
    clocking cb_monitor @(posedge PCLK);
        default input #1step;
        input PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRESETn;
        input PRDATA, PREADY, PSLVERR;
    endclocking
                     
    modport DUT (input PCLK, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA, 
                     output PRDATA, PREADY, PSLVERR);

    modport monitor (input PCLK, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY, PSLVERR,
                     clocking cb_monitor);

    modport driver (input PCLK, PRESETn,
                     output PSEL, PENABLE, PWRITE, PADDR, PWDATA,
                     clocking cb_master);
                     
endinterface : apb_if
