#!/bin/bash

ctrl_c()
{
	cd .. &&
	rm -rf ."$LANGUAGE"_repl
	echo ""
	exit
}

selectLanguage()
{
	if [ "$1" = "java" ] || [ "$1" = "Java" ] || [ "$1" = "JAVA" ]; then
		LANGUAGE="java"
	elif [ "$1" = "C" ] || [ "$1" = "c" ]; then
		LANGUAGE="c"
	elif [ "$1" = "c++" ] || [ "$1" = "C++" ] || [ "$1" = "cpp" ] || [ "$1" = "Cpp" ] || [ "$1" = "CPP" ]; then
		LANGUAGE="c++"
	else
		return 1
	fi
}

print_commands()
{
	echo "======="
	echo "RESTART - reset state"
	echo "EXIT - quit"
	echo "FREEWRITE - turn off repl"
	echo "REPL - turn on repl"

	if [ "$LANGUAGE" = "c++" ] || [ "$LANGUAGE" = "c" ]; then
		echo "INCLUDE - insert #include directive"
	elif [ "$LANGUAGE" = "java" ]; then
		echo "IMPORT - insert import directive"
	fi

	echo "PEEK - view your program"
	echo "======="
	echo ""
}

start()
{
	trap ctrl_c INT
	print_commands

	mkdir ."$LANGUAGE"_repl && 
	cd ."$LANGUAGE"_repl &&

	if [ "$LANGUAGE" = "c++" ]; then
		touch source_code &&
		echo "#include <iostream>" > source_code
		echo "using namespace std; int main(){" >> source_code

	elif [ "$LANGUAGE" = "c" ]; then
		touch source_code &&
		echo "#include <stdio.h>" > source_code
		echo "int main(){" >> source_code

	elif [ "$LANGUAGE" = "java" ]; then
		touch source_code &&
		echo "import java.util.*;" > source_code
		echo "public class execute { " >> source_code
		echo "public static void main (String[] args){" >> source_code

	fi
}

compile_and_run()
{
	cat source_code > execute."$LANGUAGE"
	
	if [ "$LANGUAGE" = "c" ] || [ "$LANGUAGE" = "cpp" ]; then
		echo "}" >> execute."$LANGUAGE" &&

		if [ "$LANGUAGE" = "c" ]; then
			gcc execute.c
		else
			g++ execute.cpp
		fi
	
		if [ $? -eq 0 ]; then
			./a.out &&
			echo ""
		else
			clean
		fi

	elif [ "$LANGUAGE" = "java" ]; then
		echo "}}" >> execute.java &&
		javac execute.java
	
		if [ $? -eq 0 ]; then
			java execute &&
			echo ""
		else
			clean
		fi

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

	elif [ "$1" = "INCLUDE" ] || [ "$1" = "IMPORT" ]; then
		 if [ "$LANGUAGE" = "c" ] || [ "$LANGUAGE" = "c++" ]; then
		 	read -r -p "Type your include directive: " inc
		elif [ "$LANGUAGE" = "java" ]; then
			read -r -p "Type your import directive: " inc
		fi

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
	if [ "$LANGUAGE" = "c++" ]; then
		echo "#include <iostream>" > source_code
		echo "using namespace std; int main(){ " >> source_code

	elif [ "$LANGUAGE" = "c" ]; then
		echo "#include <stdio.h>" > source_code
		echo "int main(){ " >> source_code

	elif [ "$LANGUAGE" = "java" ]; then
		echo "import java.util.*;" > source_code
		echo "public class execute { " >> source_code
		echo "public static void main (String[] args){" >> source_code

	fi
}

# --- Entry Point

LANGUAGE="$1"

if [ $# -ne 1 ]; then
	echo "ERROR: Requires exactly one argument (the language of your choice, e.g. c++)"
	echo ""
	exit 1
elif [ "$1" = "-h" ] || [ "$1" = "help" ] || [ "$1" = "--help" ]; then
	echo "Call with one argument (the language of your choice, e.g. repl c++)"
	echo "Currently available languages: C, C++, Java"
	echo ""
	exit 1
elif ! selectLanguage "$1"; then
	echo "ERROR: $1 is not currently a supported language."
	echo "Available languages: C, C++, Java"
	echo ""
	exit 1
fi

# -- Entry Point

start
while :; do
	read -r -p "λ " command
	execute_command "$command"
done