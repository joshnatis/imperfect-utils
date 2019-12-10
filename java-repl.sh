#!/bin/bash

ctrl_c()
{
	cd .. &&
	rm -rf .java_repl
	echo ""
	exit
}

print_commands()
{
	echo "======="
	echo "RESTART - reset state"
	echo "EXIT - quit"
	echo "FREEWRITE - turn off repl"
	echo "REPL - turn on repl"
	echo "IMPORT - insert import directive"
	echo "PEEK - view your program"
	echo "======="
	echo ""
}

start()
{
	trap ctrl_c INT
	print_commands
	mkdir .java_repl && 
	cd .java_repl &&
	touch source_code &&
	echo "import java.util.*;" > source_code
	echo "public class execute { " >> source_code
	echo "public static void main (String[] args){" >> source_code
}

compile_and_run()
{
	cat source_code > execute.java
	
	echo "}}" >> execute.java &&
	javac execute.java
	
	if [ $? -eq 0 ]; then
		java execute &&
		echo ""
	else
		clean
	fi
}

execute_command()
{
	if [ "$1" = "RESTART" ]; then
		clear
		print_commands
		clean
	elif [ "$1" = "EXIT" ]; then
		ctrl_c
	elif [ "$1" = "FREEWRITE" ]; then
		read -r -p "∞ " command
		while [ "$command" != "REPL" ]; do
			echo "$command" >> source_code
			read -r -p "∞ " command
		done
		#compile_and_run
	elif [ "$1" = "REPL" ]; then
		:
	elif [ "$1" = "IMPORT" ]; then
		read -r -p "Type your import directive: " inc
		cat source_code > temp
		echo "$inc" > source_code
		cat temp >> source_code
	elif [ "$1" = "PEEK" ]; then
		echo "---"
		cat source_code
		echo "---"
	else
		echo "$1" >> source_code
		compile_and_run
	fi
}

clean()
{
	echo "import java.util.*;" > source_code
	echo "public class execute { " >> source_code
	echo "public static void main (String[] args){" >> source_code
}

start
while :; do
	read -r -p "λ " command
	execute_command "$command"
done
