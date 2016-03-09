module main;

import core.stdc.stdlib;
import std.algorithm;
import std.exception;
import std.random;
import std.stdio;
import std.string;
import std.typecons;

pragma (lib, "dallegro5");
pragma (lib, "allegro");
pragma (lib, "allegro_primitives");

import allegro5.allegro;
import allegro5.allegro_primitives;

immutable int MAX_X = 800;
immutable int MAX_Y = 600;
immutable int SIDE = 10;
immutable int LINE = 5;
immutable int BOARD_X = 50;
immutable int BOARD_Y = 50;
immutable int CELL_X = 50;
immutable int CELL_Y = 50;

alias Board = char [SIDE] [SIDE];

ALLEGRO_DISPLAY * display;
ALLEGRO_EVENT_QUEUE * event_queue;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void init ()
{
	enforce (al_init ());
	enforce (al_init_primitives_addon ());
	enforce (al_install_mouse ());

	display = al_create_display (MAX_X, MAX_Y);
	enforce (display);

	event_queue = al_create_event_queue ();
	enforce (event_queue);

	al_register_event_source (event_queue, al_get_mouse_event_source ());
	al_register_event_source (event_queue, al_get_display_event_source (display));
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void drawCell (int row, int col, char cell)
{
    int x = BOARD_X + col * CELL_X;
    int y = BOARD_Y + row * CELL_Y;
	al_draw_rectangle (x, y, x + CELL_X, y + CELL_Y, al_map_rgb_f (0.0, 1.0, 0.5), 2.5);
	if (cell == 'X')
    {
        al_draw_line (x + CELL_X * 0.2, y + CELL_Y * 0.2,
                      x + CELL_X * 0.8, y + CELL_Y * 0.8,
                      al_map_rgb_f (0.0, 1.0, 0.0), 10.0);
        al_draw_line (x + CELL_X * 0.2, y + CELL_Y * 0.8,
                      x + CELL_X * 0.8, y + CELL_Y * 0.2,
                      al_map_rgb_f (0.0, 1.0, 0.0), 10.0);
    }
    else if (cell == 'O')
    {
        al_draw_circle (x + CELL_X * 0.5, y + CELL_Y * 0.5, min (CELL_X, CELL_Y) * 0.35,
                        al_map_rgb_f (0.0, 0.0, 1.0), 10.0);
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void draw (const ref Board board)
{
	al_clear_to_color (al_map_rgb_f (0.5, 0.4, 0.3));
	foreach (row; 0..SIDE)
        foreach (col; 0..SIDE)
            drawCell (row, col, board[row][col]);
	al_flip_display ();
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void initBoard (ref Board board)
{
    foreach (row; 0..SIDE)
        foreach (col; 0..SIDE)
            board[row][col] = '.';
//    board[4][4] = 'O';
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
immutable int DIRS = 4;
immutable int [DIRS] DROW = [+1, +1, +1,  0];
immutable int [DIRS] DCOL = [+1,  0, -1, -1];
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
bool isValid (int row, int col)
{
    return (0 <= row && row < SIDE && 0 <= col && col < SIDE);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
bool wins (const ref Board board, int row, int col, char player)
{
/*
    (5, 2) X  res=1
    (6, 3) X  res=2
    (7, 4) .

    (5, 2) X  res=3
    (4, 1) X  res=4
    (3, 0) X  res=5
    (2, -1) ---
*/
    foreach (dir; 0..DIRS)
    {
        int res = -1;
        int crow;
        int ccol;

        crow = row;
        ccol = col;
        while (isValid (crow, ccol) && board[crow][ccol] == player)
        {
            res++;
            crow += DROW[dir];
            ccol += DCOL[dir];
        }

        crow = row;
        ccol = col;
        while (isValid (crow, ccol) && board[crow][ccol] == player)
        {
            res++;
            crow -= DROW[dir];
            ccol -= DCOL[dir];
        }

        if (res >= LINE)
            return true;
    }
    return false;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
bool tie (const ref Board board)
{
    foreach (row; 0..SIDE)
        foreach (col; 0..SIDE)
            if (board[row][col] == '.')
                return false;
    return true;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
bool moveMouse (ref Board board, int x, int y, char player)
{
    if (x < BOARD_X || BOARD_X + CELL_X * SIDE <= x)
    {
        return false;
    }
    if (y < BOARD_Y || BOARD_Y + CELL_Y * SIDE <= y)
    {
        return false;
    }
    int row = (y - BOARD_Y) / CELL_Y;
    int col = (x - BOARD_X) / CELL_X;
    if (board[row][col] != '.')
    {
        return false;    if (tie (board))
    {
        game_finished = true;
    }

    }
    board[row][col] = player;
    if (wins (board, row, col, player))
    {
        game_finished = true;
    }
    if (tie (board))
    {
        game_finished = true;
    }
    return true;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
int estimatePosOne (ref Board board, char player, int crow, int ccol)
{
    if (board[crow][ccol] != '.')
        return -1;
    int [LINE] counter;
    char enemy = cast (char)('X'+'O'-player);
    for (int d=0;d<DIRS; d++)
        for (int shift=-4; shift <=0; shift++)
        {
            int row = (crow + shift *DROW[d]);
            int col = (ccol + shift *DCOL[d]);
            int we = 0;
            int bad = 0;
            for (int num = 0; num < LINE; num++)
            {
                if (!isValid(row, col) || board[row][col] == enemy)
                {
                    bad++;
                }
                else if (board[row][col] == player)
                {
                    we++;
                }
                row += DROW[d];
                col += DCOL[d];
            }
            if (bad == 0)
            {
                counter[we]++;
            }
        }
    int es;
    for (int op =0; op<LINE;op++)
    es += counter[LINE - op-1] * 10 ^^ (LINE - op-1);
    return es;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
int estimatePos (ref Board board, char player, int crow, int ccol)
{
    char enemy = cast (char) ('X' + 'O' - player);
    return estimatePosOne (board, player, crow, ccol) +
        estimatePosOne (board, enemy, crow, ccol)/2;


}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
immutable long MULT = 10;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
long estimateBoard (const ref Board board, char player)
{
    char enemy = cast (char) ('X' + 'O' - player);
    long res = 0;
    foreach (row;0..SIDE)
        foreach (col;0..SIDE)
            res += estimateFromCell (board, player, row,col)-estimateFromCell (board,enemy,row,col)/MULT;
    return res;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
long estimateFromCell (const ref Board board, char player, int row, int col)
{
    char enemy = cast (char) ('X' + 'O' - player);
    long res = 0;
    foreach (d;0..DIRS)
    {
        int we = 0;
        int crow = row;
        int ccol = col;
        foreach (step;0..LINE)
        {
            if (!isValid (crow,ccol)||board[crow][ccol]==enemy)
            {
                we = -1;
                break;
            }
            we += (board [crow][ccol]==player);
            crow += DROW [d];
            ccol += DCOL [d];
        }
    if (we >= 0)
        res += MULT ^^ (2 * we);
    }
return res;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
alias Move = Tuple!(long,"value",int,"row",int,"col");

Move pickMove (ref Board board, char player, int depth)
{
    char enemy = cast (char) ('X' + 'O' - player);
    Move res = Move (long.min / 2, -1,-1);
    foreach (row; 0..SIDE)
        foreach (col; 0..SIDE)
        {
            if (board [row][col]=='.')
            {
                board[row][col] = player;
                scope (exit)
                {
                    board [row][col]='.';
                }
                long cur ;
                if (wins(board, row, col, player))
                    cur = long.max / 2;
                else if (tie (board))
                    cur = 0;
                else if (depth >0)
                    cur = -pickMove (board, enemy, depth-1).value;
                else
                    cur = -estimateBoard (board, enemy);
                if (res.value < cur)
                    res = Move (cur,row,col);
            }
        }
    return res;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void moveAI (ref Board board, char player)
{
    int spot=-1;
    int row=-1,col=-1;
/*
    do
    {
        row = uniform (0, SIDE);
        col = uniform (0, SIDE);
    }
    while (board[row][col] != '.');
*/
    for (int crow = 0; crow < SIDE; crow++)
    {
        for (int ccol = 0; ccol < SIDE; ccol++)
        {
            if (board[crow][ccol] == '.')
            {
                int estimate = estimatePos (board, player, crow, ccol);
                if (estimate > spot)
                {
                    spot = estimate;
                    row = crow;
                    col = ccol;
                }
            }
        }
    }
    board[row][col] = player;

    if (wins (board, row, col, player))
    {
        game_finished = true;
    }
    if (tie (board))
    {
        game_finished = true;
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void moveAI2 (ref Board board, char player)
{
    Move bestMove = pickMove (board, player, 1);
    int row = bestMove.row;
    int col = bestMove.col;
    board[row][col] = player;

    if (wins (board, row, col, player))
    {
        game_finished = true;
    }
    if (tie (board))
    {
        game_finished = true;
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void tryMoveMouse (ref Board board, int x, int y, char player)
{
    if (moveMouse (board, x, y, player))
    {
        draw (board);
        if (!game_finished)
        {
            char enemy = cast (char) ('X' + 'O' - player);
            moveAI (board, enemy);
        }
    }
}

bool game_finished;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main_loop ()
{
    Board board;
    initBoard (board);

	draw (board);

	game_finished = false;
	while (!game_finished)
	{
		ALLEGRO_EVENT current_event;
		al_wait_for_event (event_queue, &current_event);

		switch (current_event.type)
		{
			case ALLEGRO_EVENT_DISPLAY_CLOSE:
				happy_end ();
				break;

			case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
				int x = current_event.mouse.x;
				int y = current_event.mouse.y;
				tryMoveMouse (board, x, y, 'X');
				break;

			default:
				break;
		}

		draw (board);
	}
	while (true)
	{
		ALLEGRO_EVENT current_event;
		al_wait_for_event (event_queue, &current_event);

		switch (current_event.type)
		{
			case ALLEGRO_EVENT_DISPLAY_CLOSE:
				happy_end ();
				break;

			default:
				break;
		}

		draw (board);
	}
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void happy_end ()
{
	al_destroy_display (display);
	al_destroy_event_queue (event_queue);

	al_shutdown_primitives_addon ();

	exit (EXIT_SUCCESS);
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
int main (string [] args)
{
	return al_run_allegro (
	{
		init ();
		main_loop ();
		happy_end ();
		return 0;
	});
}
