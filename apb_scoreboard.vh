class apb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(apb_scoreboard)

    uvm_analysis_imp #(apb_seq_item, apb_scoreboard) item_export;

    bit [31:0] ref_mem [bit [31:0]];

    int unsigned wr_count;
    int unsigned rd_count;
    int unsigned match_count;
    int unsigned mismatch_count;

    function new(string name = "apb_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        item_export = new("item_export", this);
    endfunction

    function void write(apb_seq_item t);
        bit [31:0] expected;
        if (t.write) begin
            ref_mem[t.addr] = t.wdata;
            wr_count++;
        end else begin
            rd_count++;
            expected = ref_mem.exists(t.addr) ? ref_mem[t.addr] : 32'h0;
            if (t.rdata === expected) begin
                match_count++;
                `uvm_info("SCB", $sformatf("MATCH   addr=%0h data=%0h", t.addr, t.rdata), UVM_MEDIUM)
            end else begin
                mismatch_count++;
                `uvm_error("SCB", $sformatf("MISMATCH addr=%0h got=%0h expected=%0h",
                                            t.addr, t.rdata, expected))
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SCB", "==================================================", UVM_LOW)
        `uvm_info("SCB", $sformatf("Writes=%0d  Reads=%0d  Matches=%0d  Mismatches=%0d",
                                   wr_count, rd_count, match_count, mismatch_count), UVM_LOW)
        if (mismatch_count == 0 && rd_count > 0)
            `uvm_info("SCB", "SCOREBOARD RESULT: PASSED", UVM_LOW)
        else
            `uvm_info("SCB", "SCOREBOARD RESULT: FAILED", UVM_LOW)
        `uvm_info("SCB", "==================================================", UVM_LOW)
    endfunction

endclass