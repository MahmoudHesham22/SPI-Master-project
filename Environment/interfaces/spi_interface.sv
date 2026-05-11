interface spi_if (input logic PCLK);

    logic      PRESETn;
    logic        SCLK;          
    logic        MOSI;          
    logic        MISO;          
    logic [3:0]  SS_n;          
    logic        IRQ;           

    modport DUT  (input PCLK, PRESETn, MISO,
                     output SCLK, MOSI, SS_n, IRQ);

    modport monitor (input PCLK, PRESETn, SCLK, MOSI, MISO, SS_n, IRQ);

    modport driver (input PCLK, PRESETn,
                     output SCLK, MOSI, SS_n, IRQ);

endinterface : spi_if
