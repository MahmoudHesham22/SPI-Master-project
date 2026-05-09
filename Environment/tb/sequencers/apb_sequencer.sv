
package seqr_pac;
import uvm_pkg::*;
`include "uvm_macros.svh"
import sequence_item::*;
class apb_sequencer extends uvm_sequencer #(seq_item);
    `uvm_component_utils(apb_sequencer)

    function new(string name = "apb_sequencer" , uvm_component parent = null);
        super.new(name,parent);
    endfunction

endclass 
    
endpackage
