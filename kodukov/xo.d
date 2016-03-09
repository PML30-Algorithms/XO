module main;

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

immutable int MAX_X = 800;
immutable int MAX_Y = 600;

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

	global_font = al_load_ttf_font ("CONSOLA.TTF", 72, 0);

	al_register_event_source (event_queue, al_get_mouse_event_source ());
	al_register_event_source (event_queue, al_get_display_event_source (display));
}

void draw (const ref Board board)
{
    immutable ALLEGRO_COLOR BACKGROUND = al_map_rgb_f (0.9, 0.9, 0.9);

	al_clear_to_color (BACKGROUND);
    for (int row = 0; row < SIDE; row++)
        for (int col = 0; col < SIDE; col++)
        {
            bool light = false;
            char player = board[row][col];
            if (player != '.')
            {
               char enemy = cast (char) ('X' + 'O' - player);
              for (int d = 0; d < DIRS; d++)
                for (int shift = -4; shift <= 0; shift ++ )
                  {
                     int row2 = (row + shift * DROW[d]);
                     int col2 = (col + shift * DCOL[d]);
                     int bad = 0;
                     int we = 0;
                     for (int i = 0; i < LINE; i++)
                     {
                         if (!valid (row2, col2) || board[row2][col2] == enemy)
                            bad++;
                         else if (board[row2][col2] == player)
                            we++;
                         row2 += DROW[d];
                         col2 += DCOL[d];
                     }
                     if (bad == 0)
                     {
                        if (we >= 3)
                        {
                            light = true;
                        }
                     }
                  }
            }
            int curx = BOARD_X + col * CELL_X;
            int cury = BOARD_Y + row * CELL_Y;
            if (light)
                al_draw_filled_rectangle (curx, cury, curx + CELL_X, cury + CELL_Y,
                                          al_map_rgb_f (1, 1, 0.5));
            al_draw_rectangle (curx, cury, curx + CELL_X, cury + CELL_Y,
                               al_map_rgb_f (0, 0, 0), 2.5);
            if (board[row][col] == 'X')
            {
                al_draw_line (curx + 10, cury + 10, curx + 40, cury + 40,
                              al_map_rgb_f (0.4, 0.6, 0.4), 10);
                al_draw_line (curx + 10, cury + 40, curx + 40, cury + 10,
                              al_map_rgb_f (0.4, 0.6, 0.4), 10);
            }
            if (board[row][col] == 'O')
            {
                al_draw_circle (curx + 25, cury + 25, 17.5,
                              al_map_rgb_f (0.6, 0.4, 0.6), 10);
            }
        }
    if (tie (board))
       al_draw_text (global_font, al_map_rgb (255,0,0), 680, (300), ALLEGRO_ALIGN_CENTRE, "TIE");
    if (wins (board, 'X'))
       al_draw_text (global_font, al_map_rgb (255,0,0), 680, (300), ALLEGRO_ALIGN_CENTRE, "X WINS");
    if (wins (board, 'O'))
       al_draw_text (global_font, al_map_rgb (255,0,0), 680, (300), ALLEGRO_ALIGN_CENTRE, "O WINS");
	al_flip_display ();
}

immutable int SIDE = 10;
immutable int LINE = 5;
immutable int DIRS = 4;
immutable int [DIRS] DROW =[0, +1, +1, +1];
immutable int [DIRS] DCOL =[+1, +1, 0, -1];

alias Board = char [SIDE] [SIDE];

void initBoard (ref Board board)
{
    for (int row = 0; row < SIDE; row++)
        for (int col = 0; col < SIDE; col++)
            board[row][col] = '.';
}

bool wins(const ref Board board, char player)
{
    for (int row = 0; row < SIDE; row++)
        for (int col = 0; col < SIDE; col++)
            if (winsCell (board, player, row, col))
                return true;
    return false;
}

bool tie(const ref Board board)
{
   for (int row = 0; row < SIDE; row++)
        for (int col = 0; col < SIDE; col++)
            if (board[row][col] == '.')
                return false;
    return true;
}

bool winsCell(const ref Board board, char player, int crow, int ccol)
{

  for (int d=0; d<DIRS; d++)
  {
      int res = -1;
      int row = crow;
      int col = ccol;
      while ( valid (row, col) && board[row][col] == player)
      {
          res++;
          row += DROW[d];
          col += DCOL[d];
      }
      row = crow;
      col = ccol;
      while ( valid (row, col) && board[row][col] == player)
      {
          res++;
          row -= DROW[d];
          col -= DCOL[d];
      }
      if (res >= LINE)
        return true;
  }
  return false;
}

