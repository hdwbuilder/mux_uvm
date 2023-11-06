`include "uvm_macros.svh"
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
  
  rand bit [3:0] a,b,c,d;
  rand bit [1:0] sel;
 	   bit [3:0] y;
  
  function new(string path = "transaction");
    super.new(path);
  endfunction
  
  `uvm_object_utils_begin(transaction)
  `uvm_field_int(a,UVM_DEFAULT);
  `uvm_field_int(b,UVM_DEFAULT);
  `uvm_field_int(c,UVM_DEFAULT);
  `uvm_field_int(d,UVM_DEFAULT);
  `uvm_field_int(sel,UVM_DEFAULT);
  `uvm_field_int(y,UVM_DEFAULT);
  `uvm_object_utils_end 
endclass

class generator extends uvm_sequence#(transaction);
  `uvm_object_utils(generator)
   
  function new(string path = "generator");
    super.new(path);
  endfunction
  
  transaction t;
  
  virtual task body();
    t =  transaction::type_id::create("t");
    repeat(10) begin 
      start_item(t);
      t.randomize();
      `uvm_info("GEN",$sformatf(" Data Generated : a %0d b %0d c %0d d %0d sel %0d",t.a,t.b,t.c,t.d,t.sel),UVM_NONE);
      finish_item(t);
    end 
  endtask 
  
endclass 
    
class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver)
  
  function new(string path = "generator", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  transaction t;
  virtual mux_if dif;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t =  transaction::type_id::create("t",this);
     if(!uvm_config_db#(virtual mux_if)::get(this,"","dif",dif))
          `uvm_error("DRV","Config_db issue");
  endfunction 
  
 virtual task run_phase(uvm_phase  phase);
 	forever begin
      seq_item_port.get_next_item(t);
      dif.a <= t.a;
      dif.b <= t.b;
      dif.c <= t.c;
      dif.d <= t.d;
      dif.sel <= t.sel;
      `uvm_info("DRV",$sformatf(" Data Generated : a %0d b %0d c %0d d %0d sel %0d",t.a,t.b,t.c,t.d,t.sel),UVM_NONE);
      seq_item_port.item_done();
      #10;
    end 
  endtask 
endclass 
    
class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)
  
  uvm_analysis_port#(transaction) send;
  virtual mux_if dif;
  transaction t;
  
  function new(string path = "monitor", uvm_component parent = null);
    super.new(path,parent);
    send = new("send",this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    t =  transaction::type_id::create("t",this);
    if(!uvm_config_db#(virtual mux_if)::get(this,"","dif",dif))
         `uvm_error("MON","Config_db issue");
  endfunction 
  
  virtual task run_phase(uvm_phase phase);
    forever begin
      #10;
      t.a = dif.a;
      t.b = dif.b;
      t.c = dif.c;
      t.d = dif.d;
      t.sel = dif.sel;
      t.y = dif.y;
      `uvm_info("MON",$sformatf(" DUT Response : a %0d b %0d c %0d d %0d sel %0d y %0d ",t.a,t.b,t.c,t.d,t.sel,t.y),UVM_NONE);
      send.write(t);
    end 
  endtask 
    
endclass 
     
class agent extends uvm_agent;
  `uvm_component_utils(agent)
  
  function new(string path = "agent", uvm_component parent = null);
   super.new(path,parent);
  endfunction
  
  driver d;
  monitor m;
  uvm_sequencer#(transaction) seqr;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    d = driver::type_id::create("d",this);
    m = monitor::type_id::create("m",this);
    seqr = uvm_sequencer#(transaction)::type_id::create("seqr",this);
  endfunction 
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    d.seq_item_port.connect(seqr.seq_item_export);
  endfunction 
endclass
    
class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)
  
  uvm_analysis_imp#(transaction,scoreboard)recv;  
  transaction t;
  
  function new(string path = "scoreboard", uvm_component parent = null);
    super.new(path,parent);
    recv = new("recv",this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
     t =  transaction::type_id::create("t",this);
  endfunction
  
  virtual function void write(transaction tr);
	t = tr;
    `uvm_info("SCO",$sformatf(" DUT Response : a %0d b %0d c %0d d %0d sel %0d y %0d ",t.a,t.b,t.c,t.d,t.sel,t.y),UVM_NONE);
     
    if(t.sel == 2'b00 && t.y == t.a)  
     `uvm_info("SCO","Passed",UVM_NONE)
    
    else if(t.sel == 2'b01 && t.y == t.b)
      `uvm_info("SCO","Passed",UVM_NONE)
    
    else if(t.sel == 2'b10 && t.y == t.c)
      `uvm_info("SCO","Passed",UVM_NONE)
    
    else if(t.sel == 2'b11 && t.y == t.d)
      `uvm_info("SCO","Passed",UVM_NONE)
    else  
      `uvm_info("SCO", "Failed",UVM_NONE)
  endfunction 
endclass
    
class env extends uvm_env;
  `uvm_component_utils(env)
 
  agent a;
  scoreboard s;
  
  function new(string path = "env", uvm_component parent = null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    a =  agent::type_id::create("a",this);
    s =  scoreboard::type_id::create("s",this);
  endfunction 
  
   virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
     a.m.send.connect(s.recv);
  endfunction 
  
endclass
    
class test extends uvm_test;
  `uvm_component_utils(test)
  
  
  env e;
  generator g;
  
  function new(string path = "test", uvm_component parent = null);
 	 super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e =  env::type_id::create("e",this);
    g =  generator::type_id::create("gen");
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    g.start(e.a.seqr);
    #50;
    phase.drop_objection(this);
  endtask 
endclass
         
         
module mux_tb();
  mux_if dif();
  
  mux dut (.a(dif.a),.b(dif.b),.c(dif.c),.d(dif.d),.sel(dif.sel),.y(dif.y));

  initial begin 
    uvm_config_db#(virtual mux_if)::set(null,"uvm_test_top.e.a*","dif",dif);
    run_test("test");
  end
  
  initial begin 
    $dumpfile("dump.vcd");
    $dumpvars;
  end 
endmodule 
    
    
    
    