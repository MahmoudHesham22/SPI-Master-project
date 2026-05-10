
//------------------------------------------------------------------------------
// Title      : SPI Master Project
// Project    : SPI Master
// File       : apb_driver.sv
//------------------------------------------------------------------------------
// Description: This file contains the implementation of the APB driver class, which is responsible for driving the APB signals based on the sequence items received from the sequencer. The driver interacts with the APB
//              slave interface to perform the necessary operations for the APB communication.
//------------------------------------------------------------------------------

package drive;
    import uvm_pkg::*;
    import cfg::*;
    import sequence_item::*;
    `include "uvm_macros.svh"
    class Apb_driver extends uvm_driver#(seq_item);
    `uvm_component_utils(Apb_driver)
    parameter testcases = 20000;
    seq_item item;
    virtual Apb_slave_inter Apb_slave_test_vif;
        
    function new(string name="Apb_driver",uvm_component parent = null);
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
                Apb_slave_test_vif.PSEL = item.PSEL;
                Apb_slave_test_vif.PENABLE = item.PENABLE;
                Apb_slave_test_vif.PWRITE = item.PWRITE;
                Apb_slave_test_vif.PADDR = item.PADDR;
                Apb_slave_test_vif.PWDATA = item.PWDATA;
                @(negedge Apb_slave_test_vif.clk);
                seq_item_port.item_done();
            end
        endtask //run_phase
    endclass //className extends superClass
endpackage
