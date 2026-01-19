// Elevator Controller - Multi-floor elevator with internal and external requests
// Supports 4 floors by default, configurable via parameter

module elevator_controller #(
    parameter NUM_FLOORS = 4,
    parameter FLOOR_BITS = 2  // ceil(log2(NUM_FLOORS))
)(
    input wire clk,
    input wire reset,

    // Internal request buttons (inside elevator)
    input wire [NUM_FLOORS-1:0] internal_requests,

    // External request buttons (up/down from each floor)
    input wire [NUM_FLOORS-1:0] external_up_requests,
    input wire [NUM_FLOORS-1:0] external_down_requests,

    // Floor sensor inputs (active high when elevator is at that floor)
    input wire [NUM_FLOORS-1:0] floor_sensors,

    // Motor control outputs
    output reg motor_up,
    output reg motor_down,

    // Door control outputs
    output reg door_open,
    output reg door_close,

    // Status outputs
    output reg [FLOOR_BITS-1:0] current_floor,
    output reg moving_up,
    output reg moving_down,
    output reg door_opening,
    output reg door_closing
);

    // Define states
    localparam IDLE = 3'b000;
    localparam MOVING_UP = 3'b001;
    localparam MOVING_DOWN = 3'b010;
    localparam OPENING_DOOR = 3'b011;
    localparam DOOR_OPEN = 3'b100;
    localparam CLOSING_DOOR = 3'b101;

    // State register
    reg [2:0] state, next_state;

    // Request registers
    reg [NUM_FLOORS-1:0] up_requests;
    reg [NUM_FLOORS-1:0] down_requests;
    reg [NUM_FLOORS-1:0] active_requests;

    // Door timer counter
    reg [15:0] door_timer;
    parameter DOOR_OPEN_TIME = 16'd5000;  // Time door stays open

    // Direction flag
    reg direction_up;  // 1 = up, 0 = down

    // Find current floor from sensors
    integer i;
    always @(*) begin
        current_floor = 0;
        for (i = 0; i < NUM_FLOORS; i = i + 1) begin
            if (floor_sensors[i]) begin
                current_floor = i;
            end
        end
    end

    // Helper function to check requests above current floor
    function [NUM_FLOORS-1:0] get_requests_above;
        input [NUM_FLOORS-1:0] requests;
        input [FLOOR_BITS-1:0] floor;
        integer i;
        begin
            get_requests_above = 0;
            for (i = floor + 1; i < NUM_FLOORS; i = i + 1) begin
                get_requests_above[i] = requests[i];
            end
        end
    endfunction

    // Helper function to check requests below current floor
    function [NUM_FLOORS-1:0] get_requests_below;
        input [NUM_FLOORS-1:0] requests;
        input [FLOOR_BITS-1:0] floor;
        integer i;
        begin
            get_requests_below = 0;
            for (i = 0; i < floor; i = i + 1) begin
                get_requests_below[i] = requests[i];
            end
        end
    endfunction

    // Update request registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            up_requests <= 0;
            down_requests <= 0;
        end else begin
            // Latch external requests
            up_requests <= up_requests | external_up_requests;
            down_requests <= down_requests | external_down_requests;

            // Add internal requests to appropriate direction
            if (internal_requests != 0) begin
                up_requests <= up_requests | internal_requests;
                down_requests <= down_requests | internal_requests;
            end

            // Clear requests when at floor
            if (state == DOOR_OPEN) begin
                if (direction_up) begin
                    up_requests[current_floor] <= 1'b0;
                end else begin
                    down_requests[current_floor] <= 1'b0;
                end
            end
        end
    end

    // Combine all active requests
    always @(*) begin
        active_requests = up_requests | down_requests;
    end

    // State machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            motor_up <= 0;
            motor_down <= 0;
            door_open <= 0;
            door_close <= 0;
            moving_up <= 0;
            moving_down <= 0;
            door_opening <= 0;
            door_closing <= 0;
            door_timer <= 0;
            direction_up <= 1;
        end else begin
            state <= next_state;

            // Update direction when starting to move
            if (state == IDLE && next_state == MOVING_UP) begin
                direction_up <= 1;
            end else if (state == IDLE && next_state == MOVING_DOWN) begin
                direction_up <= 0;
            end
            // Toggle direction when reaching top or bottom
            else if (state == MOVING_UP && next_state == IDLE) begin
                direction_up <= 0;
            end else if (state == MOVING_DOWN && next_state == IDLE) begin
                direction_up <= 1;
            end

            // Default outputs
            motor_up <= 0;
            motor_down <= 0;
            door_open <= 0;
            door_close <= 0;
            moving_up <= 0;
            moving_down <= 0;
            door_opening <= 0;
            door_closing <= 0;

            case (state)
                IDLE: begin
                    // No movement
                end

                MOVING_UP: begin
                    motor_up <= 1;
                    moving_up <= 1;
                end

                MOVING_DOWN: begin
                    motor_down <= 1;
                    moving_down <= 1;
                end

                OPENING_DOOR: begin
                    door_open <= 1;
                    door_opening <= 1;
                end

                DOOR_OPEN: begin
                    door_open <= 1;
                    door_timer <= door_timer + 1;
                end

                CLOSING_DOOR: begin
                    door_close <= 1;
                    door_closing <= 1;
                end
            endcase
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (active_requests != 0) begin
                    // Check if there are requests above current floor
                    if (current_floor < NUM_FLOORS - 1 &&
                        (|(get_requests_above(up_requests, current_floor)) ||
                         (|(get_requests_above(down_requests, current_floor)) && direction_up))) begin
                        next_state = MOVING_UP;
                    end
                    // Check if there are requests below current floor
                    else if (current_floor > 0 &&
                             (|(get_requests_below(down_requests, current_floor)) ||
                              (|(get_requests_below(up_requests, current_floor)) && !direction_up))) begin
                        next_state = MOVING_DOWN;
                    end
                    // Request at current floor
                    else if (active_requests[current_floor]) begin
                        next_state = OPENING_DOOR;
                    end
                end
            end

            MOVING_UP: begin
                // Stop if there's a request at current floor
                if (up_requests[current_floor] ||
                    (down_requests[current_floor] &&
                     !(|(get_requests_above(up_requests, current_floor))))) begin
                    next_state = OPENING_DOOR;
                end
                // Continue to top if no more requests above
                else if (current_floor == NUM_FLOORS - 1 ||
                         !(|(get_requests_above(up_requests, current_floor)))) begin
                    next_state = IDLE;
                end
            end

            MOVING_DOWN: begin
                // Stop if there's a request at current floor
                if (down_requests[current_floor] ||
                    (up_requests[current_floor] &&
                     !(|(get_requests_below(down_requests, current_floor))))) begin
                    next_state = OPENING_DOOR;
                end
                // Continue to bottom if no more requests below
                else if (current_floor == 0 ||
                         !(|(get_requests_below(down_requests, current_floor)))) begin
                    next_state = IDLE;
                end
            end

            OPENING_DOOR: begin
                next_state = DOOR_OPEN;
            end

            DOOR_OPEN: begin
                if (door_timer >= DOOR_OPEN_TIME) begin
                    next_state = CLOSING_DOOR;
                end
            end

            CLOSING_DOOR: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule
