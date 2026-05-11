
package spi_master_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"


    // Sequence Items
    `include "sequence items/spi_sequence_item.sv"
    `include "sequence items/apb_sequence_item.sv"

    // Sequencers
    `include "sequencers/apb_sequencer.sv"
    `include "sequencers/spi_sequencer.sv"
      

    // Configurations
    `include "spi_config.sv"
    `include "apb_config.sv"
    
    // Monitors
    `include "monitors/apb_monitor.sv"
    `include "monitors/spi_monitor.sv"
    
    // Drivers
    `include "drivers/apb_driver.sv"
    `include "drivers/spi_driver.sv"

    // Agents 
    `include "agents/apb_agent.sv"
    `include "agents/spi_agent.sv"

    //reference model
    //`include "spi_reference_model.sv"


    // scoreboard
    `include "scoreboard/scoreboard.sv"

    // Environment
    `include "env.sv"
 


    //sequences

  
    
    
    // Tests
    `include "spi_test_base.sv"
    
endpackage : spi_master_pkg
