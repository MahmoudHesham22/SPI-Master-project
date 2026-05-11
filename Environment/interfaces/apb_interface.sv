interface apb_if (input logic PCLK);
    
    logic       PRESETn;
    logic        PSEL;
    logic        PENABLE;
    logic        PWRITE;
    logic [7:0]  PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;
    logic        PSLVERR;

                     
    modport DUT (input PCLK, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA, 
                     output PRDATA, PREADY, PSLVERR);

    modport monitor (input PCLK, PRESETn, PSEL, PENABLE, PWRITE, PADDR, PWDATA, PRDATA, PREADY, PSLVERR);

    modport driver (input PCLK, PRESETn,
                     output PSEL, PENABLE, PWRITE, PADDR, PWDATA);
                     
endinterface : apb_if
