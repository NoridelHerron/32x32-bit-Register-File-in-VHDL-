
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all; -- for uniform ()

entity tb_Register is
end entity tb_Register;

architecture sim of tb_Register is

    -- Component Declaration
    component RegisterFile
        port (
            clk          : in  std_logic;
            rst          : in  std_logic;
            write_enable : in  std_logic;
            write_addr   : in  std_logic_vector(4 downto 0);
            write_data   : in  std_logic_vector(31 downto 0);
            read_addr1   : in  std_logic_vector(4 downto 0);
            read_addr2   : in  std_logic_vector(4 downto 0);
            read_data1   : out std_logic_vector(31 downto 0);
            read_data2   : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Internal Signals
    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    signal write_enable : std_logic;
    signal write_addr   : std_logic_vector(4 downto 0);
    signal write_data   : std_logic_vector(31 downto 0);
    signal read_addr1   : std_logic_vector(4 downto 0);
    signal read_addr2   : std_logic_vector(4 downto 0);
    signal read_data1   : std_logic_vector(31 downto 0);
    signal read_data2   : std_logic_vector(31 downto 0);

    -- Local "shadow" register file to track expected values
    type regfile_array is array (0 to 31) of std_logic_vector(31 downto 0);
    signal regfile : regfile_array := (others => (others => '0')); -- initialize all register to 0.

    constant TOTAL_TESTS : integer := 5000; -- number of test

begin

    -- Instantiate the RegisterFile
    uut: RegisterFile port map ( clk, rst, write_enable, write_addr, write_data, read_addr1, read_addr2, read_data1, read_data2);

    -- Clock Process
    process
    begin
        while now < 5000 us loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
        wait;
    end process;

    -- Stimulus Process
    process
        -- keep track the number of pass test
        variable passed_tests : integer := 0;
        -- Randomization    
        variable rand_addr1      : integer;
        variable rand_addr2      : integer;
        variable rand_write_addr : integer;
        variable rand_write_data : integer;
        variable seed1, seed2    : positive := 1;
        variable rand_real       : real;
        variable rand_upper16     : unsigned(15 downto 0); 
        variable rand_lower16     : unsigned(15 downto 0);
    begin
        -- Reset
        rst <= '1'; 
        wait for 10 ns;
        rst <= '0';
        wait for 10 ns;

        for i in 0 to TOTAL_TESTS-1 loop
            -- Randomize write address
            uniform(seed1, seed2, rand_real);
            rand_write_addr := integer(rand_real * 32.0) mod 32;

            -- Randomize full 32-bit random data (safe way)
            uniform(seed1, seed2, rand_real);
            rand_upper16 := to_unsigned(integer(rand_real * 65536.0), 16);

            uniform(seed1, seed2, rand_real);
            rand_lower16 := to_unsigned(integer(rand_real * 65536.0), 16);

            write_addr <= std_logic_vector(to_unsigned(rand_write_addr, 5));
            write_data <= std_logic_vector(rand_upper16 & rand_lower16);
            write_enable <= '1';

            wait until rising_edge(clk);

            -- Update shadow model
            if rand_write_addr /= 0 then -- x0 must stay 0
                regfile(rand_write_addr) <= std_logic_vector(rand_upper16 & rand_lower16);
            end if;

            -- Randomize read addresses
            uniform(seed1, seed2, rand_real);
            rand_addr1 := integer(rand_real * 32.0) mod 32; -- "mod" guarantee that the address is between 0 to 31

            uniform(seed1, seed2, rand_real);
            rand_addr2 := integer(rand_real * 32.0) mod 32;

            read_addr1 <= std_logic_vector(to_unsigned(rand_addr1, 5));
            read_addr2 <= std_logic_vector(to_unsigned(rand_addr2, 5));

            write_enable <= '0'; -- disable writing now
            wait until rising_edge(clk);

            wait for 1 ns; -- small settle

            -- Check read data
            if (read_data1 /= regfile(rand_addr1)) or (read_data2 /= regfile(rand_addr2)) then
                report "TEST FAIL! " &
                       "Read1 Addr: " & integer'image(rand_addr1) &
                       " Expected: " & integer'image(to_integer(unsigned(regfile(rand_addr1)))) &
                       " Got: " & integer'image(to_integer(unsigned(read_data1))) &
                       " | Read2 Addr: " & integer'image(rand_addr2) &
                       " Expected: " & integer'image(to_integer(unsigned(regfile(rand_addr2)))) &
                       " Got: " & integer'image(to_integer(unsigned(read_data2)))
                       severity warning;
            else
                passed_tests := passed_tests + 1;
            end if;


        end loop;

        -- Summary
        report "-------------------------------------------" severity note;
        report "RegisterFile Randomized Test Summary:" severity note;
        report "Total Tests   : " & integer'image(TOTAL_TESTS) severity note;
        report "Total Passes  : " & integer'image(passed_tests) severity note;
        report "Total Failures: " & integer'image(TOTAL_TESTS - passed_tests) severity note;
        report "-------------------------------------------" severity note;

        -- Print Register File contents
        report "Register File Final Contents:" severity note;
        for i in 0 to 31 loop
            report "Register[" & integer'image(i) & "] = " & integer'image(to_integer(unsigned(regfile(i)))) 
            severity note;
        end loop;

        wait;
    end process;
end sim;