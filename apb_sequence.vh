class apb_wr_rd_seq extends uvm_sequence #(apb_seq_item);

    `uvm_object_utils(apb_wr_rd_seq)

    int unsigned num_pairs = 20;

    function new(string name = "apb_wr_rd_seq");
        super.new(name);
    endfunction

    task body();
        apb_seq_item wr_item;
        apb_seq_item rd_item;
        bit [31:0]   saved_addr;

        repeat (num_pairs) begin
            wr_item = apb_seq_item::type_id::create("wr_item");
            start_item(wr_item);
            if (!wr_item.randomize() with { write == 1'b1; })
                `uvm_error("SEQ", "Randomization failed for write item")
            saved_addr = wr_item.addr;
            finish_item(wr_item);

            rd_item = apb_seq_item::type_id::create("rd_item");
            start_item(rd_item);
            if (!rd_item.randomize() with { write == 1'b0; addr == saved_addr; })
                `uvm_error("SEQ", "Randomization failed for read item")
            finish_item(rd_item);
        end
    endtask

endclass


class apb_rand_seq extends uvm_sequence #(apb_seq_item);

    `uvm_object_utils(apb_rand_seq)

    int unsigned num_items = 40;

    function new(string name = "apb_rand_seq");
        super.new(name);
    endfunction

    task body();
        apb_seq_item item;
        repeat (num_items) begin
            item = apb_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_error("SEQ", "Randomization failed")
            finish_item(item);
        end
    endtask

endclass