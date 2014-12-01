

module FinalProject(Clock,Stop1,Stop2,Stop3,Stop4,Resetn,SegmentDisplay1, SegmentDisplay2, SegmentDisplay3, SegmentDisplay4);
input Clock, Resetn,Stop1,Stop2,Stop3,Stop4;
output [0:6]SegmentDisplay1, SegmentDisplay2, SegmentDisplay3, SegmentDisplay4;
wire [2:0]Number, Number2, Number3, Number4;
wire output_clk;
wire Score;
wire [2:0]Number_out;
assign Score=5;


//Generate a clock with a new frequency (dependent on score)
variableClock var_clk(Clock,Score,Resetn,output_clk);

//Initialize counters
upcounter_slot num1(Clock,output_clk,Stop3,Resetn,Number);
upcounter_slot num2(Clock,output_clk,Stop2,Resetn,Number2);
upcounter_slot num3(Clock,output_clk,Stop1,Resetn,Number3);
upcounter_slot num4(Clock,output_clk,Stop0,Resetn,Number4);

//Game play
levelstate level(compare_out, Stop, Resetn, x2, x3, x4, score_count);

// Light first hex7seg
seg7 Display1(Number[2:0],SegmentDisplay1[0:6]);

//Register which segment was chosen
register reg1(Number[2:0], Stop, Number_out[2:0]);
compare comp1(Number_out[2:0], Number2[2:0],Stop, compare_out);

// Move to next segments
seg7next Display2(Number2[2:0],x2,SegmentDisplay2[0:6]);
seg7next Display3(Number3[2:0],x3,SegmentDisplay3[0:6]);
seg7next Display4(Number4[2:0],x4,SegmentDisplay4[0:6]);


endmodule


module variableClock(Clock,Score,Resetn,output_clk);

input Clock, Resetn,Score;
output reg output_clk;


reg[31:0]counter;

// The generated clock (output_clk) will switch edges when counter reaches 10000000. Counter is incremented by the score
// (the clock will get faster as the score increases). 
always@(posedge Clock, negedge Resetn)
	begin
		if(!Resetn)
			begin	
				counter<=0;
				output_clk<=0;
			end
		else
			begin
				if(counter==10000000)
					begin	
						counter<=0;
						output_clk<=~output_clk;
					end
				else
					begin
						counter<=counter+Score;
					end
			end
end
				
				
				
endmodule
				
						


// Determine the segment number that is lit up. Unless the user hits stop, the segment is increased (the number will overflow)
module upcounter_slot(Clock,output_clk,Stop,Resetn,Number);
	
	input Clock,Stop,Resetn,output_clk;
	output reg [31:0]Number;
	reg [1:0] y, Y;
	parameter A=2'b00,B=2'b01;
	
	//Define next state combinational circuit
	
	always@(Stop,y)
	
		case (y)
			A:	if(!Stop) Y=B;
				else	Y=A;
			B:	if(Stop) Y=B;
				else	Y=B;
			
			
			default: Y=2'bxx;	// do not care about other values
				
		endcase
		


		
		always@(negedge Resetn, posedge Clock)
			if (Resetn==0) y<=A;
			else y<=Y;		
	
	
		always @ (posedge output_clk,negedge Resetn)
			
			if(!Resetn)
				Number<=0;
				
			else if(y==B)
				Number<=Number;
				
			else if(Clock)
				Number<=Number+1;	
					
			
				
endmodule


// Determine which segment should light up based on signalIn
module seg7(signalIn,ledOut);

//creates a 4 value input vector and 7 outputs
	
	input [2:0]signalIn;
	output reg [6:0]ledOut;

	always @(signalIn)
		case(signalIn)
			0:ledOut = 7'b0000001;
			1:ledOut = 7'b1001111;
			2:ledOut = 7'b0010010;
			3:ledOut = 7'b0000110;
			4:ledOut = 7'b1001100;
			5:ledOut = 7'b0100100;
			6:ledOut = 7'b0100000;
			7:ledOut = 7'b0001111;
			
			default:ledOut = 7'bx;
			
		endcase
endmodule


// Determine which segment should light up based on signalIn. No segments are lit up unless x is 1.
module seg7next(signalIn,x,ledOut);
   input x;
	input [2:0]signalIn;
	output reg [6:0]ledOut;
   
	always @(signalIn)
	   if (x==1)
		begin
		case(signalIn)
			0:ledOut = 7'b0000001;
			1:ledOut = 7'b1001111;
			2:ledOut = 7'b0010010;
			3:ledOut = 7'b0000110;
			4:ledOut = 7'b1001100;
			5:ledOut = 7'b0100100;
			6:ledOut = 7'b0100000;
			7:ledOut = 7'b0001111;
			default:ledOut = 7'bx;
		endcase
		end
		else
		ledOut = 7'b1111111;
endmodule

//State machine for game logic
module levelstate(compare_out, Clock, Resetn, x2, x3, x4, score_count);
  input compare_out, Resetn;
  input Clock;
  output reg x2, x3, x4, score_count;
  reg[2:1]y, Y;
  parameter[3:1]A=3'b000, B=3'b001, C=3'b010, D=3'b011, E=3'b100;
  
  
  always @(compare_out, y)
  begin
  case(y)
   // First state (place first block)
    A:Y=B;
    
    // Move onto next state unless user does not stack block
	 B:if(compare_out) Y=C;
	   else Y=A;
	 C:if(compare_out) Y=D;
	   else Y=A;
	 D:if(compare_out) Y=E;
	   else Y=A;
	 E: Y=B;
	 default: Y=2'bxx;
	endcase
	
	// Define which hex7segs are lit up based on the state
	x2=(y==B || y==C || y==D);
	x3=(y==C || y==D);
	x4=(y==D);
	
	// Determine level
	score_count=(y==E);
	end
	
	// Reset game
	always @(posedge Clock, negedge Resetn)
	if (Resetn==0)
	y<=A;
	else
	y<=Y;
endmodule

// Compare two 3 bit inputs on a clock edge and assign result to compare_out
module compare(x1, x2,Clock, compare_out);
   input [2:0]x1, x2;
	input Clock;
	output reg compare_out;
	
	always @(posedge Clock)
	compare_out <= (x1 == x2);
endmodule

//Save x in x_reg on clock posedge
module register(x,Clock, x_reg);
input [2:0]x;
input Clock;
output reg [2:0]x_reg;

always @(posedge Clock)
  x_reg=x;
 
endmodule 
