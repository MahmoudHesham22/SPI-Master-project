//------------------------------------------------------------------------------
// Title      : SPI Master Project
// Project    : SPI Master
// File       : spi_driver.sv
//------------------------------------------------------------------------------
// Description: This file contains the implementation of the SPI driver class, which is responsible for driving the SPI signals based on the sequence items received from the sequencer. The driver interacts with the SPI
//              slave interface to perform the necessary operations for the SPI communication.
//------------------------------------------------------------------------------

package drive;
    import uvm_pkg::*;
    import cfg::*;
    import sequence_item::*;
    `include "uvm_macros.svh"
    class Spi_driver extends uvm_driver#(seq_item);
    `uvm_component_utils(Spi_driver)
    parameter testcases = 20000;
    seq_item item;
    virtual Spi_slave_inter Spi_slave_test_vif;
        
    function new(string name="Spi_driver",uvm_component parent = null);
            super.new(name,parent);
    endfunction //new()
    
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
    endfunction 
        task run_phase (uvm_phase phase);
            super.run_phase(phase);
            forever begin
                item = seq_item::type_id::create("item");
                seq_item_port.get_next_item(item);
                Spi_slave_test_vif.SS_n = item.SS_n;
                Spi_slave_test_vif.rst_n = item.rst_n;
                Spi_slave_test_vif.tx_valid = item.tx_valid;
                Spi_slave_test_vif.MOSI = item.MOSI;
                Spi_slave_test_vif.tx_data = item.tx_data;
                @(negedge Spi_slave_test_vif.clk);
                seq_item_port.item_done();
            end
        endtask //run_phase
    endclass //className extends superClass
endpackage
