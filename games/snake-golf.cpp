#include <iostream>
#include <cstdlib>
#include <time.h>

using namespace std;

/* Global Variables */
const int ROWS = 40; 
const int COLS = 40;
char MAP[ROWS][COLS];

int VISIBLE_ROWS;
int VISIBLE_COLS;

int snake_col = 0;
int snake_row = 0;

int points = 0;

int apple_row = 0;
int apple_col = 0;

/* Function Prototypes */
void clearScreen();
void initialize();
void spawnApple();
void printMap();
void moveSnake(char dir);
char getUserInput();
void printBorder(char pos);

int main()
{
	initialize();
	
	while(snake_row < VISIBLE_ROWS && snake_col < VISIBLE_COLS && snake_row >= 0 & snake_col >= 0)
	{
		spawnApple();
		printMap();
		char dir = getUserInput();
		moveSnake(dir);
		clearScreen();
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
	if(snake_row == apple_row && snake_col == apple_col)
	{
		apple_row = rand() % VISIBLE_ROWS;
		apple_col = rand() % VISIBLE_COLS;
	
		MAP[apple_row][apple_col] = 'O';
	}
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

char getUserInput()
{
	char input;
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

	if(snake_row == apple_row && snake_col == apple_col)
	{
		points++;
		MAP[apple_row][apple_col] == ' ';	
	}
}

void printMap()
{
	cout << "POINTS: " << points << endl;
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
	VISIBLE_ROWS = 1 + rand() % (ROWS - 1);
	VISIBLE_COLS = 1 + rand() % (COLS - 1);
	
	clearScreen();

	for(int i = 0; i < ROWS; ++i)
		for(int j = 0; j < COLS; ++j)
			MAP[i][j] = ' ';
	
	MAP[0][0] = '*';
}
