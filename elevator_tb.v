// Testbench for Elevator Controller
`timescale 1ns / 1ps

module elevator_tb;
    
    // Parameters
    parameter NUM_FLOORS = 4;
    parameter FLOOR_BITS = 2;
    parameter CLK_PERIOD = 10;  // 10ns = 100MHz
    
    // Inputs
    reg clk;
    reg reset;
    reg [NUM_FLOORS-1:0] internal_requests;
    reg [NUM_FLOORS-1:0] external_up_requests;
    reg [NUM_FLOORS-1:0] external_down_requests;
    reg [NUM_FLOORS-1:0] floor_sensors;
    
    // Outputs
    wire motor_up;
    wire motor_down;
    wire door_open;
    wire door_close;
    wire [FLOOR_BITS-1:0] current_floor;
    wire moving_up;
    wire moving_down;
    wire door_opening;
    wire door_closing;
    
    // Instantiate the elevator controller
    elevator_controller #(
        .NUM_FLOORS(NUM_FLOORS),
        .FLOOR_BITS(FLOOR_BITS)
    ) dut (
        .clk(clk),
        .reset(reset),
        .internal_requests(internal_requests),
        .external_up_requests(external_up_requests),
        .external_down_requests(external_down_requests),
        .floor_sensors(floor_sensors),
        .motor_up(motor_up),
        .motor_down(motor_down),
        .door_open(door_open),
        .door_close(door_close),
        .current_floor(current_floor),
        .moving_up(moving_up),
        .moving_down(moving_down),
        .door_opening(door_opening),
        .door_closing(door_closing)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test sequence
    initial begin
        // VCD dump for waveform viewing
        $dumpfile("elevator.vcd");
        $dumpvars(0, elevator_tb);
        
        // Initialize
        $display("=== Elevator Controller Testbench ===");
        $display("Time\tState\tFloor\tMotor\tDoor");
        
        reset = 1;
        internal_requests = 0;
        external_up_requests = 0;
        external_down_requests = 0;
        floor_sensors = 4'b0001;  // Start at floor 0
        
        #(CLK_PERIOD * 10);
        reset = 0;
        
        // Test 1: Internal request to go to floor 2
        $display("\nTest 1: Internal request to floor 2");
        internal_requests[2] = 1;
        #(CLK_PERIOD * 5);
        internal_requests[2] = 0;
        
        // Simulate elevator moving
        #(CLK_PERIOD * 20);
        floor_sensors = 4'b0010;  // Floor 1
        #(CLK_PERIOD * 20);
        floor_sensors = 4'b0100;  // Floor 2
        
        // Wait for door to open and close
        #(CLK_PERIOD * 100);
        
        // Test 2: External up request from floor 1
        $display("\nTest 2: External up request from floor 1");
        external_up_requests[1] = 1;
        #(CLK_PERIOD * 5);
        external_up_requests[1] = 0;
        
        // Simulate elevator moving down
        #(CLK_PERIOD * 20);
        floor_sensors = 4'b0010;  // Floor 1
        
        // Wait for door to open and close
        #(CLK_PERIOD * 100);
        
        // Test 3: External down request from floor 3
        $display("\nTest 3: External down request from floor 3");
        external_down_requests[3] = 1;
        #(CLK_PERIOD * 5);
        external_down_requests[3] = 0;
        
        // Simulate elevator moving up
        #(CLK_PERIOD * 20);
        floor_sensors = 4'b0100;  // Floor 2
        #(CLK_PERIOD * 20);
        floor_sensors = 4'b1000;  // Floor 3
        
        // Wait for door to open and close
        #(CLK_PERIOD * 100);
        
        // Test 4: Multiple requests
        $display("\nTest 4: Multiple requests (floor 1 and floor 3)");
        internal_requests[1] = 1;
        internal_requests[3] = 1;
        #(CLK_PERIOD * 5);
        internal_requests[1] = 0;
        internal_requests[3] = 0;
        
        // Simulate elevator going to floor 1 first
        #(CLK_PERIOD * 20);
        floor_sensors = 4'b0010;  // Floor 1
        
        // Wait for door to open and close
        #(CLK_PERIOD * 100);
        
        // Then to floor 3
        #(CLK_PERIOD * 20);
        floor_sensors = 4'b0100;  // Floor 2
        #(CLK_PERIOD * 20);
        floor_sensors = 4'b1000;  // Floor 3
        
        // Wait for door to open and close
        #(CLK_PERIOD * 100);
        
        $display("\n=== Test Complete ===");
        $finish;
    end
    
    // Monitor state changes
    always @(posedge clk) begin
        if (!reset) begin
            $display("%0t\t%b\t%0d\tUP:%b DOWN:%b\tOPEN:%b CLOSE:%b",
                    $time, dut.state, current_floor, motor_up, motor_down, 
                    door_open, door_close);
        end
    end
    
endmodule