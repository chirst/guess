assemble:
	as -o guess.o -g guess.asm

link:
	ld -o guess guess.o -lSystem -syslibroot `xcrun --show-sdk-path`

run:
	make assemble && make link && ./guess

debug:
	make assemble && make link && lldb ./guess
