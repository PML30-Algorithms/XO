module main;

import std.stdio;
import std.algorithm;
import std.math;



import std.datetime;
import std.concurrency;
import std.range;import std.typecons;
import core.stdc.stdlib;
import std.exception;
import std.stdio;
import std.string;
pragma (lib, "dallegro5");
pragma (lib, "allegro");

pragma (lib, "allegro_primitives");

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_font;
import allegro5.allegro_ttf;

alias Board = char [SIDE] [SIDE];
alias Move = Tuple !(long, "value", int, "row", int, "col");


immutable int BOARD_X = 50;
immutable int BOARD_Y = 50;

immutable int CELL_X = 50;
immutable int CELL_Y = 50;

immutable int SIDE = 15;
immutable int LINE = 5;
immutable long MULT = 3;


immutable int DIRS = 4;
immutable char player = 'X';
immutable int [DIRS] Drow=[0,+1,+1,+1];
immutable int [DIRS] Dcol=[+1,+1,0,-1];


immutable int MAX_X = 1000;
immutable int MAX_Y = 1000;

ALLEGRO_DISPLAY * display;
ALLEGRO_EVENT_QUEUE * event_queue;
ALLEGRO_FONT * global_font;

void init ()
{
	enforce (al_init ());
	enforce (al_init_primitives_addon ());
	enforce (al_install_mouse ());
	al_init_font_addon ();
	enforce (al_init_ttf_addon ());

	display = al_create_display (MAX_X, MAX_Y);
	enforce (display);

	event_queue = al_create_event_queue ();
	enforce (event_queue);

	global_font = al_load_ttf_font ("CONSOLA.TTF", 24, 0);

	al_register_event_source (event_queue, al_get_mouse_event_source ());
	al_register_event_source (event_queue, al_get_display_event_source (display));
}



void initBoard (ref Board board)
{
	for (int row = 0; row < SIDE; row++)
	{
		for (int col = 0; col < SIDE; col++)
		{
			board[row][col] = '-';
		}
	}

}
bool Light (const ref Board board, int crow, int ccol,char player)
{
    char enemy = cast (char)('X'+'O'-player);
    for (int d=0;d<DIRS; d++)
        for (int shift=-4; shift <=0; shift++)
        {
            int row = (crow + shift *Drow[d]);
            int col = (ccol + shift *Dcol[d]);
            int we = 0;
            int bad = 0;
            for (int num = 0; num < LINE; num++)
            {
                if (!valid(row, col) || board[row][col] == enemy)
                {
                    bad++;
                }
                else if (board[row][col] == player)
                {
                    we++;
                }
                row += Drow[d];
                col += Dcol[d];
            }
            if (bad == 0)
            {
                if (we > 2)
                    return true;
            }

        }
    return false;

}

void draw (const ref Board board)
{
	al_clear_to_color (al_map_rgb_f (128,128,128));
	for (int row = 0; row < SIDE; row++)
        for (int col = 0; col < SIDE; col++)
            drawCell (board,row, col, board[row][col]);
	if (tie (board))
       al_draw_text (global_font, al_map_rgb (255,0,0), 680, (300), ALLEGRO_ALIGN_CENTRE, "DRAW");
    if (wins (board, 'X'))
       al_draw_text (global_font, al_map_rgb (255,0,0), 680, (300), ALLEGRO_ALIGN_CENTRE, "X WINS");
    if (wins (board, 'O'))
       al_draw_text (global_font, al_map_rgb (255,0,0), 680, (300), ALLEGRO_ALIGN_CENTRE, "O WINS");
	al_flip_display ();
}

