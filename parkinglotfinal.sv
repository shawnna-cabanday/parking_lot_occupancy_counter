module parkinglotdriver(CLOCK_50, KEY0, 
								KEY3, KEY2, 
								HEX5, HEX4, HEX3, HEX2, HEX1, HEX0,
								GPIO0, GPIO1);
	
	input logic CLOCK_50, KEY0, KEY3, KEY2;
	output logic GPIO0, GPIO1;
	output logic [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0; 
	wire entersig, exitsig;
	wire [4:0] countsig;
	wire inputA, inputB;
	
	logic [31:0] clk;
	parameter whichClock = 20;
	
	clock_divider cdiv (.clock(CLOCK_50), .divided_clocks(clk));
	
	userInput inA (.clk(clk[whichClock]), .D(~KEY3), .Q(inputA));
	userInput inB (.clk(clk[whichClock]), .D(~KEY2), .Q(inputB));
	
	parkinglotfsm myfsm (.clk(clk[whichClock]), .reset(~KEY0), .A(inputA), .B(inputB), 
													.enter(entersig), .exit(exitsig));
	
	counter mycounter (.clk(clk[whichClock]), .reset(~KEY0), .inc(entersig), .dec(exitsig), 
										.cout(countsig[4:0]));
	
	hexdisplay mydisplay (.clk(clk[whichClock]), .inputcount(countsig[4:0]),
								.status5(HEX5), .status4(HEX4), .status3(HEX3), .status2(HEX2),
								.led1(HEX1), .led0(HEX0));
								
	assign GPIO0 = ~KEY3;
	assign GPIO1 = ~KEY2;

	
//for testbench verification
//	clock_divider cdiv (.clock(CLOCK_50), .divided_clocks(clk));
//	
//	userInput userInputA (.clk(CLOCK_50), .D(KEY3), .Q(inputA));
//	userInput userInputB (.clk(CLOCK_50), .D(KEY2), .Q(inputB));
//	
//	parkinglotfsm myfsm (.clk(CLOCK_50), .reset(KEY0), .A(inputA), .B(inputB), 
//													.enter(entersig), .exit(exitsig));
//	
//	counter mycounter (.clk(CLOCK_50), .reset(KEY0), .inc(entersig), .dec(exitsig), 
//										.cout(countsig[4:0]));
//	
//	hexdisplay mydisplay (.clk(CLOCK_50), .inputcount(countsig[4:0]),
//								.status5(HEX5), .status4(HEX4), .status3(HEX3), .status2(HEX2),
//								.led1(HEX1), .led0(HEX0));
//								
//	assign GPIO0 = KEY3;
//	assign GPIO1 = KEY2;
	
	
endmodule

module clock_divider (clock, divided_clocks);
	input clock;
	output [31:0] divided_clocks;
	reg [31:0] divided_clocks;
	
	
	initial
		divided_clocks <= 0;
		
	always @(posedge clock)
		divided_clocks <= divided_clocks + 1;
		
endmodule 

//metastability
module userInput(clk, D, Q);
	input clk, D;
	output logic Q;
	logic temp;
	
	always_ff @(posedge clk) begin
		temp <= D;
		Q <= temp;
	end
	
endmodule

module parkinglotfsm(clk, reset, A, B, enter, exit);
	
	input logic clk, reset, A, B;
	output logic enter, exit;
		
	//State Variables
	enum {unblocked, sensorB, sensorA, blocked} ps, ns;
	
	always @(posedge clk) begin
		case(ps)

			unblocked: 	if({A,B} == 2'b01) 	begin		ns = sensorB; enter = 0; exit = 0; end
							else if({A,B} == 2'b10) begin 	ns = sensorA; enter = 0; exit = 0; end
							else 					begin			ns = unblocked; enter = 0; exit = 0; end
							
			sensorB:	if({A,B} == 2'b01) begin 	ns = sensorB; enter = 0; exit = 0; end
						else if({A,B} == 2'b11) begin ns = blocked; enter = 0; exit = 0; end
						else if({A,B} == 2'b00) begin ns = unblocked; enter = 1; exit = 0; end
						else  		begin				ns = unblocked; enter = 0; exit = 0; end 
						
			sensorA: if({A,B} == 2'b10) begin 		ns = sensorA; enter = 0; exit = 0; end
						else if({A,B} == 2'b11) begin ns = blocked; enter = 0; exit = 0; end
						else if({A,B} == 2'b00) begin ns = unblocked; exit = 1; enter = 0; end
						else  		begin				ns = unblocked; enter = 0; exit = 0; end 
						
			blocked:	if({A,B} == 2'b01) begin 		ns = sensorB; enter = 0; exit = 0; end 
						else if({A,B} == 2'b10)	begin ns = sensorA; enter = 0; exit = 0; end
						else if({A,B} == 2'b11) begin ns = blocked; enter = 0; exit = 0; end
						else  			begin			ns = unblocked; enter = 0; exit = 0; end
						
		endcase
	end

		//alternative method for FSM rather than embedding states
//	assign enter = (ps == sensorB && {A,B} == 2'b00);
//	assign exit = (ps == sensorA && {A,B} == 2'b00);
	
	always_ff @(posedge clk) begin
		
		if(reset)
			ps <= unblocked;
		else
			ps <= ns;
	end
	
endmodule


module counter(clk, reset, inc, dec, cout);
	
	input logic clk, reset, inc, dec;
	output logic [4:0] cout; 
	logic [4:0] ps, ns;
	
	parameter [4:0] zero = 5'b0,
		one = 5'b1,
		two = 5'b10,
		three = 5'b11, 
		four = 5'b100,
		five = 5'b101,
		six = 5'b110,
		seven = 5'b111,
		eight = 5'b1000,
		nine = 5'b1001,
		ten = 5'b1010,
		eleven = 5'b1011,
		twelve = 5'b1100,
		thirteen = 5'b1101,
		fourteen = 5'b1110,
		fifteen = 5'b1111,
		sixteen = 5'b10000,
		seventeen = 5'b10001,
		eighteen = 5'b10010,
		nineteen = 5'b10011,
		twenty = 5'b10100,
		twentyone = 5'b10101,
		twentytwo = 5'b10110,
		twentythree = 5'b10111,
		twentyfour = 5'b11000,
		twentyfive = 5'b11001;
	
	
	always @(posedge clk) begin
		case(ps)
			zero: if(inc) ns = one;
					else ns = zero;
			one: if(inc) 	ns = two;
					else if(dec)		ns = zero;
					else ns = one;
			two: if(inc) 	ns = three;
					else if(dec)		ns = one;
					else ns = two;
			three:if(inc) 	ns = four;
					else if(dec)		ns = two;
					else ns = three;
			four: if(inc) 	ns = five;
					else if(dec)		ns = three;
					else ns = four;
			five: if(inc) 	ns = six;
					else if(dec)		ns = four;
					else ns = five;
			six: if(inc) 	ns = seven;
					else if(dec)		ns = five;
					else ns = six;
			seven: if(inc) 	ns = eight;
					else if(dec)		ns = six;
					else ns = seven;
			eight:if(inc) 		ns = nine;
					else if(dec)		ns = seven;
					else ns = eight;
			nine: if(inc) 	ns = ten;
					else if(dec)		ns = eight;
					else ns = nine;
			ten:	if(inc) 	ns = eleven;
					else if(dec)		ns = nine;
					else ns = ten;
			eleven:if(inc) 	ns = twelve;
					else if(dec)		ns = ten;
					else ns = eleven;
			twelve:if(inc) 	ns = thirteen;
					else if(dec)		ns = eleven;
					else ns = twelve;
			thirteen:if(inc) 	ns = fourteen;
					else if(dec)		ns = twelve;
					else ns = thirteen;
			fourteen: if(inc) 	ns = fifteen;
					else if(dec)		ns = thirteen;
					else ns = fourteen;
			fifteen:if(inc) 	ns = sixteen;
					else if(dec)		ns = fourteen;
					else ns = fifteen;
			sixteen: if(inc) 	ns = seventeen;
					else if(dec)		ns = fifteen;
					else ns = sixteen;
			seventeen:if(inc) 	ns = eighteen;
					else if(dec)		ns = sixteen;
					else ns = seventeen;
			eighteen:if(inc) 	ns = nineteen;
					else if(dec)		ns = seventeen;
					else ns = eighteen;
			nineteen:if(inc) 	ns = twenty;
					else if(dec)		ns = eighteen;
					else ns = nineteen;
			twenty:if(inc) 	ns = twentyone;
					else if(dec)		ns = nineteen;
					else ns = twenty;
			twentyone:if(inc) 	ns = twentytwo;
					else if(dec)		ns = twenty;
					else ns = twentyone;
			twentytwo:if(inc) 	ns = twentythree;
					else if(dec)		ns = twentyone;
					else ns = twentytwo;
			twentythree:if(inc) 	ns = twentyfour;
					else if(dec)		ns = twentytwo;
					else ns = twentythree;
			twentyfour:if(inc) 	ns = twentyfive;
					else if(dec)		ns = twentythree;
					else ns = twentyfour;
			twentyfive:if(dec)		ns = twentyfour;
					else ns = twentyfive;
			endcase
	end
	
	always @(posedge clk) begin
		if(reset) begin
			ps <= zero;
		end
		else begin
			cout <= ps; 
			ps <= ns;
		end
	end
	
	
endmodule

module hexdisplay(clk, inputcount,
						status5, status4, status3, status2,
						led1, led0);
	input clk;
	input logic [4:0] inputcount; 
	output logic [6:0] status5, status4, status3, status2;
	output logic  [6:0] led1, led0;
	
	//								    	6543210
	parameter [6:0]	zero = 	7'b1000000,	
							one =  	7'b1111001,
							two =  	7'b0100100,
							three = 	7'b0110000,
							four =	7'b0011001,
							five =	7'b0010010,
							six = 	7'b0000010,
							seven =	7'b1111000,
							eight = 	7'b0000000,
							nine = 	7'b0011000,
							F =		7'b0001110,
							U = 		7'b1000001,
							L = 		7'b1000111,
							E = 		7'b0000110,	//ENPTY
							N = 		7'b1001000,
							P = 		7'b0001100,
							T = 		7'b0000111,
							Y =		7'b0010001,
							blk = 	7'b1111111;


	always @(inputcount) 
		case(inputcount) 
			0:	begin status5 = E; status4 = N; status3 = P; status2 = T; led1 = Y; led0 = zero; end 
			1: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk; led1 = blk; led0 = one; end
			2: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk; led1 = blk; led0 = two; end
			3: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk; led1 = blk; led0 = three; end
			4: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk; led1 = blk;led0 = four; end
			5: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk; led1 = blk;led0 = five; end
			6: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk; led1 = blk;led0 = six; end
			7: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk; led1 = blk;led0 = seven; end
			8: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk; led1 = blk;led0 = eight; end
			9: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk; led1 = blk;led0 = nine; end
			10: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = one; led0 = zero; end
			11: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = one; led0 = one; end
			12: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = one; led0 = two; end
			13: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = one; led0 = three; end
			14: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = one; led0 = four; end
			15: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = one; led0 = five; end
			16: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = one; led0 = six; end
			17: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = one; led0 = seven; end
			18: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = one; led0 = eight; end
			19: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = one; led0 = nine; end
			20: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = two; led0 = zero; end
			21: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = two; led0 = one; end
			22: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = two; led0 = two; end
			23: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = two; led0 = three; end
			24: begin status5 = blk; status4 = blk; status3 = blk; status2 = blk;led1 = two; led0 = four; end
			25: begin status5 = F; status4 = U; status3 = L; status2 = L;led1 = two; led0 = five; end
		endcase

endmodule


module parkinglotdriver_testbench();

	logic clk, reset, A, B;
	logic [6:0] HEX5, HEX4, HEX3, HEX2, HEX1, HEX0;
	logic GPIO0, GPIO1;

	parkinglotdriver dut (.CLOCK_50(clk), .KEY0(reset), 
								.KEY3(A), .KEY2(B), 
								.HEX5(HEX5), .HEX4(HEX4), .HEX3(HEX3), .HEX2(HEX2), .HEX1(HEX1), .HEX0(HEX0),
								.GPIO0(GPIO0), .GPIO1(GPIO1)); 
	
	//Set up the clock.
	parameter CLOCK_PERIOD = 100;
	
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
		
	end

	initial begin
		reset <= 1;			@(posedge clk);	// cycle through car entering
		reset <= 0;			@(posedge clk);
								@(posedge clk);
								@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);
		{A,B} <= 2'b10;	@(posedge clk);
		{A,B} <= 2'b11;	@(posedge clk);
		{A,B} <= 2'b01;	@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);
		
		{A,B} <= 2'b00;	@(posedge clk);
		{A,B} <= 2'b10;	@(posedge clk);
		{A,B} <= 2'b11;	@(posedge clk);
		{A,B} <= 2'b01;	@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);
		
		{A,B} <= 2'b00;	@(posedge clk);
		{A,B} <= 2'b10;	@(posedge clk);
		{A,B} <= 2'b11;	@(posedge clk);
		{A,B} <= 2'b01;	@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);
		
		{A,B} <= 2'b00;	@(posedge clk);
		{A,B} <= 2'b10;	@(posedge clk);
		{A,B} <= 2'b11;	@(posedge clk);
		{A,B} <= 2'b01;	@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);	// 3 cars entered
		
		{A,B} <= 2'b00;	@(posedge clk);
		{A,B} <= 2'b01;	@(posedge clk);
		{A,B} <= 2'b11;	@(posedge clk);
		{A,B} <= 2'b10;	@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);
		
		{A,B} <= 2'b00;	@(posedge clk);
		{A,B} <= 2'b01;	@(posedge clk);
		{A,B} <= 2'b11;	@(posedge clk);
		{A,B} <= 2'b10;	@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);
		
		{A,B} <= 2'b00;	@(posedge clk);
		{A,B} <= 2'b01;	@(posedge clk);
		{A,B} <= 2'b11;	@(posedge clk);
		{A,B} <= 2'b10;	@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);	// 3 cars exiting
		
		reset <= 1;			@(posedge clk);	// cycle through car exiting
		reset <= 0;			@(posedge clk);
								@(posedge clk);
								@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);
		{A,B} <= 2'b01;	@(posedge clk);
		{A,B} <= 2'b11;	@(posedge clk);
		{A,B} <= 2'b10;	@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);		
		$stop; 
	end
endmodule

module parkinglotfsm_testbench();

	logic clk, reset, A, B, enter, exit;
	
	parkinglotfsm dut (.clk(clk), .reset(reset), .A(A), .B(B), .enter(enter), .exit(exit));
	
	//Set up the clock.
	parameter CLOCK_PERIOD = 100;
	
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
		
	end

	initial begin
		reset <= 1;			@(posedge clk);	// cycle through car entering
		reset <= 0;			@(posedge clk);
								@(posedge clk);
								@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);
		{A,B} <= 2'b10;	@(posedge clk);
		{A,B} <= 2'b11;	@(posedge clk);
		{A,B} <= 2'b01;	@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);
		
		reset <= 1;			@(posedge clk);	// cycle through car exiting
		reset <= 0;			@(posedge clk);
								@(posedge clk);
								@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);
		{A,B} <= 2'b01;	@(posedge clk);
		{A,B} <= 2'b11;	@(posedge clk);
		{A,B} <= 2'b10;	@(posedge clk);
		{A,B} <= 2'b00;	@(posedge clk);		
		$stop; 
	end
endmodule

module counter_testbench();

	logic clk, reset, inc, dec;
	logic [4:0] cout; 
	
	counter dut (.clk, .reset, .inc, .dec);
	
	//Set up the clock.
	parameter CLOCK_PERIOD = 100;
	
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
		
	end

	initial begin
		reset <= 1;				@(posedge clk);	// cycle through car entering
		reset <= 0;				@(posedge clk);
		
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		inc <= 1; dec <= 0;	@(posedge clk);
		inc <= 0; dec <= 0;	@(posedge clk);
		
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);

		
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
		dec <= 1; inc <= 0;	@(posedge clk);
		dec <= 0; inc <= 0;	@(posedge clk);
									@(posedge clk);
		$stop; 
	end
endmodule