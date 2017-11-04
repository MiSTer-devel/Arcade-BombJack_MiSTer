-------------------------------------------------------------------[07.09.2015]
-- MAME Bomb Jack implementation in FPGA
-------------------------------------------------------------------------------
-- Modify for DE1-SoC DevBoard By MVV'2015
-- https://github.com/mvvproject/DE1-SoC-Board
--
-- Base Version http://papilio.cc/index.php?n=Playground.BombJack
--
-- (c) 2012 d18c7db(a)hotmail
--
-- This program is free software; you can redistribute it and/or modify it under
-- the terms of the GNU General Public License version 3 or, at your option,
-- any later version as published by the Free Software Foundation.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses
--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity bombjack_top is
port 	(
		-- Clock
		clk_48M			: in std_logic;
		clk_6M			: out std_logic;

		reset				: in std_logic;

		p1_start, p1_coin, p1_jump, p1_down, p1_up, p1_left, p1_right : in std_logic;
		p2_start, p2_coin, p2_jump, p2_down, p2_up, p2_left, p2_right : in std_logic;
				 
		-- VGA
		VGA_R				: out std_logic_vector(3 downto 0);
		VGA_G				: out std_logic_vector(3 downto 0);
		VGA_B				: out std_logic_vector(3 downto 0);
		VGA_HS			: out std_logic;
		VGA_VS			: out std_logic;		

		O_VBLANK			: out	std_logic;
		O_HBLANK			: out	std_logic;

		audio				: out std_logic_vector( 7 downto 0)
	);
end bombjack_top;

architecture RTL of bombjack_top is

	signal clk_4M_en		: std_logic := '0';
	signal clk_6M_en		: std_logic := '0';
	signal clk_12M			: std_logic := '0';

	signal i_rom_4P_data		: std_logic_vector( 7 downto 0) := (others => '0');
	signal o_rom_4P_addr		: std_logic_vector(12 downto 0) := (others => '0');
	signal o_rom_4P_ena		: std_logic := '1';

	signal i_rom_7JLM_data	: std_logic_vector(23 downto 0) := (others => '0');
	signal o_rom_7JLM_addr	: std_logic_vector(12 downto 0) := (others => '0');
	signal o_rom_7JLM_ena	: std_logic := '1';

	signal i_rom_8KHE_data	: std_logic_vector(23 downto 0) := (others => '0');
	signal o_rom_8KHE_addr	: std_logic_vector(12 downto 0) := (others => '0');
	signal o_rom_8KHE_ena	: std_logic := '1';

	signal i_rom_8RNL_data	: std_logic_vector(23 downto 0) := (others => '0');
	signal o_rom_8RNL_addr	: std_logic_vector(12 downto 0) := (others => '0');
	signal o_rom_8RNL_ena	: std_logic := '1';

	signal ctr_even			: std_logic_vector(2 downto 0) := (others => '0');
	signal ctr_odd			: std_logic_vector(3 downto 0) := (others => '0');