void drawCell (const ref Board board,int row, int col, char cell)
{
    int we = 0;
    int light;
    int curx = BOARD_X + col * CELL_X;
    int cury = BOARD_Y + row * CELL_Y;


    if (Light(board,row,col,'X')|| Light(board,row,col,'O') )
        light = true;
    else
        light = false;


    if (light == true)
        al_draw_filled_rectangle(curx,cury, curx+CELL_X,cury + CELL_Y, al_map_rgb_f(1,0,0));
    else
        al_draw_rectangle(curx-1,cury-1,curx + CELL_X-1,cury + CELL_Y-1, al_map_rgb_f(0,255,255),2.5);
    if (cell == 'X')
    {
        al_draw_line(curx+10,cury + 10, curx + 40, cury +40, al_map_rgb_f(0,0,153),5);
        al_draw_line(curx+10,cury + 40, curx + 40, cury +10, al_map_rgb_f(0,0,153),5);
    }
    else if (cell == 'O')
        al_draw_circle(curx +25, cury +25, 17.5, al_map_rgb_f(0,153,0),5);
}

bool is_finished;

void moveHuman (ref Board board, char player)
{
    bool local_finished = false;
    while (!local_finished)
    {
        ALLEGRO_EVENT current_event;
        al_wait_for_event (event_queue, &current_event);

        switch (current_event.type)
        {
            case ALLEGRO_EVENT_DISPLAY_CLOSE:
                happy_end ();
                break;

            case ALLEGRO_EVENT_DISPLAY_SWITCH_IN:
                draw (board);
                break;

            case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
                int x = current_event.mouse.x;
                int y = current_event.mouse.y;
                if (moveMouse (board, player, x, y))
                {
                    local_finished = true;
                }
                break;

            default:
                break;
        }
    }
}

void moveX (ref Board board)
{
    moveHuman (board, 'X');
}

void moveO (ref Board board)
{
    moveAI2 (board, 'O');
}

void main_loop ()
{

    Board board;
    initBoard (board);
    is_finished = false;




	while (true)
	{
	    draw (board);
	    moveX (board);
	    if (is_finished) break;
	    draw (board);
	    moveO (board);
	    if (is_finished) break;
	}
    draw (board);

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
    }
}

void happy_end ()
{
	al_destroy_display (display);
	al_destroy_event_queue (event_queue);
	al_destroy_font (global_font);

	al_shutdown_ttf_addon ();
	al_shutdown_font_addon ();
	al_shutdown_primitives_addon ();

	exit (EXIT_SUCCESS);
}



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



bool moveMouse (ref Board board, char player, int x, int y)
{
    immutable char enemy = cast (char) ('X' + 'Y' - player);
    if (x < BOARD_X || BOARD_X + SIDE *CELL_X <= x)
        return false;
    if (y < BOARD_Y|| BOARD_Y+ SIDE *CELL_Y <= y)
        return false;
    int row = (y - BOARD_Y) / CELL_Y;
    int col = (x - BOARD_X) / CELL_X;
    if (board[row][col] != '-')
        return false;
    board [row][col] = player;

    if (wins (board, player))
    {
        writeln ("Player wins");
        is_finished = true;
        return true;
    }
     if (tie (board))
    {
        writeln ("DRAW");
        is_finished = true;
        return true;
    }
    return true;
}





int estimatePosOne (ref Board board, char player, int crow, int ccol)
{
    if (board[crow][ccol] != '-')
        return -1;
    int [LINE] counter;
    char enemy = cast (char)('X'+'O'-player);
    for (int d=0;d<DIRS; d++)
        for (int shift=-4; shift <=0; shift++)
        {
            int row = (crow + shift *Drow[d]);
            int col = (ccol + shift *Dcol[d]);
            int we = 0;
            int bad = 0;
            for (int num = 0; num < LINE; num++)
            {
                if (!valid(row, col) || board[row][col] == enemy)
                {
                    bad++;
                }
                else if (board[row][col] == player)
                {
                    we++;
                }
                row += Drow[d];
                col += Dcol[d];
            }
            if (bad == 0)
            {
                counter[we]++;
            }
        }
    int es;
    for (int op =0; op<LINE;op++)
    es += counter[LINE - op-1] * 81 ^^ (LINE - op-1);
    return es;
}


