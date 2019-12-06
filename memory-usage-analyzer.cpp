#include <iostream>
#include <fstream>
#include <map>


//TODO - add pointers to types
	//ISSUE - how can you tell if something is a pointer or dereferincing e.g int *eggs vs *eggs = ...
//TODO - add dynamic memory
//TODO - deal with functions (declarations and prototypes)
//TODO - arrays, vectors, other shit
//TODO - fix detecting functions
//TODO - deal with class definitions being in .hpp
//TODO - add ifstream, isstream, all sorts of stl stuff to types
//TODO - take into account variables in loops being reallocated

//IDEA - a lot of this stuff is looking for patterns, maybe try regex
//IDEA - dup file, make one round removing all function definitions/declarations/prototypes, then scan that normally 

int memoryFootprint(std::istream &fin);
int size(const std::string &type);
bool istype(const std::string &word);
void legitcheck(const std::string &filename);

int main(int argc, char **argv)
{
	if(argc != 2)
	{
		std::cout << "ERROR: Provide a single file as a parameter.\n";
		exit(1);
	}

	std::ifstream fin;
	fin.open(argv[1]);
	
	if(fin.fail())
	{
		std::cout << "ERROR: File does not exist.\n";
		exit(1);
	}

	legitcheck(argv[1]); //make sure it's a cpp file (or valid cpp file, later)


	int results = memoryFootprint(fin);
	std::cout << "Your program used approximately " << results << " bytes of memory.\n"; 

	return 0;
}

int memoryFootprint(std::istream &fin)
{
	int memory = 0; //total memory footprint for the program fin
	std::map<std::string, int> classMemoryTable; // e.g {"Person": 28}
	std::map<std::string, int> typeOccurencesTable; //stores number of each data type allocated


	//CASES: (1) is a type, (2) defines a class, (3) is an instance of a class, (4) ...
	std::string word;
	while(fin >> word)
	{
		if(istype(word))
		{
			memory += size(word);
			//update sighting in table
			if(typeOccurencesTable.count(word) == 0)
					typeOccurencesTable[word] = 1;
			else
					typeOccurencesTable[word] += 1; 
		}

		else if(word == "class" || word == "struct") //find memory usage of user specified types
		{
			std::string classname;
			fin >> classname; // word after class keyword is the class name

			//SPECIAL CASE CHECK - e.g. class Person{ ... (Need to get rid of the rogue curly boy)
			if(classname[classname.length() - 1] == '{' && classname.length() > 1)
				classname = classname.substr(0, classname.length() - 1);

			//create entry in our table which will hold amount of space each instance of classname takes up
			classMemoryTable[classname] = 0;

			int classmemory = 0;
			std::string member;
			while(fin >> member)
			{
				//SPECIAL CASE CHECK - for people who don't put spaces after '{', e.g. {int x = 5;
				if(member[0] == '{' && member.length() > 1)
		 			member = member.substr(1, member.length() - 1);
		
				if(istype(member)) // this is an instance variable, every object will contain it
					classmemory += size(member);

				else if(member.length() >= 2 && member.substr(0, 2) == "//")
					getline(fin, member); //entire line is a comment, strip it

				else if(member.length() >= 2 && member.substr(0, 2) == "/*") //multi-line comment, keep stripping until */ found
				{
					while(fin >> member)
					{
						if(member.length() >= 2 &&  member.substr(member.length() - 2) == "*/") //comment finished
						break;
					}
				}

				//end of class, we've counted all data members
				else if(member == "};" || (word == "struct" && member == "}"))
				{
					classMemoryTable[classname] = classmemory;
					break;
				}
			}
		}

		//if the word is an instance of a previously parsed class
		else if(classMemoryTable.count(word) == 1)
		{
			memory += classMemoryTable[word]; //add amt of memory taken by an instance of the class

			if(typeOccurencesTable.count(word) == 0)
					typeOccurencesTable[word] = 1;
			else
					typeOccurencesTable[word] += 1; 
		}

		else if(word.length() >= 2 && word.substr(0, 2) == "//")
			getline(fin, word); //entire line is a comment, strip it

		else if(word.length() >= 2 && word.substr(0, 2) == "/*") //multi-line comment, keep stripping until */ found
		{
			while(fin >> word)
			{
				if(word.length() >= 2 &&  word.substr(word.length() - 2) == "*/") //comment finished
					break;
			}
		}


		//these can be space separated and precede further type specifiers, special cases
		//consider: (1) not including long in istype(), (2) adding word != "long" &&, (3) moving to top
		//need to make sure long isn't caught by first if and then another long will follow
		//else if(word == "unsigned" || word == "signed" || word == "long") { }
	}

	std::cout << "Allocations: \n-----\n";
	for(auto& type : typeOccurencesTable)
	{
    	std::cout << type.first << ": " << type.second;
    	if(classMemoryTable.count(type.first) == 1)
    		std::cout << " [" << classMemoryTable[type.first] * typeOccurencesTable[type.first] << "b]\n";
    	else
    		std::cout << " [" << size(type.first) * type.second << "b]\n";
	}
    std::cout << "-----\n";

	return memory ;
}

int size(const std::string &type)
{
	if(type == "int") 		return sizeof(int);
	if(type == "bool")		return sizeof(bool);
	if(type == "char")		return sizeof(char);
	if(type == "float")		return sizeof(float);
	if(type == "double")	return sizeof(double);
	if(type == "string" || type == "std::string")
		return sizeof(std::string);
	if(type == "size_t") 	return sizeof(size_t);
	if(type == "short")		return sizeof(short);
	if(type == "wchar_t")	return sizeof(wchar_t);
	if(type == "char16_t")	return sizeof(char16_t);
	if(type == "char32_t")	return sizeof(char32_t);
	//if(type == "long") SPECIAL CASE
  	//return sizeof(long);

//pointers
	if(type == "int*")		return sizeof(int*);
	if(type == "bool*")		return sizeof(bool*);
	if(type == "char*")		return sizeof(char*);
	if(type == "float*")	return sizeof(float*);
	if(type == "double*")	return sizeof(double*);
	if(type == "string*" || type == "std::string")	
		return sizeof(std::string*);
	if(type == "size_t*")	return sizeof(size_t*);
	if(type == "short*")	return sizeof(short*);
	if(type == "wchar_t*")	return sizeof(wchar_t*);
	if(type == "char16_t*")	return sizeof(char16_t*);
	if(type == "char32_t*")	return sizeof(char32_t*);

	//else return extremely negative value to notion that something went wrong
	return -999999;
}

bool istype(const std::string &word)
{
	return word == "int" || word == "bool" || word == "char" || word == "float" || word == "double" || 
		   word == "string" || word == "std::string" || word == "size_t" || word == "short" || 
		   word == "wchar_t" || word == "char16_t" || word == "char32_t" || word == "int*" || 
		   word == "bool*" || word == "char*" || word == "float*" || word == "double*" || 
		   word == "string*" || word == "std::string*" || word == "size_t*" || word == "short*" || 
		   word == "wchar_t*" || word == "char16_t*" || word == "char32_t*";
}

void legitcheck(const std::string &filename)
{
	if(filename.length() > 3 && filename.substr(filename.length() - 3) == "cpp")
		return;

	std::cout << "ERROR: Not a valid C++ program, poptart man >:(\n";
	exit(1);
}