// ****************************************************************************
// *                                                                          *
// * Copyright (c) 2014-2015 Synopsys Inc. All rights reserved.               *
// *                                                                          *
// * Synopsys Proprietary and Confidential. This file contains confidential   *
// * information and the trade secrets of Synopsys Inc. Use, disclosure, or   *
// * reproduction is prohibited without the prior express written permission  *
// * of Synopsys, Inc.                                                        *
// *                                                                          *
// * Synopsys, Inc.                                                           *
// * 700 East Middlefield Road                                                *
// * Mountain View, California 94043                                          *
// * (800) 541-7737                                                           *
// *                                                                          *
// ****************************************************************************


module spi_master_top;
    import uvm_pkg::*;
    import spi_master_pkg::*;
    `include "uvm_macros.svh"
    // Clock Generation
    bit clk ;
    initial begin
        forever begin
            #1;
            clk=!clk;
        end
    end
   // instantite dut & interfaces
    spi_if spi_if(clk);
    apb_if apb_if(clk);

    spi_master(.PRESETn(spi_if.PRESETn),
               .SCLK(spi_if.SCLK),
               .MOSI(spi_if.MOSI),
               .MISO(spi_if.MISO),
               .SS_n(spi_if.SS_n),
               .IRQ(spi_if.IRQ),
               .PSEL(apb_if.PSEL),
               .PENABLE(apb_if.PENABLE),
               .PWRITE(apb_if.PWRITE),
               .PADDR(apb_if.PADDR),
               .PWDATA(apb_if.PWDATA),
               .PRDATA(apb_if.PRDATA),
               .PREADY(apb_if.PREADY),
               .PSLVERR(apb_if.PSLVERR)
    );

    initial begin

        uvm_config_db#(virtual spi_if)::set(null,"uvm_test_top", "SPI_IF",   spi_if  );
        uvm_config_db#(virtual apb_if)::set(null,"uvm_test_top", "APB_IF",   apb_if  );

        run_test("ACTIVE_test");
    end
endmodule : spi_master_top