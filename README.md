# verilog-cache-simulator
Project Log: Two-Level Cache Hierarchy Simulation

Log Entry 1: GitHub Repository Setup

Initialized a new GitHub repository for the project. Created the standard directory layout with subfolders for each cache configuration: direct_mapped, set_associative_2way, set_associative_4way, and a shared unified_testbench folder for top-level validation. Confirmed Git installation and linked the local repository with GitHub. Verified that commits and pushes worked properly.
Log Entry 2: Direct-Mapped Cache Modules

Wrote cache_direct.v and cache_directl2.v to implement simple direct-mapped L1 and L2 cache modules. Simulated each with a fixed number of blocks and implemented basic tag checking and validity bit logic. Encountered SystemVerilog syntax errors when declaring variables (e.g., loop index i) inside procedural blocks. Moved all such declarations outside the blocks to resolve the issue. Ensured each cache could respond with simulated data on hit and initiate tag replacement on miss.

Log Entry 3: Direct Cache System Integration
Developed cache_system_direct.v, integrating both cache_direct and cache_directl2. Managed L1 and L2 behavior in sequence: if L1 missed but L2 hit, the block would be promoted to L1. Initially used mismatched data widths (11-bit read_data), which caused port binding warnings. Corrected all modules to use 32-bit-wide read_data to maintain consistency and avoid padding-related issues.

Log Entry 4: 2-Way Set-Associative Cache System
Implemented cache_system_2way.v to simulate 2-way set-associative caches with internal data and tag arrays. Designed LRU-based replacement for both L1 and L2 using a single-bit policy. Calculated tag, index, and offset widths programmatically using a clog2 function. Encountered indexing issues in tag extraction and LRU assignment, which were
fixed after correcting the address slicing logic. Confirmed that promotion from L2 to L1 occurs properly.

Log Entry 5: 4-Way Set-Associative Cache Modules and Hierarchical Staging
Constructed a complete 4-way set-associative hierarchy consisting of cache_4way.v, cache_4wayl2.v, and cache_system_4way.v. Each cache used 4 sets and supported pseudo-LRU (least-recently-used) logic for replacement. Implemented the L1–L2 hierarchy by first checking L1 for a hit. If missed, L2 was queried and, upon a hit, data was promoted from L2 to L1.
Faced a number of challenges:
•
Incorrect tag width slicing caused false hits and alignment errors.
•
Block indexing misaligned with associativity led to overwrite bugs.
•
Fixed these issues by carefully verifying address decomposition (tag/index/offset) and restructuring control logic for multi-way replacement.
Validated cache behavior using controlled address patterns. L1 and L2 caches correctly handled miss promotion and LRU updates. Confirmed that the modular design allowed cache_4way.v and cache_4wayl2.v to be reused independently in different systems. Later used this system in the unified testbench.

Log Entry 6: Unified Testbench Development
Developed test_cache_all.v to run a single simulation comparing all three cache systems side-by-side. Initially tested using fixed addresses (e.g., 0x020, 0x040) and printed hit/miss counts for each access. Detected and resolved errors with output ports and signal naming. Reorganized wiring to prevent conflict across instances and ensure all caches could respond independently. Verified output consistency.

Log Entry 7: Randomized Access Testing Implementation
Extended test_cache_all.v to generate 10,000 random memory accesses using $random % 2048. Replaced static tests with a loop-based simulation. Tracked per-cache
hit/miss rates with dedicated counters. Printed access summary for each iteration, showing address and per-cache result (HIT or MISS). Verified that cache logic scaled across random input and output remained stable. Observed expected miss rates for cold-start behavior.

Log Entry 8: AMAT Calculation Integration and Final Validation
Integrated Average Memory Access Time (AMAT) calculation at the end of test_cache_all.v. Defined real variables outside of initial block to avoid syntax errors. Used the formula:
AMAT = L1_time + (miss_rate * (L2_time + (1 - L2_hit_prob) * mem_time))
Assumed constants: L1 = 1 cycle, L2 = 5 cycles, main memory = 100 cycles, L2 hit probability = 0.5. Calculated miss rates from counter values. Verified correct output:
•
Direct-Mapped: Hits = 1227, Misses = 8773 → AMAT = 49.25 cycles
•
2-Way Set: Hits = 595, Misses = 9405 → AMAT = 52.73 cycles
•
4-Way Set: Hits = 311, Misses = 9689 → AMAT = 54.29 cycles
Ran simulation using iverilog and vvp. Output matched expectations. Committed and pushed final codebase to GitHub. Cache simulation project completed successfully.

Simulation

Unified testbench: unified_testbench Command line to compile:
iverilog -o cache_sim test_cache_all.v ../direct_mapped/cache_system_direct.v ../direct_mapped/cache_direct.v ../direct_mapped/cache_directl2.v ../set_associative_2way/cache_system_2way.v ../set_associative_4way/cache_system_4way.v ../set_associative_4way/cache_4way.v ../set_associative_4way/cache_4wayl2.v

Command to run simulation:
vvp cache_sim

