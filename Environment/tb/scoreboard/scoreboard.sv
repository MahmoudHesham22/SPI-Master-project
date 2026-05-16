//------------------------------------------------------------------------------
//
// CLASS: scoreboard
//
// The scoreboard class provides a parameterized base implementation for 
// scoreboards in UVM testbenches. It includes analysis ports for receiving
// input and output transactions, automatic comparison capabilities using
// uvm_comparer, and built-in error tracking with summary reporting.
//
//------------------------------------------------------------------------------

class spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_scoreboard)
    // Analysis infrastructure
    // (Export <-> FIFO) for transactions fed to the block as controllers transactions
    uvm_analysis_export #(apb_sequence_item)apb_sb_export; 
    uvm_tlm_analysis_fifo #(apb_sequence_item) fifo_apb;
    // (Export <-> FIFO) for transactions fed to the block as controllers transactions
    uvm_analysis_export #(spi_sequence_item) spi_sb_export;
    uvm_tlm_analysis_fifo #(spi_sequence_item) fifo_spi;


    // Transaction handles
    // Transactions received by the driver and the monitor
    apb_sequence_item item_apb;
    spi_sequence_item item_spi;
    spi_ref_model    model;
    // Statistics tracking
    // Error and correct counts
    bit match;
    int error_count, correct_count;
    int total_count = correct_count + error_count;
    real pass_rate;
    string summary_msg;
    string status_msg;
    uvm_severity test_severity;

    

    // Function: new
    //
    // Creates a new scoreboard instance with the given name and parent.

function new(string name = "spi_scoreboard", uvm_component parent = null);
    super.new(name, parent);
endfunction : new

// build_phase
// -----------

function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info("build_phase", "Building scoreboard and creating analysis ports and FIFOs", UVM_LOW)
    apb_sb_export = new("apb_sb_export", this);
    fifo_apb = new("fifo_apb", this);
    spi_sb_export = new("spi_sb_export", this);
    fifo_spi = new("fifo_spi", this);
    model = new();
    `uvm_info("build_phase", "finished building scoreboard", UVM_LOW)
endfunction : build_phase

// connect_phase
// -------------

function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("connect_phase", "Connecting scoreboard analysis ports to FIFOs", UVM_LOW)
    apb_sb_export.connect(fifo_apb.analysis_export);
    spi_sb_export.connect(fifo_spi.analysis_export);
endfunction : connect_phase

// report_phase
// ------------

function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    // Calculate totals
    total_count = correct_count + error_count;
    pass_rate = (total_count > 0) ? (real'(correct_count) / real'(total_count)) * 100.0 : 0.0;
    
    // Determine test status
    if (error_count == 0) begin
        status_msg = "PASSED";
        test_severity = UVM_INFO;
    end else begin
        status_msg = "FAILED";
        test_severity = UVM_ERROR;
    end
    
    // Build summary message
    summary_msg = {
        "\n",
        "===============================================\n",
        $sformatf("     TEST SUMMARY REPORT - %s\n", this.get_name()),
        "===============================================\n",
        $sformatf("Test Status       : %s\n", status_msg),
        $sformatf("Total Transactions: %0d\n", total_count),
        $sformatf("Correct Count     : %0d\n", correct_count),
        $sformatf("Error Count       : %0d\n", error_count),
        $sformatf("Pass Rate         : %.2f%%\n", pass_rate),
        "===============================================\n"
    };
    
    // Display summary
    `uvm_info("TEST_SUMMARY", summary_msg, UVM_LOW)
    
    // Final status message
    if (error_count == 0) begin
        `uvm_info("TEST_RESULT", "*** TEST PASSED ***", UVM_LOW)
    end else begin
        `uvm_error("TEST_RESULT", $sformatf("*** TEST FAILED with %0d errors ***", error_count))
    end
endfunction : report_phase

// compare
// -------

// compare
// -------

task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    fork
        // Process 1: APB Checking
        forever begin
            fifo_apb.get(item_apb);
            match = model.check_apb(item_apb); // Calls the new check_apb function
            
            if (match) correct_count++;
            else error_count++;
                
            `uvm_info("scoreboard_apb", $sformatf("APB Transaction Result: %s, Total Correct: %0d, Total Errors: %0d", 
                     (match ? "MATCH" : "MISMATCH"), correct_count, error_count), UVM_LOW)
        end
        
        // Process 2: SPI Checking
        forever begin
            fifo_spi.get(item_spi);
            match = model.check_spi(item_spi); // Calls the new check_spi function
            
            if (match) correct_count++;
            else error_count++;
                
            `uvm_info("scoreboard_spi", $sformatf("SPI Transaction Result: %s, Total Correct: %0d, Total Errors: %0d", 
                     (match ? "MATCH" : "MISMATCH"), correct_count, error_count), UVM_LOW)
        end
    join_none
endtask : run_phase

endclass : spi_scoreboard