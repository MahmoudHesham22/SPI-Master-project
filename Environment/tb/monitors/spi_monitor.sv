//------------------------------------------------------------------------------
// Title      : SPI Master Project
// Project    : SPI Master
// File       : spi_monitor.sv
//------------------------------------------------------------------------------
// Description: This file contains the implementation of the SPI monitor class, which is responsible for monitoring the SPI signals based on the sequence items received from the sequencer. The monitor interacts with the SPI
//              interface to perform the necessary operations for the SPI communication using clocking blocks for synchronization.
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
    
    task  run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            item = spi_sequence_item::type_id::create("item");
            
            // Sample signals through clocking block
            @(spi_vif.cb_mon);
            item.SCLK = spi_vif.cb_mon.SCLK;
            item.MOSI = spi_vif.cb_mon.MOSI;
            item.MISO = spi_vif.cb_mon.MISO;
            item.SS_n = spi_vif.cb_mon.SS_n;
            item.IRQ = spi_vif.cb_mon.IRQ;

            spi_mon_ap.write(item);
        end
    endtask //
endclass //className extends superClass

 
