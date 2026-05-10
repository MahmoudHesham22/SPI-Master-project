interface apb_if (input logic PCLK, input logic PRESETn);

    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [7:0]  PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        PSLVERR;

    modport master  (input PCLK, PRESETn, PRDATA, PREADY, PSLVERR,
                     output PSEL, PENABLE, PWRITE, PADDR, PWDATA);
                     
    modport slave   (input PCLK, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA, 
                     output PRDATA, PREADY, PSLVERR);

    modport monitor (input PCLK, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY, PSLVERR);

endinterface : apb_if
