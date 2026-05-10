class apb_monitor extends uvm_monitor;
     `uvm_component_utils(apb_monitor)
    seq_item item;
    virtual apb_interface apb_test_vif;
    uvm_analysis_port #(seq_item) mon_ap;
       
    function new(string name = "apb_monitor",uvm_component parent = null);
            super.new(name,parent);
    endfunction //new()
        
    function void build_phase (uvm_phase phase);
            super.build_phase(phase);
            mon_ap=new("mon_ap",this);
    endfunction 
    
    task  run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            item = seq_item::type_id::create("item");
            @(negedge apb_test_vif.clk);
            item.PSEL = apb_test_vif.PSEL;
            item.PENABLE = apb_test_vif.PENABLE;
            item.PWRITE = apb_test_vif.PWRITE;
            item.PADDR = apb_test_vif.PADDR;
            item.PWDATA = apb_test_vif.PWDATA;
            item.PRDATA = apb_test_vif.PRDATA;
            mon_ap.write(item);
        end
    endtask //
endclass //className extends superClass
