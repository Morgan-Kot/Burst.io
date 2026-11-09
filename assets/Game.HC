// ============================================================================
// COSMIC DEFENDER - A 2D Arcade Space Shooter in HolyC
// Target: TempleOS / Ring 0 64-bit
// Controls: [LEFT / RIGHT / UP / DOWN] Move, [SPACE] Fire, [ESC] Quit / Restart
// ============================================================================

#define SCREEN_W        640
#define SCREEN_H        480

#define MAX_STARS       60
#define MAX_BULLETS     8
#define MAX_ENEMIES     10

#define SHIP_SPEED      6
#define BULLET_SPEED    12
#define SHIP_W          16
#define SHIP_H          12

// Game states
#define GS_PLAYING      0
#define GS_GAME_OVER    1

class CStar {
  I64 x, y;
  I64 speed;
  I64 color;
};

class CBullet {
  Bool active;
  I64  x, y;
};

class CEnemy {
  Bool active;
  I64  x, y;
  I64  vx, vy;
  I64  health;
  I64  color;
};

// Global game state variables
CStar   g_stars[MAX_STARS];
CBullet g_bullets[MAX_BULLETS];
CEnemy  g_enemies[MAX_ENEMIES];

I64 g_ship_x;
I64 g_ship_y;
I64 g_score;
I64 g_high_score = 0;
I64 g_lives;
I64 g_game_state;
I64 g_sound_timer;

// ----------------------------------------------------------------------------
// INITIALIZATION & SPAWN LOGIC
// ----------------------------------------------------------------------------

U0 InitStars()
{
  I64 i;
  for (i = 0; i < MAX_STARS; i++) {
    g_stars[i].x = RandU16 % SCREEN_W;
    g_stars[i].y = RandU16 % SCREEN_H;
    g_stars[i].speed = (RandU16 % 3) + 1;
    if (g_stars[i].speed == 1)      g_stars[i].color = DKGRAY;
    else if (g_stars[i].speed == 2) g_stars[i].color = LTGRAY;
    else                            g_stars[i].color = WHITE;
  }
}

U0 SpawnEnemy(I64 i)
{
  g_enemies[i].active = TRUE;
  g_enemies[i].x      = RandU16 % (SCREEN_W - 40) + 20;
  g_enemies[i].y      = -(RandU16 % 100) - 20;
  g_enemies[i].vx     = (RandU16 % 5) - 2; // Drift left/right: -2 to 2
  g_enemies[i].vy     = (RandU16 % 3) + 2; // Fall speed: 2 to 4
  g_enemies[i].health = 1;
  g_enemies[i].color  = RED + (RandU16 % 3); // RED, LTRED, or PURPLE
}

U0 ResetGame()
{
  I64 i;
  g_ship_x     = SCREEN_W / 2;
  g_ship_y     = SCREEN_H - 60;
  g_score      = 0;
  g_lives      = 3;
  g_game_state = GS_PLAYING;
  g_sound_timer= 0;

  for (i = 0; i < MAX_BULLETS; i++)
    g_bullets[i].active = FALSE;

  for (i = 0; i < MAX_ENEMIES; i++)
    SpawnEnemy(i);
}

// ----------------------------------------------------------------------------
// SOUND & WEAPON HELPERS
// ----------------------------------------------------------------------------

U0 PlayTone(I64 freq, I64 duration_ticks)
{
  Sound(freq);
  g_sound_timer = duration_ticks;
}

U0 FireBullet()
{
  I64 i;
  for (i = 0; i < MAX_BULLETS; i++) {
    if (!g_bullets[i].active) {
      g_bullets[i].active = TRUE;
      g_bullets[i].x      = g_ship_x;
      g_bullets[i].y      = g_ship_y - SHIP_H;
      PlayTone(74, 2); // Quick chirp for blaster fire
      break;
    }
  }
}

// ----------------------------------------------------------------------------
// GRAPHICS RENDER CALLBACK
// Called automatically each frame by the TempleOS window manager
// ----------------------------------------------------------------------------

