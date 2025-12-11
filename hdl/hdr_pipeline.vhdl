-- HDR_PIPELINE.vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity HDR_PIPELINE is
    generic (
        DATA_WIDTH     : integer := 8;
        FRACTION_BITS  : integer := 8
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        valid_in   : in  std_logic;
        valid_out  : out std_logic;
        pixel_curto : in std_logic_vector(DATA_WIDTH-1 downto 0);
        pixel_longo : in std_logic_vector(DATA_WIDTH-1 downto 0);
        t1 : in std_logic_vector(15 downto 0);
        t2 : in std_logic_vector(15 downto 0);
        w1 : in std_logic_vector(7 downto 0);
        w2 : in std_logic_vector(7 downto 0);
        pixel_hdr_out : out std_logic_vector(DATA_WIDTH + FRACTION_BITS - 1 downto 0)
    );
end HDR_PIPELINE;

architecture RTL of HDR_PIPELINE is
    constant C_SCALED_WIDTH : integer := DATA_WIDTH + FRACTION_BITS;

    signal s1_valid : std_logic := '0';
    signal s1_p1, s1_p2 : unsigned(DATA_WIDTH-1 downto 0);
    signal s1_t1, s1_t2 : unsigned(15 downto 0);
    signal s1_w1, s1_w2 : unsigned(7 downto 0);

    signal s2_valid : std_logic := '0';
    signal s2_i1_norm, s2_i2_norm : unsigned(C_SCALED_WIDTH-1 downto 0);
    signal s2_w1, s2_w2 : unsigned(7 downto 0);

    signal s3_valid : std_logic := '0';
    signal s3_num  : unsigned(31 downto 0);
    signal s3_den  : unsigned(15 downto 0);

    signal s4_valid : std_logic := '0';
    signal s4_hdr   : unsigned(C_SCALED_WIDTH-1 downto 0);

begin

    -- Stage0: register inputs
    stage0: process(clk, rst)
    begin
        if rst = '1' then
            s1_valid <= '0';
            s1_p1 <= (others => '0');
            s1_p2 <= (others => '0');
            s1_t1 <= (others => '0');
            s1_t2 <= (others => '0');
            s1_w1 <= (others => '0');
            s1_w2 <= (others => '0');
        elsif rising_edge(clk) then
            if valid_in = '1' then
                s1_valid <= '1';
                s1_p1 <= unsigned(pixel_curto);
                s1_p2 <= unsigned(pixel_longo);
                s1_t1 <= unsigned(t1);
                s1_t2 <= unsigned(t2);
                s1_w1 <= unsigned(w1);
                s1_w2 <= unsigned(w2);
            else
                s1_valid <= '0';
            end if;
        end if;
    end process;

    -- Stage1: normalization
    stage1: process(clk, rst)
        variable v_i1_norm, v_i2_norm : unsigned(C_SCALED_WIDTH-1 downto 0);
    begin
        if rst = '1' then
            s2_valid <= '0';
            s2_i1_norm <= (others => '0');
            s2_i2_norm <= (others => '0');
            s2_w1 <= (others => '0');
            s2_w2 <= (others => '0');
        elsif rising_edge(clk) then
            if s1_valid = '1' then
                if s1_t1 /= 0 then
                    v_i1_norm := shift_left(resize(s1_p1, C_SCALED_WIDTH), FRACTION_BITS) / s1_t1;
                else
                    v_i1_norm := (others => '0');
                end if;
                if s1_t2 /= 0 then
                    v_i2_norm := shift_left(resize(s1_p2, C_SCALED_WIDTH), FRACTION_BITS) / s1_t2;
                else
                    v_i2_norm := (others => '0');
                end if;
                s2_i1_norm <= v_i1_norm;
                s2_i2_norm <= v_i2_norm;
                s2_w1 <= s1_w1;
                s2_w2 <= s1_w2;
                s2_valid <= '1';
            else
                s2_valid <= '0';
            end if;
        end if;
    end process;

    -- Stage2: weighted sum
    stage2: process(clk, rst)
        variable v_term1, v_term2 : unsigned(31 downto 0);
        variable v_num : unsigned(31 downto 0);
        variable v_den : unsigned(15 downto 0);
    begin
        if rst = '1' then
            s3_valid <= '0';
            s3_num <= (others => '0');
            s3_den <= (others => '0');
        elsif rising_edge(clk) then
            if s2_valid = '1' then
                v_term1 := resize(resize(s2_w1, 8) * resize(s2_i1_norm, C_SCALED_WIDTH), 32);
                v_term2 := resize(resize(s2_w2, 8) * resize(s2_i2_norm, C_SCALED_WIDTH), 32);
                v_num := v_term1 + v_term2;
                v_den := resize(s2_w1, 16) + resize(s2_w2, 16);
                s3_num <= v_num;
                s3_den <= v_den;
                s3_valid <= '1';
            else
                s3_valid <= '0';
            end if;
        end if;
    end process;

    -- Stage3: final division
    stage3: process(clk, rst)
        variable v_hdr : unsigned(C_SCALED_WIDTH-1 downto 0);
    begin
        if rst = '1' then
            s4_valid <= '0';
            s4_hdr <= (others => '0');
        elsif rising_edge(clk) then
            if s3_valid = '1' then
                if s3_den /= 0 then
                    v_hdr := resize(s3_num / s3_den, C_SCALED_WIDTH);
                else
                    v_hdr := (others => '0');
                end if;
                s4_hdr <= v_hdr;
                s4_valid <= '1';
            else
                s4_valid <= '0';
            end if;
        end if;
    end process;

    pixel_hdr_out <= std_logic_vector(s4_hdr);
    valid_out <= s4_valid;

end RTL;
