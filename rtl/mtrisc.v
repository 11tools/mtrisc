module mtrisc
       (
      clk,  
		rnt_p,
		pc_out,
		ram_in,
		ram_out,
		ram_wr,
		ram_addr,
	   );

input clk;
input rnt_p;
output [31:0] pc_out;
output [31:0] ram_in;
input  [31:0] ram_out;
output [31:0] ram_addr;
output ram_wr;

//reg [31:0][0] ------ DI:   data always 0x00000000
//reg [31:0}[1] ------ RX:   reg x
//reg [31:0}[2] ------ RY:   reg Y
//reg [31:0][3] ------ RZ:   reg output
//reg [31:0][4] ------ MO:   mode and status reg : idle / busy / err
reg [31:0] rn[5];


reg [31:0] pc_out;
reg [31:0] pc_in;
reg [31:0] ram_in;
reg [31:0] ram_addr1;
reg [31:0] ram_addr2;
wire fetch;

reg ram_wr;
reg [31:0] ins;
reg [31:0] stack_head;
reg [31:0] stack_ptr;


wire [7:0]  op;
wire [7:0]  r1;
wire [7:0]  r2;
wire [15:0] da;

assign op = ins[31:24];
assign r1 = ins[23:20];
assign r2 = ins[19:16];
assign da = ins[15:0];

always @( posedge clk )
begin
   if(rnt_p) 
	    begin
        pc_out <= 0;
		end
   else
	    begin
        if(pc_in > 0)
            pc_out <= pc_in;
        else
            pc_out <= pc_out +4;
	   end
end


always @( negedge clk )
begin
    fetch = 1'b1;
    ram_wr <= 1'b0;
    ram_addr1 <= pc_out;
end

always @( posedge clk )
begin
    ins <= ram_in;
end

// insru format : 32bit
// 0x-xx----xx---xx---xxxx
//     |    |    |     |
//    op    r1   r2   data
// reg index
// rx : 1
// ry : 2
// rz : 3
// pc : 4
// mo : 5
// the op is as blow

parameter NOP = 0;     // nop
parameter LDH = 1;     // ldh rn, xxxx
parameter LDL = 2;     // ldr rn, xxxx
parameter STR = 3;     // str rn, [rm]
parameter MOV = 5;     // mov rn, rm
parameter ADD = 9;     // add rn, rm
parameter DEC = 10;    // dec rn, rm
parameter MUL = 11;    // mul rn, rm
parameter DIV = 12;    // div rn, rm
parameter LSF = 13;    // lsf rn, rm
parameter RSF = 14;    // rnf rn, rm
parameter AND = 15;    // and rn, rm
parameter OR  = 16;    // or rn, rm
parameter XOR = 17;    // xor rn, rm
parameter NOT = 18;   // not rn
parameter IFEQ = 21;   // ifeq rn, rm
parameter IFNQ = 22;   // ifnq rn, rm
parameter IFLG = 23;   // iflg rn, rm
parameter IFSM = 24;   // ifsm rn, rm
parameter JPR  = 25;   // jpr rn
parameter JPD  = 26;   // jpd xxxx
parameter STACK = 28;   // stack rn
parameter PUSH  = 29;  // push rn
parameter POP  = 30;   // pop rm
parameter PUSHA = 31;   // push all
parameter POPA = 32;   // pop all


always @ (posedge clk)
begin
    fetch = 1'b0;
    case (op)
    NOP : begin end
    LDH : begin 
          case (r1)
          4'h1  :  rn[1][31:16] <= da; //ldh rx, xxxx
          4'h2  :  rn[2][31:16] <= da; //ldh ry, xxxx
          4'h3  :  rn[3][31:16] <= da; //ldh rz, xxxx
          endcase
          end
    LDL : begin
          case (r1)
          4'h1  :  rn[1][15:0] <= da;  //ldl, rx, xxx
          4'h2  :  rn[2][15:0] <= da;  //ldl, ry, xxx
          4'h3  :  rn[3][15:0] <= da;  //ldl, rz, xxx
          endcase
          end
    STR : begin
          ram_addr2 <= rn[r2];
          ram_in <= rn[r1];
          end
    MOV : begin 
          rn[r1] <= rn[r2];
          end
    ADD : begin 
          rn[3] <= rn[r1] + rn[r2];
          end
    DEC : begin 
          rn[3] <= rn[r1] - rn[r2];
          end
    MUL : begin
          rn[3] <= rn[r1] * rn[r2];
          end
    DIV : begin
          if(rn[r2] != 0) 
             rn[3] <= rn[1] / rn[2];
          else
             rn[4] <= 4'h3;   //div 0 error!
          end
    LSF : begin
          rn[3] <= rn[r1] << rn[r2];
          end
    RSF : begin
          rn[3] <= rn[r1] >> rn[r2];
          end
    AND : begin
          rn[3] <= rn[r1] & rn[r2];
          end
    OR : begin
          rn[3] <= rn[r1] | rn[r2];
         end
    XOR : begin
          rn[3] <= rn[r1] ^ rn[r2];
         end
    NOT : begin
          rn[r1] <= ~rn[r1];
         end
    IFEQ : begin
          if (rn[r1] == rn[r2])
             begin
             rn[3] <= 1;
             pc_in <= pc_in + da;
             end
          else
             rn[3] = 0;
          end
    IFNQ : begin
          if (rn[r1] != rn[r2])
             begin
             rn[3] = 1;
             pc_in <= pc_in + da;
             end
          else
             rn[3] = 0;
          end
    IFLG : begin
         if (rn[r1] > rn[r2])
            begin
            rn[3] = 1;
            pc_in <= pc_in + da;
            end
         else
           rn[3] = 0;
         end
    IFSM : begin
         if (rn[r1] < rn[r2])
            begin
            rn[3] = 1;
            pc_in <= pc_in + da;
            end
         else
           rn[3] = 0;
         end
    STACK : begin
         stack_head <= rn[r1];
         end
    PUSH  :  begin
         ram_addr2 <= stack_ptr;
         ram_in <= rn[r1];
         stack_ptr <= stack_ptr + 4;
         end
    POP : begin
         ram_addr2 <= stack_ptr;
         rn[r1] <= ram_out;
         stack_ptr <= stack_ptr - 4;
         end
    endcase

end

assign ram_addr = fetch ? ram_addr1:ram_addr2;

endmodule
