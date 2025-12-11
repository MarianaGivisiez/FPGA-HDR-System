-- TOP.vhdl 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TOP is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        ocm_addr   : out unsigned(31 downto 0);
        ocm_din    : out std_logic_vector(7 downto 0);
        ocm_dout   : in  std_logic_vector(7 downto 0);
        ocm_we     : out std_logic;

        done       : out std_logic
    );
end TOP;

architecture RTL of TOP is

    signal t1_s : unsigned(15 downto 0) := to_unsigned(100, 16);
    signal t2_s : unsigned(15 downto 0) := to_unsigned(400, 16);
    signal w1_s : unsigned(7 downto 0)  := to_unsigned(1, 8);
    signal w2_s : unsigned(7 downto 0)  := to_unsigned(1, 8);

    component HDR_FUSAO_PIPELINE is
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            valid_in   : in  std_logic;
            valid_out  : out std_logic;
            pixel_curto : in std_logic_vector(7 downto 0);
            pixel_longo : in std_logic_vector(7 downto 0);
            t1 : in std_logic_vector(15 downto 0);
            t2 : in std_logic_vector(15 downto 0);
            w1 : in std_logic_vector(7 downto 0);
            w2 : in std_logic_vector(7 downto 0);
            pixel_hdr_out : out std_logic_vector(15 downto 0)
        );
    end component;

    type fsm_t is (
        INIT, READ_CURTO, WAIT_CURTO, WAIT_CURTO_2,
        READ_LONGO, WAIT_LONGO, WAIT_LONGO_2,
        SEND_PIXEL, WAIT_PIPE,
        WRITE_HDR_MSB, WAIT_WRITE1,
        WRITE_HDR_LSB, WAIT_WRITE2,
        DONE_STATE
    );
    signal state : fsm_t := INIT;

    constant NUM_PIXELS_C : integer := 24;
    signal pixel_index : integer range 0 to NUM_PIXELS_C := 0;

    signal curto_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal longo_reg : std_logic_vector(7 downto 0) := (others => '0');

    signal valid_pix  : std_logic := '0';
    signal hdr_valid  : std_logic := '0';
    signal hdr_word   : std_logic_vector(15 downto 0) := (others => '0');

    signal ocm_addr_int : unsigned(31 downto 0) := (others => '0');
    signal ocm_din_int  : std_logic_vector(7 downto 0) := (others => '0');
    signal ocm_we_int   : std_logic := '0';

begin

    ocm_addr <= ocm_addr_int;
    ocm_din  <= ocm_din_int;
    ocm_we   <= ocm_we_int;

    PIPE: entity work.HDR_FUSAO_PIPELINE
        port map (
            clk => clk,
            rst => rst,
            valid_in => valid_pix,
            valid_out => hdr_valid,
            pixel_curto => curto_reg,
            pixel_longo => longo_reg,
            t1 => std_logic_vector(t1_s),
            t2 => std_logic_vector(t2_s),
            w1 => std_logic_vector(w1_s),
            w2 => std_logic_vector(w2_s),
            pixel_hdr_out => hdr_word
        );

    process(clk, rst)
    begin
        if rst = '1' then
            state <= INIT;
            pixel_index <= 0;
            valid_pix <= '0';
            ocm_we_int <= '0';
            ocm_addr_int <= (others => '0');
            ocm_din_int <= (others => '0');
            done <= '0';

        elsif rising_edge(clk) then

            report "CYCLE: state=" & integer'image(fsm_t'pos(state)) &
                   " addr=" & integer'image(to_integer(ocm_addr_int(7 downto 0))) &
                   " we=" & std_logic'image(ocm_we_int);

            ocm_we_int <= '0';
            valid_pix  <= '0';

            case state is
                when INIT =>
                    pixel_index <= 0;
                    done <= '0';
                    state <= READ_CURTO;

                when READ_CURTO =>
                    ocm_addr_int <= to_unsigned(pixel_index, 32);
                    state <= WAIT_CURTO;

                when WAIT_CURTO =>
                    state <= WAIT_CURTO_2;

                when WAIT_CURTO_2 =>
                    curto_reg <= ocm_dout;
                    ocm_addr_int <= to_unsigned(24 + pixel_index, 32);
                    state <= READ_LONGO;

                when READ_LONGO =>
                    state <= WAIT_LONGO;

                when WAIT_LONGO =>
                    state <= WAIT_LONGO_2;

                when WAIT_LONGO_2 =>
                    longo_reg <= ocm_dout;
                    state <= SEND_PIXEL;

                when SEND_PIXEL =>
                    valid_pix <= '1';
                    state <= WAIT_PIPE;

                when WAIT_PIPE =>
                    if hdr_valid = '1' then
                        state <= WRITE_HDR_MSB;
                    end if;

                when WRITE_HDR_MSB =>
                    ocm_addr_int <= to_unsigned(48 + pixel_index*2, 32);
                    ocm_din_int  <= hdr_word(15 downto 8);
                    ocm_we_int   <= '1';
                    state <= WAIT_WRITE1;

                when WAIT_WRITE1 =>
                    state <= WRITE_HDR_LSB;

                when WRITE_HDR_LSB =>
                    ocm_addr_int <= to_unsigned(48 + pixel_index*2 + 1, 32);
                    ocm_din_int  <= hdr_word(7 downto 0);
                    ocm_we_int   <= '1';
                    state <= WAIT_WRITE2;

                when WAIT_WRITE2 =>
                    if pixel_index = NUM_PIXELS_C - 1 then
                        state <= DONE_STATE;
                    else
                        pixel_index <= pixel_index + 1;
                        state <= READ_CURTO;
                    end if;

                when DONE_STATE =>
                    done <= '1';

                when others =>
                    state <= INIT;
            end case;
        end if;
    end process;

end RTL;