int estimatePos (ref Board board, char player, int crow, int ccol)
{
    char enemy = cast (char) ('X' + 'O' - player);
    return estimatePosOne (board, player, crow, ccol) +
        estimatePosOne (board, enemy, crow, ccol)/2;
}


long EstimateMoveBoard (ref Board board, char player, int crow, int ccol)
{
    long res;
    if (board[crow][ccol] != '-')
        return -1;
    int [LINE] counter;
    char enemy = cast (char)('X'+'O'-player);
    for (int d=0;d<DIRS; d++)
        for (int shift=-4; shift <=0; shift++)
        {
            int row = (crow + shift *Drow[d]);
            int col = (ccol + shift *Dcol[d]);
            int we = 0;
            int bad = 0;
            for (int num = 0; num < LINE; num++)
            {
                if (!valid(row, col) || board[row][col] == enemy)
                {
                    bad++;
                }
                else if (board[row][col] == player)
                {
                    we++;
                }
                row += Drow[d];
                col += Dcol[d];
            }
            if (bad == 0)
                counter[we]++;
        }
    long est = 0;
    for (int op = 0; op<LINE;op++)
        est += counter[op] * 81L ^^ op;
    return est;
}


int EstimateFromCell (ref Board board, char player, int row, int col)
{
    char enemy = cast (char) ('X'+'O'-player);
    int res;
    foreach(d;0..
     DIRS)
    {
        int we=0;
        int crow=row;
        int ccol=col;
        foreach ( step; 0..LINE)
        {
            if (!valid (crow,ccol)  || board[crow][ccol] == enemy)
            {we = -1; break;}
            we += (board[crow][ccol] == player);
            crow += Drow[d]; ccol += Dcol[d];
        }
        if (we >= 0)
            res += MULT ^^ (2*we);
    }
    return res;
}


Move pickMoveSaved (ref Board board, char player, int depth)
{
    char enemy = cast (char) ('X'+'O'-player);
    auto res = Move (long.min / 2, -1, -1);
    foreach (row;0..SIDE)
        foreach (col;0..SIDE)
            if (board[row][col] == '-')
            {
                board[row][col] = player;
                long cur;
                if (wins(board, player))
                    cur = long.max / 2;
                else if (tie(board))
                    cur=0;
                else if (depth > 0)
                    cur = -pickMove (board, enemy, depth -1).value;
                else
                    cur = EstimateBoardPlayer (board,player);
                if (res.value < cur)
                    res = Move(cur,row,col);
                board[row][col] = '-';
            }
    return res;
}

immutable int DEPTH = 7;
immutable int WIDTHS [DEPTH+1] = [10,10, 5,  2, 2, 2, 1,1];
Move pickMove (ref Board board, char player, int depth)
{
    int i,t,l;
    int space;
    space = SIDE*SIDE;

    auto a = new Move [WIDTHS[depth]];

    foreach (ref curMove; a[])
    {
        curMove.value = long.min / 2;
    }

    char enemy = cast (char) ('X'+'O'-player);
    auto res = Move (long.min / 2, -1, -1);
    foreach (row;0..SIDE)
        foreach (col;0..SIDE)
            if (board[row][col] == '-')
            {
                auto curValue = EstimateMoveBoard (board, player, row, col) +
                    EstimateMoveBoard (board, enemy, row, col)/9 ;
                if (a[].minPos.front.value < curValue)
                {
                    a[].minPos.front = Move (curValue, row, col);
                }
            }

    foreach (curMove; a[])
    {
        int row = curMove.row;
        int col = curMove.col;
        if (board[row][col] == '-')
        {
            board[row][col] = player;
            long cur;
            if (wins(board, player))
                cur = long.max / 2;
            else if (tie(board))
                cur=0;
            else if (depth > 0)
                cur = -pickMove (board, enemy, depth -1).value;
            else
                cur = EstimateBoardPlayer (board,player);
            if (res.value < cur)
                res = Move(cur,row,col);
            board[row][col] = '-';
        }
    }

    return res;
}


