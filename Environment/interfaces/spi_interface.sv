interface spi_if (input logic PCLK);

    logic        SCLK;          
    logic        MOSI;          
    logic        MISO;          
    logic [3:0]  SS_n;          
    logic        IRQ;           

    modport master  (input PCLK, MISO,
                     output SCLK, MOSI, SS_n, IRQ);

    modport slave   (input PCLK, SCLK, MOSI, SS_n, IRQ,
                     output MISO);

    modport monitor (input PCLK, SCLK, MOSI, MISO, SS_n, IRQ);

endinterface : spi_if
