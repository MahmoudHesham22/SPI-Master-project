//------------------------------------------------------------------------------
// Title      : SPI Master Project
// Project    : SPI Master
// File       : spi_monitor.sv
//------------------------------------------------------------------------------
// Description: This file contains the implementation of the SPI monitor class, which is responsible for monitoring the SPI signals based on the sequence items received from the sequencer. The monitor interacts with the SPI
//               interface to perform the necessary operations for the SPI communication using clocking blocks for synchronization.
//------------------------------------------------------------------------------

class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)
    spi_sequence_item item;
    virtual spi_if.monitor spi_vif;
    uvm_analysis_port #(spi_sequence_item) spi_mon_ap;
    
    function new(string name = "spi_monitor",uvm_component parent = null);
        super.new(name,parent);
    endfunction //new()
        
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        spi_mon_ap=new("spi_mon_ap",this);
    endfunction 
    
    task run_phase(uvm_phase phase);
            logic [3:0] last_ss;
            logic       last_irq;
            
            super.run_phase(phase);
            
            // Initialize tracking variables
            @(spi_vif.cb_mon);
            last_ss  = spi_vif.cb_mon.SS_n;
            last_irq = spi_vif.cb_mon.IRQ;

            forever begin
                @(spi_vif.cb_mon);
                
                // ADD THIS IF STATEMENT: Only capture on SS_n or IRQ changes
                if (spi_vif.cb_mon.SS_n !== last_ss || spi_vif.cb_mon.IRQ !== last_irq) begin
                    item = spi_sequence_item::type_id::create("item");
                    
                    item.SCLK = spi_vif.cb_mon.SCLK;
                    item.MOSI = spi_vif.cb_mon.MOSI;
                    item.MISO = spi_vif.cb_mon.MISO;
                    item.SS_n = spi_vif.cb_mon.SS_n;
                    item.IRQ  = spi_vif.cb_mon.IRQ;

                    spi_mon_ap.write(item);
                    
                    // Update tracking variables
                    last_ss  = spi_vif.cb_mon.SS_n;
                    last_irq = spi_vif.cb_mon.IRQ;
                end
            end
        endtask
endclass //className extends superClass

 