U0 DrawGame(CTask *task, CDC *dc)
{
  I64 i;

  // 1. Draw Starfield
  for (i = 0; i < MAX_STARS; i++) {
    dc->color = g_stars[i].color;
    GrPlot(dc, g_stars[i].x, g_stars[i].y);
  }

  // 2. Draw Bullets
  dc->color = YELLOW;
  for (i = 0; i < MAX_BULLETS; i++) {
    if (g_bullets[i].active) {
      GrRect(dc, g_bullets[i].x - 1, g_bullets[i].y - 4, 3, 8);
    }
  }

  // 3. Draw Enemies (Invader UFOs)
  for (i = 0; i < MAX_ENEMIES; i++) {
    if (g_enemies[i].active) {
      dc->color = g_enemies[i].color;
      // UFO Hull & Dome
      GrCircle(dc, g_enemies[i].x, g_enemies[i].y, 10);
      GrLine(dc, g_enemies[i].x - 14, g_enemies[i].y, 
                 g_enemies[i].x + 14, g_enemies[i].y);
      dc->color = CYAN;
      GrPlot(dc, g_enemies[i].x, g_enemies[i].y - 3);
    }
  }

  // 4. Draw Player Ship
  if (g_game_state == GS_PLAYING) {
    dc->color = CYAN;
    // Triangle hull
    GrLine(dc, g_ship_x, g_ship_y - SHIP_H, g_ship_x - SHIP_W, g_ship_y + SHIP_H);
    GrLine(dc, g_ship_x, g_ship_y - SHIP_H, g_ship_x + SHIP_W, g_ship_y + SHIP_H);
    GrLine(dc, g_ship_x - SHIP_W, g_ship_y + SHIP_H, g_ship_x + SHIP_W, g_ship_y + SHIP_H);
    
    // Engine Thruster flame
    dc->color = LTRED;
    GrLine(dc, g_ship_x - 4, g_ship_y + SHIP_H, g_ship_x, g_ship_y + SHIP_H + 6);
    GrLine(dc, g_ship_x + 4, g_ship_y + SHIP_H, g_ship_x, g_ship_y + SHIP_H + 6);
  }

  // 5. HUD Overlay
  dc->color = WHITE;
  GrPrint(dc, 16, 16, "SCORE: %06d", g_score);
  GrPrint(dc, 200, 16, "HIGH:  %06d", g_high_score);
  
  dc->color = GREEN;
  GrPrint(dc, 400, 16, "LIVES: ");
  for (i = 0; i < g_lives; i++) {
    GrPrint(dc, 460 + (i * 18), 16, "^");
  }

  // 6. Game Over Screen
  if (g_game_state == GS_GAME_OVER) {
    dc->color = RED;
    GrPrint(dc, SCREEN_W / 2 - 40, SCREEN_H / 2 - 20, "GAME OVER");
    dc->color = YELLOW;
    GrPrint(dc, SCREEN_W / 2 - 95, SCREEN_H / 2 + 10, "Press [SPACE] to Restart");
    GrPrint(dc, SCREEN_W / 2 - 80, SCREEN_H / 2 + 25, "Press [ESC] to Exit");
  }
}

// ----------------------------------------------------------------------------
// GAME UPDATE LOOP (PHYSICS & COLLISIONS)
// ----------------------------------------------------------------------------

