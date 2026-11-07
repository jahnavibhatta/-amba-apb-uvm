class apb_driver extends uvm_driver #(apb_seq_item);

    `uvm_component_utils(apb_driver)

    virtual apb_if vif;

    function new(string name = "apb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Virtual interface not set for apb_driver")
    endfunction

    task run_phase(uvm_phase phase);
        reset_signals();
        wait (vif.PRESETn === 1'b1);
        @(vif.drv_cb);
        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    task reset_signals();
        vif.drv_cb.PSEL    <= 1'b0;
        vif.drv_cb.PENABLE <= 1'b0;
        vif.drv_cb.PWRITE  <= 1'b0;
        vif.drv_cb.PADDR   <= 32'h0;
        vif.drv_cb.PWDATA  <= 32'h0;
    endtask

    task drive_transfer(apb_seq_item t);
        // SETUP phase
        @(vif.drv_cb);
        vif.drv_cb.PSEL    <= 1'b1;
        vif.drv_cb.PENABLE <= 1'b0;
        vif.drv_cb.PWRITE  <= t.write;
        vif.drv_cb.PADDR   <= t.addr;
        if (t.write) vif.drv_cb.PWDATA <= t.wdata;

        // ACCESS phase
        @(vif.drv_cb);
        vif.drv_cb.PENABLE <= 1'b1;

        // Wait for PREADY
        @(vif.drv_cb);
        while (!vif.drv_cb.PREADY) @(vif.drv_cb);

        if (!t.write) t.rdata = vif.drv_cb.PRDATA;

        // Back to IDLE
        vif.drv_cb.PSEL    <= 1'b0;
        vif.drv_cb.PENABLE <= 1'b0;
    endtask

endclass