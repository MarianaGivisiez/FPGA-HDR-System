-- HDR_TB_corrected.vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HDR_TB is
end HDR_TB;

architecture TB of HDR_TB is

    --------------------------------------------------------------------
    -- DUT signals
    --------------------------------------------------------------------
    signal clk  : std_logic := '0';
    signal rst  : std_logic := '1';

    signal ocm_addr : unsigned(31 downto 0);
    signal ocm_din  : std_logic_vector(7 downto 0);
    signal ocm_dout : std_logic_vector(7 downto 0);
    signal ocm_we   : std_logic;
    signal done     : std_logic;

    constant CLK_PERIOD : time := 20 ns;

    --------------------------------------------------------------------
    -- Memory model (256 bytes) - initialized via impure function
    --------------------------------------------------------------------
    type mem_t is array (0 to 255) of std_logic_vector(7 downto 0);

    constant IMG_W : integer := 6;
    constant IMG_H : integer := 4;
    constant NUM_PIXELS : integer := IMG_W * IMG_H;

    type int_array_t is array (natural range <>) of integer;

    constant curto_vals : int_array_t(0 to NUM_PIXELS-1) := (
        20,30,40,50,60,70,
        10,20,30,40,50,60,
         5,10,20,30,40,50,
         0, 5,10,15,20,25
    );

    constant longo_vals : int_array_t(0 to NUM_PIXELS-1) := (
        80,120,200,240,255,255,
        60,110,180,240,255,255,
        40,80,150,220,255,255,
        20,40,80,120,180,240
    );

    -- impure function to initialize memory at elaboration time
    impure function init_memory return mem_t is
        variable v : mem_t := (others => (others => '0'));
    begin
        -- copy curto at addresses 0..NUM_PIXELS-1
        for i in 0 to NUM_PIXELS-1 loop
            v(i) := std_logic_vector(to_unsigned(curto_vals(i), 8));
        end loop;
        -- copy longo at addresses 24..24+NUM_PIXELS-1
        for i in 0 to NUM_PIXELS-1 loop
            v(24 + i) := std_logic_vector(to_unsigned(longo_vals(i), 8));
        end loop;
        return v;
    end function;

    -- single driver for mem (initialized)
    signal mem : mem_t := init_memory;

begin

    --------------------------------------------------------------------
    -- Clock generator
    --------------------------------------------------------------------
    clk_proc: process
    begin
        while true loop
            clk <= '0'; wait for CLK_PERIOD/2;
            clk <= '1'; wait for CLK_PERIOD/2;
        end loop;
    end process;

    --------------------------------------------------------------------
    -- OCM Memory model (synchronous read/write)
    -- NOTE: index uses low 8 bits of ocm_addr to index mem (0..255)
    --------------------------------------------------------------------
    mem_model: process(clk)
        variable idx : integer;
    begin
        if rising_edge(clk) then
            idx := to_integer(unsigned(ocm_addr(7 downto 0)));
            -- write has priority (typical for memory model)
            if ocm_we = '1' then
                mem(idx) <= ocm_din;
            end if;
            -- synchronous read output
            ocm_dout <= mem(idx);
        end if;
    end process;

    --------------------------------------------------------------------
    -- Instantiate DUT (assumes HDR_TOP_OCM exists in work library)
    --------------------------------------------------------------------
    DUT : entity work.HDR_TOP_OCM
        port map (
            clk      => clk,
            rst      => rst,
            ocm_addr => ocm_addr,
            ocm_din  => ocm_din,
            ocm_dout => ocm_dout,
            ocm_we   => ocm_we,
            done     => done
        );

    --------------------------------------------------------------------
    -- Test Process
    -- - Reset
    -- - Wait for done using proper clock-synchronized wait loop
    --------------------------------------------------------------------
    stim: process
        variable i : integer;
        variable msb, lsb : integer;
        variable hdr_word : integer;
    begin
        -- Apply reset
        rst <= '1';
        wait for 100 ns;
        wait until rising_edge(clk);
        rst <= '0';

        -- Wait for DUT to assert done. Wait on rising edges to avoid races.
        -- This loop waits until done becomes '1' sampled on a rising edge.
        loop
            wait until rising_edge(clk);
            exit when done = '1';
        end loop;

        -- give a couple cycles to ensure final writes have settled
        wait for 2 * CLK_PERIOD;

        report "=== HDR RESULT (16-bit Q8.8 integers) ===";
        for r in 0 to IMG_H-1 loop
            for c in 0 to IMG_W-1 loop
                i := r * IMG_W + c;
                msb := to_integer(unsigned(mem(48 + i*2)));
                lsb := to_integer(unsigned(mem(48 + i*2 + 1)));
                hdr_word := msb * 256 + lsb;
                report "pixel(" & integer'image(r) & "," & integer'image(c) & ") = " & integer'image(hdr_word);
            end loop;
        end loop;
        report "=== END HDR RESULT ===";
        wait;
    end process;

end TB;
