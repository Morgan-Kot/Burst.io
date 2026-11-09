// ============================================================================
// COMPREHENSIVE HOLYC SYNTAX & API DEMONSTRATION FILE
// Target Architecture: TempleOS / 64-bit Ring 0 x86_64
// ============================================================================

#help_index "Demonstration/Language Features"
#help_file  "::/Doc/HolyCDemo.DD"

#define BUFFER_SIZE     512
#define BIT_MASK(b)     (1 << (b))
#define TERRY_QUOTE     "God says... lightning strikes."

#ifdef OPTIMIZE_SPEED
  #define INLINE_FLAG   inline
#else
  #define INLINE_FLAG
#endif

// Compile-time HolyC meta-programming via #exe
#exe {
  StreamPrint("// Auto-generated build timestamp: %d\n", CDate2Sys(Now));
};

// ============================================================================
// 1. DATA TYPES, TYPE ALIASES & BITFIELDS
// ============================================================================

// HolyC native primitive types:
// I0, U0  - 0-bit (void)
// I8, U8  - 8-bit signed / unsigned
// I16, U16 - 16-bit signed / unsigned
// I32, U32 - 32-bit signed / unsigned
// I64, U64 - 64-bit signed / unsigned (default integer size)
// F64      - 64-bit IEEE float (F32 is NOT supported on the stack)
// Bool     - 1-byte boolean (TRUE / FALSE)

typedef U64 QWORD;
typedef U32 DWORD;
typedef U16 WORD;
typedef U8  BYTE;

extern U0 SystemYield();
_extern _SYS_HALT U0 SysHalt();

class CSubStructure
{
  I32 sub_id;
  U8  sub_flags;
};

class CDemoRecord
{
  I64           id;
  U8            type format "%02X";       // Built-in DolDoc print format specifier
  Bool          is_active;
  F64           frequency format "%8.3f";
  
  // Bitfields
  U32           flag_read:1,
                flag_write:1,
                flag_execute:1,
                reserved:29;

  // Embedded and pointer members
  CSubStructure sub;
  U8            *data_blob;
  U8            name[64];

  // Member function pointer
  U0            (*fp_callback)(I64 code, U8 *msg);
};

union CRegisterOverlay
{
  U64 qword;
  U32 dwords[2];
  U16 words[4];
  U8  bytes[8];
};

// ============================================================================
// 2. GLOBAL VARIABLES & HARDWARE REGISTERS
// ============================================================================

public I64   g_global_counter = 0;
public F64   g_pi_approx      = 3.1415926535897932;
public U8   *g_framebuffer    = 0xA0000;

// Register storage class variables (kept directly in CPU registers)
reg I64 r_scratch_rax;
reg I64 r_scratch_rbx;

// ============================================================================
// 3. INLINE X86_64 ASSEMBLY & INTERRUPT CONTEXTS
// ============================================================================

asm {
_SYS_HALT::
        PUSH    RBP
        MOV     RBP, RSP
        CLI
        HLT
        POP     RBP
        RET

_ASM_MEMSET_FAST::
        PUSH    RBP
        MOV     RBP, RSP
        PUSH    RDI
        PUSH    RAX
        PUSH    RCX

        MOV     RDI, SF_ARG1[RBP]       // First HolyC parameter
        MOV     AL,  SF_ARG2[RBP]       // Fill byte
        MOV     RCX, SF_ARG3[RBP]       // Length
        REP_STOSB

        POP     RCX
        POP     RAX
        POP     RDI
        POP     RBP
        RET1    24                      // Callee cleans up args (ArgPop)
}

interrupt U0 CustomTimerISR()
{
  g_global_counter++;
  OutU8(0x20, 0x20); // Send EOI to PIC
}

// ============================================================================
// 4. FUNCTION DECLARATIONS: DEFAULT ARGS, VARARGS & SYNTAX VARIATIONS
// ============================================================================

// Default argument values + HolyC's optional parentheses for parameterless calls
U0 SimplePing()
{
  "Ping called!\n"; // Bare string literal outputs directly to DolDoc stream
}

