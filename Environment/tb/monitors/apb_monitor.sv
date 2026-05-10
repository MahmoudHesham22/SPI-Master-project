class apb_monitor extends uvm_monitor;
     `uvm_component_utils(apb_monitor)
    apb_sequence_item apb_item;
    virtual apb_if apb_vif;
    uvm_analysis_port #(apb_sequence_item) apb_mon_ap;
       
    function new(string name = "apb_monitor",uvm_component parent = null);
        super.new(name,parent);
    endfunction //new()
        
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        apb_mon_ap=new("apb_mon_ap",this);
    endfunction 
    
    task  run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            apb_item = apb_sequence_item::type_id::create("apb_item");
            @(negedge apb_vif.clk);
            apb_item.PSEL = apb_vif.PSEL;
            apb_item.PENABLE = apb_vif.PENABLE;
            apb_item.PWRITE = apb_vif.PWRITE;
            apb_item.PADDR = apb_vif.PADDR;
            apb_item.PWDATA = apb_vif.PWDATA;
            apb_item.PRDATA = apb_vif.PRDATA;
            apb_mon_ap.write(apb_item);
        end
    endtask //
endclass 
