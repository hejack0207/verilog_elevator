// C++ testbench for Verilator simulation
#include <verilated.h>
#include "Velevator_controller.h"

#include <iostream>

using namespace std;

// Simulation parameters
const int NUM_FLOORS = 4;
const int FLOOR_BITS = 2;
const int CLK_PERIOD = 10;  // 10ns = 100MHz
const int DOOR_OPEN_TIME = 5000;

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    
    // Create DUT instance
    Velevator_controller* dut = new Velevator_controller;
    
    // Initialize inputs
    dut->clk = 0;
    dut->reset = 1;
    dut->internal_requests = 0;
    dut->external_up_requests = 0;
    dut->external_down_requests = 0;
    dut->floor_sensors = 0x1;  // Start at floor 0
    
    vluint64_t sim_time = 0;
    vluint64_t door_timer = 0;
    
    cout << "=== Elevator Controller Testbench (Verilator) ===" << endl;
    cout << "Time\tFloor\tMotor\tDoor" << endl;
    
    // Reset sequence
    for (int i = 0; i < 10; i++) {
        dut->clk = !dut->clk;
        dut->eval();
        sim_time += CLK_PERIOD / 2;
    }
    dut->reset = 0;
    
    // Test 1: Internal request to go to floor 2
    cout << "\nTest 1: Internal request to floor 2" << endl;
    dut->internal_requests = 0x4;  // Floor 2
    for (int i = 0; i < 5; i++) {
        dut->clk = !dut->clk;
        dut->eval();
        sim_time += CLK_PERIOD / 2;
    }
    dut->internal_requests = 0;
    
    // Simulate elevator moving
    for (int i = 0; i < 20; i++) {
        dut->clk = !dut->clk;
        dut->eval();
        sim_time += CLK_PERIOD / 2;
    }
    dut->floor_sensors = 0x2;  // Floor 1
    for (int i = 0; i < 20; i++) {
        dut->clk = !dut->clk;
        dut->eval();
        sim_time += CLK_PERIOD / 2;
    }
    dut->floor_sensors = 0x4;  // Floor 2
    
    // Wait for door to open and close
    door_timer = 0;
    while (!(dut->motor_up == 0 && dut->motor_down == 0 && 
             dut->door_open == 0 && dut->door_close == 0) || door_timer < DOOR_OPEN_TIME + 1000) {
        dut->clk = !dut->clk;
        dut->eval();
        if (dut->door_open) door_timer++;
        sim_time += CLK_PERIOD / 2;
        
        // Print state changes
        if (dut->clk && sim_time % (CLK_PERIOD * 10) == 0) {
            cout << sim_time << "\t" << (int)dut->current_floor << "\t"
                 << "UP:" << dut->motor_up << " DOWN:" << dut->motor_down << "\t"
                 << "OPEN:" << dut->door_open << " CLOSE:" << dut->door_close << endl;
        }
    }
    
    // Test 2: External up request from floor 1
    cout << "\nTest 2: External up request from floor 1" << endl;
    dut->external_up_requests = 0x2;  // Floor 1
    for (int i = 0; i < 5; i++) {
        dut->clk = !dut->clk;
        dut->eval();
        sim_time += CLK_PERIOD / 2;
    }
    dut->external_up_requests = 0;
    
    // Simulate elevator moving down
    for (int i = 0; i < 20; i++) {
        dut->clk = !dut->clk;
        dut->eval();
        sim_time += CLK_PERIOD / 2;
    }
    dut->floor_sensors = 0x2;  // Floor 1
    
    // Wait for door to open and close
    door_timer = 0;
    while (!(dut->motor_up == 0 && dut->motor_down == 0 && 
             dut->door_open == 0 && dut->door_close == 0) || door_timer < DOOR_OPEN_TIME + 1000) {
        dut->clk = !dut->clk;
        dut->eval();
        if (dut->door_open) door_timer++;
        sim_time += CLK_PERIOD / 2;
        
        if (dut->clk && sim_time % (CLK_PERIOD * 10) == 0) {
            cout << sim_time << "\t" << (int)dut->current_floor << "\t"
                 << "UP:" << dut->motor_up << " DOWN:" << dut->motor_down << "\t"
                 << "OPEN:" << dut->door_open << " CLOSE:" << dut->door_close << endl;
        }
    }
    
    // Test 3: External down request from floor 3
    cout << "\nTest 3: External down request from floor 3" << endl;
    dut->external_down_requests = 0x8;  // Floor 3
    for (int i = 0; i < 5; i++) {
        dut->clk = !dut->clk;
        dut->eval();
        sim_time += CLK_PERIOD / 2;
    }
    dut->external_down_requests = 0;
    
    // Simulate elevator moving up
    for (int i = 0; i < 20; i++) {
        dut->clk = !dut->clk;
        dut->eval();
        sim_time += CLK_PERIOD / 2;
    }
    dut->floor_sensors = 0x4;  // Floor 2
    for (int i = 0; i < 20; i++) {
        dut->clk = !dut->clk;
        dut->eval();
        sim_time += CLK_PERIOD / 2;
    }
    dut->floor_sensors = 0x8;  // Floor 3
    
    // Wait for door to open and close
    door_timer = 0;
    while (!(dut->motor_up == 0 && dut->motor_down == 0 && 
             dut->door_open == 0 && dut->door_close == 0) || door_timer < DOOR_OPEN_TIME + 1000) {
        dut->clk = !dut->clk;
        dut->eval();
        if (dut->door_open) door_timer++;
        sim_time += CLK_PERIOD / 2;
        
        if (dut->clk && sim_time % (CLK_PERIOD * 10) == 0) {
            cout << sim_time << "\t" << (int)dut->current_floor << "\t"
                 << "UP:" << dut->motor_up << " DOWN:" << dut->motor_down << "\t"
                 << "OPEN:" << dut->door_open << " CLOSE:" << dut->door_close << endl;
        }
    }
    
    // Test 4: Multiple requests
    cout << "\nTest 4: Multiple requests (floor 1 and floor 3)" << endl;
    dut->internal_requests = 0xA;  // Floor 1 and 3
    for (int i = 0; i < 5; i++) {
        dut->clk = !dut->clk;
        dut->eval();
        sim_time += CLK_PERIOD / 2;
    }
    dut->internal_requests = 0;
    
    // Simulate elevator going to floor 1 first
    for (int i = 0; i < 20; i++) {
        dut->clk = !dut->clk;
        dut->eval();
        sim_time += CLK_PERIOD / 2;
    }
    dut->floor_sensors = 0x2;  // Floor 1
    
    // Wait for door to open and close
    door_timer = 0;
    while (!(dut->motor_up == 0 && dut->motor_down == 0 && 
             dut->door_open == 0 && dut->door_close == 0) || door_timer < DOOR_OPEN_TIME + 1000) {
        dut->clk = !dut->clk;
        dut->eval();
        if (dut->door_open) door_timer++;
        sim_time += CLK_PERIOD / 2;
        
        if (dut->clk && sim_time % (CLK_PERIOD * 10) == 0) {
            cout << sim_time << "\t" << (int)dut->current_floor << "\t"
                 << "UP:" << dut->motor_up << " DOWN:" << dut->motor_down << "\t"
                 << "OPEN:" << dut->door_open << " CLOSE:" << dut->door_close << endl;
        }
    }
    
    // Then to floor 3
    for (int i = 0; i < 20; i++) {
        dut->clk = !dut->clk;
        dut->eval();
        sim_time += CLK_PERIOD / 2;
    }
    dut->floor_sensors = 0x4;  // Floor 2
    for (int i = 0; i < 20; i++) {
        dut->clk = !dut->clk;
        dut->eval();
        sim_time += CLK_PERIOD / 2;
    }
    dut->floor_sensors = 0x8;  // Floor 3
    
    // Wait for door to open and close
    door_timer = 0;
    while (!(dut->motor_up == 0 && dut->motor_down == 0 && 
             dut->door_open == 0 && dut->door_close == 0) || door_timer < DOOR_OPEN_TIME + 1000) {
        dut->clk = !dut->clk;
        dut->eval();
        if (dut->door_open) door_timer++;
        sim_time += CLK_PERIOD / 2;
        
        if (dut->clk && sim_time % (CLK_PERIOD * 10) == 0) {
            cout << sim_time << "\t" << (int)dut->current_floor << "\t"
                 << "UP:" << dut->motor_up << " DOWN:" << dut->motor_down << "\t"
                 << "OPEN:" << dut->door_open << " CLOSE:" << dut->door_close << endl;
        }
    }
    
    cout << "\n=== Test Complete ===" << endl;
    
    // Cleanup
    delete dut;
    
    return 0;
}