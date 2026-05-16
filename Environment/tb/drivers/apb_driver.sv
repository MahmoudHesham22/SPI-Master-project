
//------------------------------------------------------------------------------
// Title      : SPI Master Project
// Project    : SPI Master
// File       : apb_driver.sv
//------------------------------------------------------------------------------
// Description: This file contains the implementation of the APB driver class, which is responsible for driving the APB signals based on the sequence items received from the sequencer. The driver interacts with the APB
//              interface to perform the necessary operations for the APB communication using clocking blocks for synchronization.
//------------------------------------------------------------------------------
class apb_driver extends uvm_driver#(apb_sequence_item);
    `uvm_component_utils(apb_driver)
    apb_sequence_item apb_item;
    virtual apb_if.driver apb_vif;
        
    function new(string name="apb_driver",uvm_component parent = null);
        super.new(name,parent);
    endfunction //new()
    
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
    endfunction 

    task run_phase (uvm_phase phase);
                super.run_phase(phase);
                forever begin
                    apb_item = apb_sequence_item::type_id::create("apb_item");
                    seq_item_port.get_next_item(apb_item);
                    
                    // Drive signals through clocking block
                    apb_vif.cb_master.PSEL <= apb_item.PSEL;
                    apb_vif.cb_master.PRESETn <= apb_item.PRESETn;
                    apb_vif.cb_master.PENABLE <= apb_item.PENABLE;
                    apb_vif.cb_master.PWRITE <= apb_item.PWRITE;
                    apb_vif.cb_master.PADDR <= apb_item.PADDR;
                    apb_vif.cb_master.PWDATA <= apb_item.PWDATA;
                    
                    // Wait for clock edge - clocking block handles timing
                    @(apb_vif.cb_master);
                    
                    // ADD THIS LINE: Capture the read data and send it back to the sequence
                    apb_item.PRDATA = apb_vif.cb_master.PRDATA; 
                    
                    seq_item_port.item_done();
                end
            endtask //run_phase
    endclass //className extends superClass