// HolyC exponentiation operator ` (backtick)
F64 CalculatePower(F64 base, F64 exp)
{
  return base ` exp; // Exponentiation operator
}

// Default parameters and HolyC function attribute keywords
I64 ComputeVector(I64 x=10, I64 y=20, I64 z=30, F64 scale=1.0)
{
  I64 result = (x`2 + y`2 + z`2);
  return ToI64(Sqrt(result) * scale);
}

// Variadic functions utilize implicit 'argc' and 'argv'
I64 SumNumbers(...)
{
  I64 total = 0;
  I64 idx;

  for (idx = 0; idx < argc; idx++) {
    total += argv[idx];
  }

  return total;
}

// ============================================================================
// 5. CONTROL FLOW: EXTENDED SWITCH, RANGES & SUB-SWITCHES
// ============================================================================

U0 DemonstrateControlFlow(I64 input_code)
{
  I64 i;

  // Standard loops
  for (i = 0; i < 10; i++) {
    if (i == 5) continue;
  }

  while (i > 0) {
    i--;
  }

  do {
    i++;
  } while (i < 3);

  // Extended HolyC switch statement featuring ranges and sub-switches
  switch (input_code) {
    case 0:
      "Code is Zero\n";
      break;

    // Range case
    case 1..5:
      "Code is in range [1, 5]\n";
      break;

    case 6..10:
      // Sub-switch constructs
      start:
        "Preparing sub-block logic...\n";
      case 6:
      case 7:
        "Sub range [6, 7]\n";
        break;
      case 8:
      case 9:
      case 10:
        "Sub range [8, 10]\n";
        break;
      end:
      break;

    default:
      "Code is outside known bounds (>10 or <0)\n";
      break;
  }
}

// ============================================================================
// 6. EXCEPTION HANDLING
// ============================================================================

U0 RiskyOperation(Bool trigger_fault)
{
  if (trigger_fault) {
    throw('FAULT'); // Exceptions throw 64-bit integer values / char literals
  }
  "Operation executed successfully.\n";
}

U0 ExceptionDemo()
{
  try {
    "Entering guarded block...\n";
    RiskyOperation(TRUE);
  }
  catch {
    "Exception caught: %c%c%c%c\n", Fs->except_ch, 
                                    Fs->except_ch >> 8, 
                                    Fs->except_ch >> 16, 
                                    Fs->except_ch >> 24;
    Fs->catch_except = TRUE; // Mark handled
  }
}

// ============================================================================
// 7. MEMORY ALLOCATION, TASKS & CPU ACCESS (Fs / Gs)
// ============================================================================

U0 MemoryAndTaskDemo()
{
  // MAlloc / Free on Task Heap vs Adam Task Heap
  U8  *buffer       = MAlloc(BUFFER_SIZE, Fs);          // Current task heap
  U8  *adam_buffer  = MAlloc(BUFFER_SIZE, adam_task);   // System heap
  I64 *int_arr      = CAlloc(64 * sizeof(I64));         // Zero-initialized
  
  I64 allocated_len = MSize(buffer);

  MemSet(buffer, 0xAA, BUFFER_SIZE);
  MemCpy(adam_buffer, buffer, BUFFER_SIZE);

  // Fs represents the current CTask (Task Context Pointer)
  // Gs represents the current CCPU (Processor Context Pointer)
  I64 current_core = Gs->num;
  I64 task_flags   = Fs->task_flags;

  "Current CPU Core ID: %d | Task Flags: 0x%08X | Alloc Size: %d\n",
    current_core, task_flags, allocated_len;

  Free(buffer);
  Free(adam_buffer);
  Free(int_arr);
}

// Task function to be spawned
U0 WorkerSubTask(I64 arg_value)
{
  I64 ticks = 0;
  while (ticks < arg_value) {
    ticks++;
    Yield; // Context switch to next scheduled task
  }
}

U0 SpawnTaskDemo()
{
  CTask *worker = Spawn(&WorkerSubTask, 1000, "WorkerTask",, Fs);
  TaskWait(worker);
}

// ============================================================================
// 8. DOLDOC FORMATTING & DOCUMENT COMMAND ENGINE
// ============================================================================

