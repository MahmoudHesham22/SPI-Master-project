class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)
    spi_sequence_item item;
    virtual spi_if spi_vif;
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
            @(negedge spi_vif.clk);
            item.SS_n = spi_vif.SS_n;
            item.rst_n = spi_vif.rst_n;
            item.tx_valid = spi_vif.tx_valid;
            item.MOSI = spi_vif.MOSI;
            item.tx_data = spi_vif.tx_data;
            spi_mon_ap.write(item);
        end
    endtask //
endclass //className extends superClass
