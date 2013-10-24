      Member()
      Include('ConsoleSupport.inc'),ONCE

fpAttachConsole LONG,NAME('AttachConsole')

	  Map
        MODULE('API')
            ! General functions
            GetLastError(),DWORD,PASCAL
 
            ! Console functions
            AllocConsole(),BYTE,PASCAL,RAW
            GetStdHandle(DWORD),HANDLE,PASCAL,PROC,RAW
            WriteConsole(Handle,Long,Dword,long,long),bool,Raw,Pascal,name('WriteConsoleA')
            WriteFile(Handle,Long,Dword,long,long),bool,Raw,Pascal,name('WriteFile')

            ReadConsole(Handle,Long,Dword,long,long),bool,Raw,Pascal,name('ReadConsoleA')
            SetConsoleTitle(Long),Bool,Raw,Pascal,name('SetConsoleTitleA')
            GetConsoleTitle(Long,dword),Bool,Raw,Pascal,name('GetConsoleTitleA')
            SetConsoleMode(Handle,dWord),BOOL,RAW,PASCAL
            GetConsoleMode(Handle,Long),BOOL,RAW,PASCAL
        End
        MODULE('kernel32')
AttachConsole  PROCEDURE(LONG),BYTE,PASCAL,RAW,DLL(1)
         END
      End

ConsoleSupport.Construct PROCEDURE

  CODE

ConsoleSupport.Destruct PROCEDURE

  CODE

ConsoleSupport.Init				   PROCEDURE () !,BYTE,VIRTUAL 
  CODE
  IF NOT SELF._LoadLib &= NULL
    IF SELF._LoadLib.LibraryLoaded()
      SELF._LoadLib.LlcFreeLibrary()
    END
    Dispose(SELF._LoadLib)
  END
  SELF._LoadLib &= NEW LoadLibClass
  IF NOT SELF._LoadLib &= NULL
    IF SELF._LoadLib.LlcLoadLibrary('kernel32.dll') <> SUCCESS
      Halt(1,'_LoadLib.LlcLoadLibrary failed (' & GetLastError() & ')')
      RETURN INVALID_HANDLE_VALUE
    END
    IF SELF._LoadLib.LibraryLoaded()
      fpAttachConsole = SELF._LoadLib.LlcGetProcAddress('AttachConsole')
    END
  END

    ! IF AllocConsole() <> 0
    !     Halt(1,'AllocConsole failed (' & GetLastError() & ')')
    !     RETURN INVALID_HANDLE_VALUE
    ! END
    ! IF AttachConsole(-1) <> 0
    !     Halt(1,'AttachConsole failed (' & GetLastError() & ')')
    !     RETURN INVALID_HANDLE_VALUE
    ! END
    SELF.OutputHandle = GetStdHandle(STD_OUTPUT_HANDLE)
    If SELF.OutputHandle = INVALID_HANDLE_VALUE
        Halt(1,'Unable to get output handle (' & GetLastError() & ')')
        RETURN INVALID_HANDLE_VALUE
    End
 
    SELF.InputHandle = GetStdHandle(STD_INPUT_HANDLE)
    if SELF.InputHandle = INVALID_HANDLE_VALUE
        Halt(2,'Unable to get console input handle (' & GetLastError() & ')')
        RETURN INVALID_HANDLE_VALUE
    End
 
    If ~SetConsoleMode(SELF.InputHandle,ENABLE_PROCESSED_INPUT )
        Halt(3,'Unable to set console mode (' & GetLastError() & ')')
        RETURN INVALID_OTHER
    End

    RETURN FALSE

ConsoleSupport.WriteLine			   PROCEDURE (STRING pText) !,BYTE,PROC,VIRTUAL 
  CODE
    SELF.TextBuffer = SELF.Prefix & pText & '<13,10>'
    If WriteConsole(SELF.OutputHandle, ADDRESS(SELF.TextBuffer), LEN(SELF.TextBuffer),ADDRESS(SELF.BytesWritten), NULL) = 0
      ! If WriteConsole fails then maybe we are supposed to use a "file" stream...
      If WriteFile(SELF.OutputHandle, ADDRESS(SELF.TextBuffer), LEN(SELF.TextBuffer),ADDRESS(SELF.BytesWritten), NULL) = 0
        Halt(4,'WriteConsoleError (' & GetLastError() & ')')
        RETURN -1
      END
    End
    RETURN FALSE

Consolesupport.ReadKey  			   PROCEDURE () !,STRING,PROC,VIRTUAL 
  CODE
  SELF.WriteLine('Press any key to continue...')
  Clear(SELF.InBuffer)
  Loop
    IF ReadConsole(SELF.InputHandle,Address(SELF.InBuffer),100,Address(SELF.BytesRead),NULL) = 0 THEN
      Halt(5,'Error on read console (' & GetLastError() & ')')
      Break
    End
  Until SELF.BytesRead > 0
  RETURN SELF.InBuffer