U0 UpdateGame()
{
  I64 i, j;

  // Update background stars
  for (i = 0; i < MAX_STARS; i++) {
    g_stars[i].y += g_stars[i].speed;
    if (g_stars[i].y >= SCREEN_H) {
      g_stars[i].y = 0;
      g_stars[i].x = RandU16 % SCREEN_W;
    }
  }

  // Handle sound decay
  if (g_sound_timer > 0) {
    g_sound_timer--;
    if (g_sound_timer == 0) Sound; // Turn off PC speaker
  }

  if (g_game_state != GS_PLAYING) return;

  // Move active bullets
  for (i = 0; i < MAX_BULLETS; i++) {
    if (g_bullets[i].active) {
      g_bullets[i].y -= BULLET_SPEED;
      if (g_bullets[i].y < 0) {
        g_bullets[i].active = FALSE;
      }
    }
  }

  // Move enemies and check collisions
  for (i = 0; i < MAX_ENEMIES; i++) {
    if (!g_enemies[i].active) {
      SpawnEnemy(i);
      continue;
    }

    g_enemies[i].x += g_enemies[i].vx;
    g_enemies[i].y += g_enemies[i].vy;

    // Bounce off horizontal borders
    if (g_enemies[i].x <= 20 || g_enemies[i].x >= SCREEN_W - 20) {
      g_enemies[i].vx = -g_enemies[i].vx;
    }

    // Wrap-around if reaching screen bottom
    if (g_enemies[i].y >= SCREEN_H + 20) {
      SpawnEnemy(i);
    }

    // Bullet-to-Enemy collision checks (AABB)
    for (j = 0; j < MAX_BULLETS; j++) {
      if (g_bullets[j].active) {
        if (AbsI64(g_bullets[j].x - g_enemies[i].x) < 14 &&
            AbsI64(g_bullets[j].y - g_enemies[i].y) < 12) {
          
          g_bullets[j].active = FALSE;
          g_score += 100;
          if (g_score > g_high_score) g_high_score = g_score;
          
          PlayTone(38, 4); // Low crunch explosion tone
          SpawnEnemy(i);
          break;
        }
      }
    }

    // Enemy-to-Ship collision check
    if (AbsI64(g_ship_x - g_enemies[i].x) < (SHIP_W + 8) &&
        AbsI64(g_ship_y - g_enemies[i].y) < (SHIP_H + 8)) {
      
      PlayTone(20, 10); // Heavy death sound
      SpawnEnemy(i);
      g_lives--;

      if (g_lives <= 0) {
        g_game_state = GS_GAME_OVER;
      }
    }
  }
}

// ----------------------------------------------------------------------------
// MAIN LOOP & INPUT HANDLER
// ----------------------------------------------------------------------------

public U0 CosmicDefender()
{
  I64 scancode = 0;
  I64 ch = 0;

  // Clear DolDoc buffer and hide text cursor
  DocClear;
  DocCursor(FALSE);

  InitStars;
  ResetGame;

  // Assign HolyC window manager draw callback to task
  Fs->draw_it = &DrawGame;

  try {
    while (TRUE) {
      // Non-blocking key scanner
      if (ScanKey(&scancode, &ch)) {
        if (ch == CH_ESC) break;

        // Restart trigger during Game Over
        if (g_game_state == GS_GAME_OVER && ch == CH_SPACE) {
          ResetGame;
        }
      }

      // Smooth multi-key input handling via bit-scan array (kbd.scan_code)
      if (g_game_state == GS_PLAYING) {
        if (Bt(kbd.scan_codes, SC_CURSOR_LEFT)  && g_ship_x > SHIP_W + 8)
          g_ship_x -= SHIP_SPEED;
        if (Bt(kbd.scan_codes, SC_CURSOR_RIGHT) && g_ship_x < SCREEN_W - SHIP_W - 8)
          g_ship_x += SHIP_SPEED;
        if (Bt(kbd.scan_codes, SC_CURSOR_UP)    && g_ship_y > 40)
          g_ship_y -= SHIP_SPEED;
        if (Bt(kbd.scan_codes, SC_CURSOR_DOWN)  && g_ship_y < SCREEN_H - 30)
          g_ship_y += SHIP_SPEED;

        // Spacebar shooting with key edge detection
        if (Bt(kbd.scan_codes, SC_SPACE)) {
          FireBullet;
          Btr(kbd.scan_codes, SC_SPACE); // Clear bit to prevent rapid automatic fire
        }
      }

      UpdateGame;
      Sleep(20); // Maintain ~50-60 FPS tick rate
    }
  }
  catch {
    Fs->catch_except = TRUE;
  }

  // Cleanup
  Sound; // Silence speaker
  Fs->draw_it = NULL;
  DocClear;
  DocCursor(TRUE);
}

// Run immediately when included or executed from the command line
CosmicDefender;
