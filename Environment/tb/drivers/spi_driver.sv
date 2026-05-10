//------------------------------------------------------------------------------
// Title      : SPI Master Project
// Project    : SPI Master
// File       : spi_driver.sv
//------------------------------------------------------------------------------
// Description: This file contains the implementation of the SPI driver class, which is responsible for driving the SPI signals based on the sequence items received from the sequencer. The driver interacts with the SPI
//              slave interface to perform the necessary operations for the SPI communication.
//------------------------------------------------------------------------------
class spi_driver extends uvm_driver#(spi_sequence_item);
    `uvm_component_utils(spi_driver)
    spi_sequence_item spi_item;
    virtual spi__if spi_vif;
        
    function new(string name="spi_driver",uvm_component parent = null);
        super.new(name,parent);
    endfunction //new()
    
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
    endfunction 
    
    task run_phase (uvm_phase phase);
            super.run_phase(phase);
            forever begin
                spi_item = spi_sequence_item::type_id::create("spi_item");
                seq_item_port.get_next_item(spi_item);
                spi_vif.SS_n = spi_item.SS_n;
                spi_vif.rst_n = spi_item.rst_n;
                spi_vif.tx_valid = spi_item.tx_valid;
                spi_vif.MOSI = spi_item.MOSI;
                spi_vif.tx_data = spi_item.tx_data;
                @(negedge spi_vif.clk);
                seq_item_port.item_done();
            end
    endtask //run_phase
endclass //className extends superClass