begin

	-- generate clocks
	--          ___         ___         ___
	--   4M ___/   \_______/   \_______/   \_
	--          ___     ___     ___     ___
	--   6M ___/   \___/   \___/   \___/   \_
	--        _   _   _   _   _   _   _   _   
	--  12M _/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_

	gen_clk : process(clk_48M, reset)
	begin
		if reset = '1' then
			ctr_odd  <= (others => '0');
			ctr_even <= (others => '0');
		elsif rising_edge(clk_48M) then
			ctr_even <= ctr_even + 1;
			if ctr_odd = x"b" then
				ctr_odd <= (others => '0');
			else
				ctr_odd <= ctr_odd + 1;
			end if;
		end if;
	end process gen_clk;

	clk_4M_en 	<= ctr_odd(2);
	clk_6M_en 	<= ctr_even(2);
	clk_12M		<= ctr_even(1);
	clk_6M	 	<= ctr_even(2);

	bombjack_inst : entity work.BOMB_JACK
	port map(
		-- player 1 controls
		I_P1(7 downto 5)	=> "000",		-- P1 unused
		I_P1(4)				=> p1_jump, 	-- P1 jump
		I_P1(3)				=> p1_down, 	-- P1 down
		I_P1(2)				=> p1_up, 		-- P1 up
		I_P1(1)				=> p1_left, 	-- P1 left
		I_P1(0)				=> p1_right, 	-- P1 right

		-- player 2 controls
		I_P2(7 downto 5)	=> "000",		-- P2 unused
		I_P2(4)				=> p2_jump,		-- P2 jump
		I_P2(3)				=> p2_down,		-- P2 down
		I_P2(2)				=> p2_up,		-- P2 up
		I_P2(1)				=> p2_left,		-- P2 left
		I_P2(0)				=> p2_right,	-- P2 right

		-- system inputs
		I_SYS(7 downto 4)	=> "1111",		-- unused
		I_SYS(3)				=> p2_start,	-- P2 start
		I_SYS(2)				=> p1_start,	-- P1 start
		I_SYS(1)				=> p2_coin,		-- P2 coin
		I_SYS(0)				=> p1_coin,		-- P1 coin

		-- SW1 presets
		I_SW1(7)				=> '1',			-- demo sounds 1=on, 0=off
		I_SW1(6)				=> '1',			-- orientation 1=upright, 0=cocktail
		I_SW1(5 downto 4)	=> "10",			-- lives 00=3, 01=4, 10=5, 11=2
		I_SW1(3 downto 2)	=> "00",			-- coin b 00=1Coin/1Credit, 01=2Coins/1Credit, 10=1Coin/2Credits, 11=1Coin/3Credits
		I_SW1(1 downto 0)	=> "00",			-- coin a 00=1Coin/1Credit, 01=1Coin/2Credits, 10=1Coin/3Credits, 11=1Coin/6Credits
                           
		-- SW2 presets       
		I_SW2(7)				=> '0',			-- special coin 0=easy, 1=hard
		I_SW2(6 downto 5)	=> "00",			-- enemies number and speed 00=easy, 01=medium, 10=hard, 11=insane
		I_SW2(4 downto 3)	=> "00",			-- bird speed 00=easy, 01=medium, 10=hard, 11=insane
		I_SW2(2 downto 0)	=> "010",		-- bonus life 000=none, 001=every 100k, 010=every 30k, 011=50k only, 100=100k only, 101=50k and 100k, 110=100k and 300k, 111=50k and 100k and 300k

		-- Audio out
		O_AUDIO				=> audio,

		-- VGA monitor output
		O_VIDEO_R			=> VGA_R,
		O_VIDEO_G			=> VGA_G,
		O_VIDEO_B			=> VGA_B,
		O_HSYNC				=> VGA_HS,
		O_VSYNC				=> VGA_VS,

		O_VBLANK				=> O_VBLANK,
		O_HBLANK				=> O_HBLANK,

		-- external ROMs
		I_ROM_4P_DATA		=> i_rom_4P_data,
		O_ROM_4P_ADDR		=> o_rom_4P_addr,
		O_ROM_4P_ENA		=> o_rom_4P_ena,

		I_ROM_7JLM_DATA	=> i_rom_7JLM_data,
		O_ROM_7JLM_ADDR	=> o_rom_7JLM_addr,
		O_ROM_7JLM_ENA		=> o_rom_7JLM_ena,

		I_ROM_8KHE_DATA	=> i_rom_8KHE_data,
		O_ROM_8KHE_ADDR	=> o_rom_8KHE_addr,
		O_ROM_8KHE_ENA		=> o_rom_8KHE_ena,

		I_ROM_8RNL_DATA	=> i_rom_8RNL_data,
		O_ROM_8RNL_ADDR	=> o_rom_8RNL_addr,
		O_ROM_8RNL_ENA		=> o_rom_8RNL_ena,

		-- Active high reset
		I_RESET				=> reset,

		-- Clocks
		I_CLK_4M				=> clk_4M_en,
		I_CLK_6M				=> clk_6M_en,
		I_CLK_12M			=> clk_12M
	);

	---------------------------------
	-- page 4 schematic - sprite ROMS
	---------------------------------
	-- chip 7J page 4
	ROM_7J : entity work.ROM_7J
	port map (
		clock		=> clk_12M,
		clken		=> o_rom_7JLM_ena,
		address	=> o_rom_7JLM_addr,
		q			=> i_rom_7JLM_data(23 downto 16)
	);

	-- chip 7L page 4
	ROM_7L : entity work.ROM_7L
	port map (
		clock		=> clk_12M,
		clken		=> o_rom_7JLM_ena,
		address	=> o_rom_7JLM_addr,
		q			=> i_rom_7JLM_data(15 downto  8)
	);

	-- chip 7M page 4
	ROM_7M : entity work.ROM_7M
	port map (
		clock		=> clk_12M,
		clken		=> o_rom_7JLM_ena,
		address	=> o_rom_7JLM_addr,
		q			=> i_rom_7JLM_data( 7 downto  0)
	);

	----------------------------------------------
	-- page 6 schematic - character generator ROMs
	----------------------------------------------
	-- chip 8K page 6
	ROM_8K : entity work.ROM_8K
	port map (
		clock		=> clk_12M,
		clken		=> o_rom_8KHE_ena,
		address	=> o_rom_8KHE_addr(11 downto 0),
		q			=> i_rom_8KHE_data(23 downto 16)
	);

	-- chip 8H page 6
	ROM_8H : entity work.ROM_8H
	port map (
		clock		=> clk_12M,
		clken		=> o_rom_8KHE_ena,
		address	=> o_rom_8KHE_addr(11 downto 0),
		q			=> i_rom_8KHE_data(15 downto  8)
	);

	-- chip 8E page 6
	ROM_8E : entity work.ROM_8E
	port map (
		clock		=> clk_12M,
		clken		=> o_rom_8KHE_ena,
		address	=> o_rom_8KHE_addr(11 downto 0),
		q			=> i_rom_8KHE_data( 7 downto  0)
	);

	-------------------------------------------
	-- page 7 schematic - background tiles ROMs
	-------------------------------------------
	-- chip 4P page 7
	ROM_4P : entity work.ROM_4P
	port map (
		clock		=> clk_12M,
		clken		=> o_rom_4P_ena,
		address	=> o_rom_4P_addr(11 downto 0),
		q			=> i_rom_4P_data
	);

	-- chip 8R page 7
	ROM_8R : entity work.ROM_8R
	port map (
		clock		=> clk_12M,
		clken		=> o_rom_8RNL_ena,
		address	=> o_rom_8RNL_addr,
		q			=> i_rom_8RNL_data(23 downto 16)
	);

	-- chip 8N page 7
	ROM_8N : entity work.ROM_8N
	port map (
		clock		=> clk_12M,
		clken		=> o_rom_8RNL_ena,
		address	=> o_rom_8RNL_addr,
		q			=> i_rom_8RNL_data(15 downto  8)
	);

	-- chip 8L page 7
	ROM_8L : entity work.ROM_8L
	port map (
		clock		=> clk_12M,
		clken	  	=> o_rom_8RNL_ena,
		address	=> o_rom_8RNL_addr,
		q	  		=> i_rom_8RNL_data( 7 downto  0)
	);

end RTL;