U0 DolDocTextDemo()
{
  // Inline terminal escape formatting codes
  "$RED$This text is red.$FG$ Back to default color.\n";
  "$BG,BLUE$$YELLOW$Yellow text over blue background.$FG$$BG$\n";
  "$BK,1$Blinking Text$BK,0$\n";
  "$UL,1$Underlined Text$UL,0$\n";
  "$TX+BD,1$Bold Text$TX+BD,0$\n";

  // Macro link and tree widget
  "$MA+L,PTR=\"https://templeos.holyc\",LM=\"Click here to jump\"$\n";
  "$TR,\"Branch Item\"$\n";
  "$ID,2$";
  "Sub-item inside branch\n";
  "$ID,-2$";

  // Printing via DolDoc stream
  DocPrint(DocPut, "$PURPLE$Directly printing via DocPrint.$FG$\n");
}

// ============================================================================
// 9. 2D/3D GRAPHICS (CDC), SPRITES & CSprite
// ============================================================================

U0 DrawGraphicsDemo()
{
  CDC *dc = DCAlias(gr.dc, Fs); // Get device context aliased to screen

  DCClear(dc);

  // Color selection
  dc->color = RED;
  GrPlot(dc, 100, 100);

  dc->color = BLUE;
  GrLine(dc, 20, 20, 200, 150);

  dc->color = GREEN;
  GrCircle(dc, 150, 150, 40);

  dc->color = YELLOW;
  GrRect(dc, 300, 100, 80, 50);

  dc->color = PURPLE;
  GrPrint(dc, 50, 50, "Hello TempleOS Graphics: %d", 42);

  // 3D Rotation Matrix transforms on DC
  Mat4x4IdentEqu(dc->r);
  Mat4x4RotX(dc->r, 0.45);
  Mat4x4RotY(dc->r, 0.75);

  DCDel(dc);
}

// ============================================================================
// 10. HARDWARE I/O PORTS & SPEAKER AUDIO
// ============================================================================

U0 HardwareIODemo()
{
  // Port I/O instructions
  OutU8(0x61, InU8(0x61) | 0x03);   // Enable PC Speaker gate
  Sleep(10);
  OutU8(0x61, InU8(0x61) & ~0x03);  // Disable PC Speaker gate

  // HolyC High-Level Sound Functions
  Sound(64);       // Play 64 Hz tone
  Sleep(150);      // Sleep for 150 milliseconds
  Sound;           // No argument: turns sound off

  // Music string interpretation engine
  MusicSettingsRst;
  Play("5q.e4G3A4C"); // Notation string parser
}

// ============================================================================
// 11. KEYBOARD & MOUSE EVENT DISPATCH
// ============================================================================

U0 UserInputDemo()
{
  I64 scancode = 0;
  I64 ascii_char = 0;

  "Press any key to test input (ESC to abort)...\n";

  while (ascii_char != CH_ESC) {
    // ScanKey non-blocking key scanner
    if (ScanKey(&scancode, &ascii_char)) {
      "Key: ASCII=0x%02X ScanCode=0x%08X\n", ascii_char, scancode;
    }

    // Mouse coordinates check via Task structure
    if (mouse.lb) {
      "Left Mouse Button Clicked at (%d, %d)\n", mouse.pos.x, mouse.pos.y;
    }

    Sleep(50);
  }
}

// ============================================================================
// 12. ENTRY POINT / MAIN HARNESS
// ============================================================================

public I64 Main(...)
{
  "====================================================\n";
  "Starting Unified HolyC System Feature Test\n";
  "====================================================\n";

  // Invoking parameterless function with no parens
  SimplePing;

  // Mathematical operations & power operator
  F64 exp_result = CalculatePower(2.0, 8.0);
  "2.0 ` 8.0 = %8.4f\n", exp_result;

  I64 vec = ComputeVector(3, 4, 5, 2.5);
  "Vector magnitude: %d\n", vec;

  // Variadic function invocation
  I64 sum = SumNumbers(10, 20, 30, 40, 50);
  "SumNumbers(10..50) = %d\n", sum;

  // Flow control & exceptions
  DemonstrateControlFlow(7);
  ExceptionDemo;

  // Memory, tasks & OS subsystems
  MemoryAndTaskDemo;
  SpawnTaskDemo;
  DolDocTextDemo;
  DrawGraphicsDemo;
  HardwareIODemo;

  "Execution Complete. Returning status 0.\n";
  return 0;
}

// If invoked from the command line, calling Main without parentheses runs it
Main;
