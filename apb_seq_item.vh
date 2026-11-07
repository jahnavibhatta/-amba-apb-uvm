class apb_seq_item extends uvm_sequence_item;

    rand bit [31:0] addr;
    rand bit [31:0] wdata;
    rand bit        write;     // 1 = write, 0 = read
         bit [31:0] rdata;

    constraint c_addr { addr < 256; }

    `uvm_object_utils_begin(apb_seq_item)
        `uvm_field_int(addr,  UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(write, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "apb_seq_item");
        super.new(name);
    endfunction

endclass