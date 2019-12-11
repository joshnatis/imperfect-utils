#include <string>
#include <iostream>
#include <regex>
#include <stack>
#include <queue>
#include <stdlib.h> //rand(), srand()
#include <time.h>

/* INTERFACE */
class PasswordGenerator
{
public:
	PasswordGenerator();
	PasswordGenerator(std::string alphabet);
	std::string generateRegexPassword(std::string pattern, int length = 0);
	std::string generateRandomPassword();
private:
	std::string ALPHABET;
};

/* IMPLEMENTATION */
PasswordGenerator::PasswordGenerator()
	: ALPHABET("AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz") {}


PasswordGenerator::PasswordGenerator(std::string alphabet)
	: ALPHABET(alphabet) {}

std::string PasswordGenerator::generateRegexPassword(std::string pattern, int length)
{
	std::regex re(pattern); //create regex from user specified pattern

	std::stack<std::string> words;
	words.push(""); //every set contains the empty set, and also we do this skip the first words.empty() condition

	std::string current_string;

 	while(!words.empty())
 	{
 		current_string = words.top();
 		words.pop();

 		//assure that matched string satisfies the length requirement
 		if(current_string.length() == length && std::regex_match(current_string, re))
 			return current_string;

 		if(current_string.length() < length)
		{
 			for(int i = 0; i < ALPHABET.length(); ++i)
 				words.push(current_string + ALPHABET[i]);
 		}
	}

	return current_string;
}

std::string PasswordGenerator::generateRandomPassword()
{
	std::string pw = "";
	for(int i = 0, pwlen = 1 + (rand() % 10); i < pwlen; ++i)
	{
		if(rand() % 2 == 0)
			pw.push_back('A' + rand() % 25);
		else if(rand() % 5 == 0)
			pw.push_back('0' + rand() % 9);
		else
			pw.push_back('a' + rand() % 25);
	}
	return pw;
}


/* MAIN */
int main(int argc, char **argv)
{
	if(argc == 1) //no parameters passed in, use defaults
	{
		srand (time(NULL));
		PasswordGenerator p = PasswordGenerator();
		std::cout << p.generateRandomPassword() << std::endl;
	}

	else if(argc == 2) //asked for help or invalid
	{
		if(!strcmp(argv[1], "-h") || !strcmp(argv[1], "help") || !strcmp(argv[1], "--help"))
		{
			std::cout << "-------\n";
			std::cout << "OPTION 1: Execute with no parameters. \n\t* This will return a random password (a-z and A-Z).\n";
			std::cout << "\t* ./a.out\n\n";
			std::cout << "OPTION 2: Execute with the parameters of: \n\t* (1) a regex pattern, (2) desired length\n\t* This will return a password matching your pattern\n";
			std::cout << "\t* ./a.out L+[A-O]L+ 4\n\n";
			std::cout << "OPTION 3: Execute with the parameters of: \n\t* (1) a regex pattern, (2) desired length, and (3) an alphabet (set of characters to build from), \n";
			std::cout << "\t* This will return a password of a desired length matching your pattern\n\t* Consists of characters specified in your alphabet.\n";
			std::cout << "\t* ./a.out [1..10] 2 0123456789 \n";
			std::cout << "-------\n";
		}
		else
		{
			std::cout << "ERROR: INVALID PARAMETERS (-h for help)\n";
		}
	}

	else if(argc == 3) //specified regex pattern and length
	{
		try
		{
			std::regex re(argv[1]); //fails if invalid
			PasswordGenerator p = PasswordGenerator(); //default alphabet
			std::cout << p.generateRegexPassword(argv[1], std::stoi(argv[2])) << std::endl;
		}
		catch(std::regex_error& e)
		{
			std::cout << "ERROR: INVALID REGEX PATTERN\n" << e.what() << std::endl;
		}
		catch(...)
		{
			std::cout << "ERROR: INVALID PARAMETERS (-h for help)\n";
		}
	}

	else if(argc == 4) // specified regex, length, and alphabet
	{
		try
		{
			std::regex re(argv[1]); //fails if invalid
			PasswordGenerator p = PasswordGenerator(argv[3]);
			std::cout << p.generateRegexPassword(argv[1], std::stoi(argv[2])) << std::endl;
		}
		catch(std::regex_error& e)
		{
			std::cout << "ERROR: INVALID REGEX PATTERN\n" << e.what() << std::endl;
		}
	}

	else
	{
		std::cout << "ERROR: INVALID PARAMETERS (-h for help)\n";
	}

	return 0;
}