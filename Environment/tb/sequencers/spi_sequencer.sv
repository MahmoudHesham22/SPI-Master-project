package seqr_pac;
import uvm_pkg::*;
`include "uvm_macros.svh"
import sequence_item::*;
class spi_sequencer extends uvm_sequencer #(seq_item);
    `uvm_component_utils(spi_sequencer)

    function new(string name = "spi_sequencer" , uvm_component parent = null);
        super.new(name,parent);
    endfunction

endclass 
    
endpackage