long EstimateBoard (ref Board board, char player)
{
    char enemy = cast (char) ('X'+'O' - player);
    long res = 0;

    foreach (row;0..SIDE)
        foreach (col;0..SIDE)
            res += EstimateFromCell(board,player,row,col) * MULT - EstimateFromCell(board,enemy,row,col);
     return res;
}

long EstimateBoardPlayer (ref Board board, char player)
{
    char enemy = cast (char) ('X'+'O' - player);
    long res = 0;

    foreach (row;0..SIDE)
        foreach (col;0..SIDE)
        {
            for (int d=0;d<DIRS; d++)
            {
                for (int crow;crow<SIDE;crow++)
                    for (int ccol;ccol< SIDE;ccol++)
                    {
                        int x = 10 - std.math.abs (row - crow) - std.math.abs (col - ccol);
                        if (x < 0) continue;
                        if (board[row][col] == player)
                            res += MULT ^^ x;
                        if (board[row][col] == enemy)
                            res += (MULT/2) ^^ x;
                    }
            }
            res += EstimateFromCell(board,player,row,col) * MULT + EstimateFromCell(board,enemy,row,col);
        }
     return res;
}


void realmoveAI2 (Tid FatherID, Board board, char player)
{
  auto move = pickMove (board, player, DEPTH);
  send(FatherID,move);
}


void moveAI2 (ref Board board, char player)
{
    spawn(&realmoveAI2, thisTid() ,board,player);
    Move move;
    float time = 0.01;
    while (true)
    {
        if (receiveTimeout(
                   1.msecs,(Move n) {move = n;}
            ))
            break;


            ALLEGRO_EVENT current_event;

            al_wait_for_event_timed(event_queue, &current_event, time);

            switch (current_event.type)
            {
                case ALLEGRO_EVENT_DISPLAY_CLOSE:
                    happy_end ();
                    break;


                case ALLEGRO_EVENT_DISPLAY_SWITCH_IN:
                    draw (board);
                    break;

                case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
                    writeln ("NOT YOUR TURN");
                    break;

                default:
                    break;
            }

    }
    int row = move.row;
    int col = move.col;
    writeln (row + 1, " ", col + 1);
    board[row][col] = player;

    if (wins (board, player))
    {
        writeln ("Computer wins");
        is_finished = true;
        return;
    }
     if (tie (board))
    {
        writeln ("DRAW");
        is_finished = true;
        return;
    }

}



void moveAI (ref Board board, char player)
{
    int spot=-1;
    int row,col;
    for (int crow = 0; crow < SIDE; crow++)
    {
        for (int ccol = 0; ccol < SIDE; ccol++)
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
    writeln (row + 1, " ", col + 1);
    board[row][col] = player;

    if (wins (board, player))
    {
        writeln ("Computer wins");
        is_finished = true;
        return;
    }
     if (tie (board))
    {
        writeln ("DRAW");
        is_finished = true;
        return;
    }
}



bool valid (int row,int col)
    {
        return (0<= row && row < SIDE) && (0<= col && col < SIDE);
    }


bool wins (Board board, char player)
{
    for (int row=0; row < SIDE; row++)
        for (int col = 0;col < SIDE; col++)
            if (winsCell ( board, player, row, col))
                return true;
    return false;
}

bool tie (const ref Board board)
{
	for (int row = 0; row < SIDE; row++)
	{
		for (int col = 0; col < SIDE; col++)
		{
			if (board[row][col] == '-')
			{
				return false;
			}
		}
	}
	return true;
}



bool winsCell (ref Board board, char player , int crow, int ccol)
{
    for ( int d=0; d<DIRS; d++)
    {
        int res =-1;
        int col = ccol;
        int row = crow;
        while (valid (row,col) && board[row][col] == player)
        {
            res++;
            row += Drow[d];
            col += Dcol[d];
        }
        row = crow;
        col = ccol;
        while (valid (row,col) && board[row][col] == player)
        {
            res++;
            row -= Drow[d];
            col -= Dcol[d];
        }

        if (res>= LINE) return true;

    }
    return false;
}

