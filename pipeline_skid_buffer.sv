module pipe_skid_buffer #(   
   // Global Parameters   
   parameter DWIDTH    =  8                                // Data width                                                          
) 
(
   input  logic                clk             ,           // Clock
   input  logic                rstn            ,           // Active-low synchronous reset
   
   // Input Interface   
   input  logic [DWIDTH-1 : 0] i_data          ,           // Data in
   input  logic                i_valid         ,           // Data in valid
   output logic                o_ready         ,           // Ready out
   
   // Output Interface
   output logic [DWIDTH-1 : 0] o_data          ,            // Data out
   output logic                o_valid         ,            // Data out valid
   input  logic                i_ready                      // Ready in
) ;


logic [DWIDTH-1 : 0] data_rg1, data_rg2;
logic valid_rg, valid_rg_nxt;

typedef enum logic  {PIPE, SKID}  state_t;
state_t state;
state_t state_nxt;

always_ff @(posedge clk or negedge rstn) begin 
if (!rstn) begin 
    state <= PIPE;
    valid_rg <= 0;
end
else begin 
    state <= state_nxt;
    valid_rg <= valid_rg_nxt;
end 
end

always_ff @(posedge clk or negedge rstn)
if (i_valid && o_ready) data_rg1 <= i_data;

always_ff @(posedge clk or negedge rstn)
if (i_valid && valid_rg && (!i_ready) && (state == PIPE)) data_rg2 <= data_rg1; // this condition means that data buffer 1 is full, and downstream is not accpeting data but upstream wants to write more data
//we will store data in rg1 to rg2, write incoming data into rg1 and stall pipeline until rg2 is cleared. 


always_comb begin
    state_nxt = state;
    o_data= data_rg1;
    valid_rg_nxt = valid_rg;
    case (state)
    PIPE : begin
        o_data= data_rg1;
        valid_rg_nxt = i_valid;
        if (i_valid && valid_rg && (!i_ready)) state_nxt = SKID;
    end
    SKID: begin
        o_data= data_rg2;
        if (i_ready) state_nxt = PIPE;
    end
    endcase
end

assign o_valid = valid_rg;
assign o_ready = (state == PIPE);

endmodule