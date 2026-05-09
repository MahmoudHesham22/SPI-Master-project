
package spi_master_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

  

    // Sequence Items
    `include "sequence_items/spi_sequence_item.sv"
    `include "sequence_items/apb_sequence_item.sv"
  
    
    // Sequencers
    `include "sequencers/apb_sequencer.sv"
    `include "sequencers/spi_sequencer.sv"
    
    // Monitors
    `include "monitors/apb_monitor.sv"
    `include "monitors/Spi_monitor.sv"
    
    // Drivers
    `include "drivers/apb_driver.sv"
    `include "drivers/Spi_driver.sv"
    

    // Agents 
    `include "agents/apb_agent.sv"
    `include "agents/spi_agent.sv"

    // scoreboard
    `include "scoreboard/scoreboard.sv"

    // Environment
    `include "env.svh"
 
    
    //sequences

  
    
    
    // Tests    
    
endpackage : spi_master_pkg