bool valid (int row, int col)
{
    return (0 <= row && row < SIDE) && (0 <= col && col < SIDE);
}

int estimatePosOne (ref Board board, char player, int crow, int ccol)
{
    if (board[crow][ccol] != '.')
    {
        return -1;
    }
    char enemy = cast (char) ('X' + 'O' - player);
    int [LINE] counter;
  for (int d = 0; d < DIRS; d++)
    for (int shift = -4; shift <= 0; shift ++ )
      {
         int row = (crow + shift * DROW[d]);
         int col = (ccol + shift * DCOL[d]);
         int bad = 0;
         int we = 0;
         for (int i = 0; i < LINE; i++)
         {
             if (!valid (row, col) || board[row][col] == enemy)
                bad++;
             else if (board[row][col] == player)
                we++;
             row += DROW[d];
             col += DCOL[d];
         }
         if (bad == 0)
         {
             counter[we]++;
         }
      }
      int res = 0;
      int z = 1;
      for(int i = 0; i < LINE; i++)
      {
          res += counter[i] * z;
          z *= 10;
      }
        return res;
    }

int estimatePos (ref Board board, char player, int crow, int ccol)
{
    char enemy = cast (char) ('X' + 'O' - player);
    return estimatePosOne (board, player, crow, ccol) +
        estimatePosOne (board, enemy, crow, ccol) / 2;
}

void moveAI1(ref Board board, char player)
{
    char enemy = cast (char) ('X' + 'O' - player);
    int bestrow = 0;
    int bestcol = 0;
    int bestest = -1;
    for (int crow = 0; crow < SIDE; crow++)
        for (int ccol = 0; ccol < SIDE; ccol++)
        {
            int est = estimatePos (board, player, crow, ccol);
            if (bestest < est)
            {
                bestest = est;
                bestrow = crow;
                bestcol = ccol;
            }
        }

    writeln (bestrow + 1, ' ', bestcol + 1);
    board[bestrow][bestcol] = player;
}

bool is_finished = false;

immutable int BOARD_X = 50;
immutable int BOARD_Y = 50;
immutable int CELL_X = 50;
immutable int CELL_Y = 50;

void moveMouse (ref Board board, int x, int y)
{
    if (x < BOARD_X || BOARD_X + SIDE * CELL_X <= x)
        return;
    if (y < BOARD_Y || BOARD_Y + SIDE * CELL_Y <= y)
        return;
    int row = (y - BOARD_Y) / CELL_Y;
    int col = (x - BOARD_X) / CELL_X;
    if (board[row][col] != '.')
        return;
    board[row][col] = 'X';
    draw (board);
    if (wins (board, 'X'))
    {
         writeln ("X wins");
         is_finished = true;
         return;
    }
    if (tie (board))
    {
         writeln("draw");
         is_finished = true;
         return;
    }
    moveAI1 (board, 'O');
    draw (board);
    if (wins (board, 'O'))
    {
         writeln ("O wins");
         is_finished = true;
         return;
    }
    if (tie (board))
    {
         writeln("draw");
         is_finished = true;
         return;
   }
}

void main_loop ()
{
    Board board;
    initBoard (board);
    draw (board);

	is_finished = false;
	while (!is_finished)
	{
		ALLEGRO_EVENT current_event;
		al_wait_for_event (event_queue, &current_event);

		switch (current_event.type)
		{
		    case ALLEGRO_EVENT_DISPLAY_SWITCH_IN:
                draw (board);
                break;

			case ALLEGRO_EVENT_DISPLAY_CLOSE:
				is_finished = true;
				return;

			case ALLEGRO_EVENT_MOUSE_BUTTON_UP:
				int x = current_event.mouse.x;
				int y = current_event.mouse.y;
				moveMouse (board, x, y);
				break;

			default:
				break;
		}

//		draw (board);
	}

	is_finished = false;
	while (!is_finished)
	{
		ALLEGRO_EVENT current_event;
		al_wait_for_event (event_queue, &current_event);

		switch (current_event.type)
		{
			case ALLEGRO_EVENT_DISPLAY_CLOSE:
				is_finished = true;
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
