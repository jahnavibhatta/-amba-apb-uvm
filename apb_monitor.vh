class apb_monitor extends uvm_monitor;

    `uvm_component_utils(apb_monitor)

    virtual apb_if vif;
    uvm_analysis_port #(apb_seq_item) ap;

    function new(string name = "apb_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Virtual interface not set for apb_monitor")
    endfunction

    task run_phase(uvm_phase phase);
        apb_seq_item item;
        forever begin
            @(vif.mon_cb);
            if (vif.PRESETn === 1'b1 &&
                vif.mon_cb.PSEL && vif.mon_cb.PENABLE && vif.mon_cb.PREADY) begin
                item       = apb_seq_item::type_id::create("mon_item");
                item.addr  = vif.mon_cb.PADDR;
                item.write = vif.mon_cb.PWRITE;
                if (item.write) item.wdata = vif.mon_cb.PWDATA;
                else            item.rdata = vif.mon_cb.PRDATA;
                `uvm_info("MON", $sformatf("Collected: %s addr=%0h wdata=%0h rdata=%0h",
                          item.write ? "WRITE" : "READ ", item.addr, item.wdata, item.rdata),
                          UVM_MEDIUM)
                ap.write(item);
            end
        end
    endtask

endclass