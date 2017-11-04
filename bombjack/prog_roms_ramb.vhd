--	(c) 2012 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity PROG_ROMS is
	port (
		I_CLK       : in  std_logic;
		I_ROM_SEL   : in  std_logic_vector( 4 downto 0);
		I_ADDR      : in  std_logic_vector(12 downto 0);
		--
		O_DATA      : out std_logic_vector( 7 downto 0)
	);
end;

architecture RTL of PROG_ROMS is
	signal ROMD_1J : std_logic_vector( 7 downto 0) := (others => '0');
	signal ROMD_1L : std_logic_vector( 7 downto 0) := (others => '0');
	signal ROMD_1M : std_logic_vector( 7 downto 0) := (others => '0');
	signal ROMD_1N : std_logic_vector( 7 downto 0) := (others => '0');
	signal ROMD_1R : std_logic_vector( 7 downto 0) := (others => '0');
begin

	ROM_1J : entity work.ROM_1J
	port map(
		clock		=> I_CLK,
		address		=> I_ADDR,
		q		=> ROMD_1J
	);

	ROM_1L : entity work.ROM_1L
	port map(
		clock		=> I_CLK,
		address		=> I_ADDR,
		q		=> ROMD_1L
	);

	ROM_1M : entity work.ROM_1M
	port map(
		clock		=> I_CLK,
		address		=> I_ADDR,
		q		=> ROMD_1M
	);

	ROM_1N : entity work.ROM_1N
	port map(
		clock		=> I_CLK,
		address		=> I_ADDR,
		q		=> ROMD_1N
	);

	ROM_1R : entity work.ROM_1R
	port map(
		clock		=> I_CLK,
		address		=> I_ADDR,
		q		=> ROMD_1R
	);

	O_DATA <=
		ROMD_1J when I_ROM_SEL = "11110" else
		ROMD_1L when I_ROM_SEL = "11101" else
		ROMD_1M when I_ROM_SEL = "11011" else
		ROMD_1N when I_ROM_SEL = "10111" else
		ROMD_1R when I_ROM_SEL = "01111" else
		(others => '0');
end RTL;
