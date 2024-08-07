src_files	:= $(wildcard ./src/*.asm)
src_names	:= $(patsubst ./src/%.asm, %, $(src_files))
targ_objs	:= $(patsubst %, ./target/%.o, $(src_names))
std			:= $(wildcard ./std/*.o)
libs		:= $(patsubst %, ../%/target/%.o, $(shell cat ./libs))

w	:= $(shell tput cols)
h	:= $(shell tput lines)

.SILENT:

build: compile link
run: clean build exec
gdb: clean build startgdb

compile: $(src_files)
	echo "+ Building files:"
	for f in $(src_names); do \
		echo "  - $$f.asm"; \
		nasm -f elf -o ./target/$$f.o ./src/$$f.asm; \
	done

link: $(targ_objs) $(libs) $(std)
	echo "+ Linking files:"
	for f in $^; do echo "  - $$f"; done
	ld -m elf_i386 -o ./target/main $^

exec: ./target/main
	echo "+ Executing main"
	echo "  With ($(w), $(h))"
	echo "=================="
	./target/main $(w) $(h)

clean:
	echo "+ Cleaning Target"
	rm -rf ./target
	mkdir target

init:
	read -p "Enter new project name: " proj_name && \
	mkdir -p $$proj_name/src && \
	cp template.asm $$proj_name/src/main.asm && \
	cd $$proj_name && \
	touch libs && \
	ln ../makefile makefile

addlib:
	read -p "Enter lib name: " lib_name && \
	echo $$lib_name >> ./libs

startgdb:
	gdb --args ./target/main $(w) $(h)
