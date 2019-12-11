#include <iostream>
#include <cstdlib>
#include <time.h>

using namespace std;

/* Global Variables */
const int ROWS = 20; 
const int COLS = 50;
char MAP[ROWS][COLS];

int VISIBLE_ROWS;
int VISIBLE_COLS;

int snake_col = 0;
int snake_row = 0;

int points = 0; //total apples found
int avg = -1; //average moves to get apple throughout session
int moves = 0; //total user cued moves (e.g wasd is 4 moves)

int apple_row = 0;
int apple_col = 0;

/* Function Prototypes */
void clearScreen();
void initialize();
void spawnApple();
void printMap();
void moveSnake(char dir);
string getUserInput();
void printBorder(char pos);

int main()
{
	initialize();
	
	while(snake_row < VISIBLE_ROWS && snake_col < VISIBLE_COLS && snake_row >= 0 & snake_col >= 0)
	{
		spawnApple();
		printMap();
		string dir = getUserInput();
		for(int i = 0, size = dir.length(); i < size; ++i)
		{
			moveSnake(dir[i]);
		}
		clearScreen();
		++moves; //every combination of letters is a move, not every letter
	}
	return 0;
}

void clearScreen()
{
	for(int i = 0; i < 100; ++i)
		cout << "\n";
}
void spawnApple()
{
	while(snake_row == apple_row && snake_col == apple_col)
	{
		apple_row = rand() % VISIBLE_ROWS;
		apple_col = rand() % VISIBLE_COLS;
	}
	//apple location guaranteed not to be snake location
	MAP[apple_row][apple_col] = 'O';
}

void printBorder(char pos)
{
	cout << " ";
	for(int i = 1; i < VISIBLE_COLS; ++i)
	{
		if(pos == 't')
			cout << "_";
		else if(pos == 'b')
			cout << "-";	
	}
	cout << "\n";
}

string getUserInput()
{
	string input;
	cin >> input;
	return input;
}

void moveSnake(char dir)
{
	if(dir == 'w')
	{	
		MAP[snake_row][snake_col] = ' ';
		MAP[snake_row - 1][snake_col] = '*';
		snake_row--;
	}

	else if(dir == 's')
	{
		MAP[snake_row][snake_col] = ' ';
		MAP[snake_row + 1][snake_col] = '*';
		snake_row++;
	}

	else if(dir == 'a')
	{
		MAP[snake_row][snake_col] = ' ';
		MAP[snake_row][snake_col - 1] = '*';
		snake_col--;
	}
	
	else if(dir == 'd')
	{
		MAP[snake_row][snake_col] = ' ';
		MAP[snake_row][snake_col + 1] = '*';
       	snake_col++;
	}

	//found apple
	if(snake_row == apple_row && snake_col == apple_col)
	{
		if(points == 0) //first turn
			avg = moves;
		else
			avg = (avg + moves)/2; //average previous avg and current avg
		
		//reset state counters
		moves = 0;

		points++;

		MAP[apple_row][apple_col] = ' ';
		MAP[apple_row][apple_col] = '*';
	}
}

void printMap()
{
	cout << "AVERAGE MOVES: " << avg << " | MOVE #" << moves << " | POINTS: " << points << endl;
	printBorder('t');
	for(int i = 0; i < VISIBLE_ROWS; ++i)
	{
		for(int j = 0; j <= VISIBLE_COLS; ++j)
		{
			if(j == 0 || j == VISIBLE_COLS)
				cout << "|";
			cout << MAP[i][j];
		}
		cout << "\n";
	}
	printBorder('b');
}

void initialize()
{
	srand (time(NULL));
	VISIBLE_ROWS = 1 + (rand() % (ROWS - 1));
	VISIBLE_COLS = 1 + (rand() % (COLS - 1));
	
	clearScreen();

	for(int i = 0; i < ROWS; ++i)
		for(int j = 0; j < COLS; ++j)
			MAP[i][j] = ' ';
	
	MAP[0][0] = '*';
}
