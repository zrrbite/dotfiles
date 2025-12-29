# GDB configuration

# Unreal Engine pretty printers (wrapped in try-except for GDB 17+ compatibility)
python
import sys
try:
    sys.path.append('/home/zrrbite/.config/Epic/GDBPrinters/')
    from UEPrinters import register_ue_printers
    register_ue_printers(None)
    print("Registered pretty printers for UE classes")
except Exception as e:
    print(f"Note: UE printers not loaded ({type(e).__name__})")
end

# Allow loading .gdbinit from project directories
set auto-load safe-path /
set auto-load local-gdbinit on
add-auto-load-safe-path /home/zrrbite/dev/

# Better output formatting
set print pretty on
set print array on
set print array-indexes on
set print elements 0
set print object on
set print static-members on
set print vtbl on
set print demangle on
set print asm-demangle on

# History
set history save on
set history size 10000
set history filename ~/.gdb_history
set history expansion on

# Disable pagination for non-interactive scripts
set pagination off

# Don't prompt for confirmation on quit
set confirm off

# Disable debuginfod prompts
set debuginfod enabled off

# Better disassembly
set disassembly-flavor intel

# Follow fork settings (detach-on-fork on for GUI apps that spawn GPU processes)
set follow-fork-mode parent
set detach-on-fork on

# Thread debugging
set print thread-events off

# C++ specific - skip STL internals when stepping
set print sevenbit-strings off
skip -gfi /usr/include/c++/*
skip -gfi /usr/include/c++/*/*
skip -gfi /usr/include/c++/*/*/*
skip -gfi /usr/include/bits/*

# Useful aliases

# Print raw array
define pa
    print *($arg0)@$arg1
end
document pa
Print raw array: pa <array> <length>
end

# Print std::vector contents
define pv
    print $arg0.size()
    print *$arg0._M_impl._M_start@$arg0.size()
end
document pv
Print std::vector contents: pv my_vector
end

# Print std::map contents
define pm
    print $arg0.size()
    print $arg0
end
document pm
Print std::map contents: pm my_map
end

define pl
    set $i = 0
    set $node = $arg0
    while $node != 0
        print *$node
        set $node = $node->next
        set $i = $i + 1
        if $i > 100
            printf "... (stopped at 100 elements)\n"
            loop_break
        end
    end
end
document pl
Print linked list: pl <head_pointer>
end

# Quick thread info
define threads
    info threads
end

# Quick backtrace all threads
define btall
    thread apply all bt
end
document btall
Backtrace all threads
end

# Breakpoint shortcuts
define bpl
    info breakpoints
end
document bpl
List all breakpoints
end

define bpc
    delete breakpoints
end
document bpc
Clear all breakpoints
end

# Source listing around current line
define ctx
    list *$pc
end
document ctx
Show source context around current PC
end

# Load gdb-dashboard for visual debugging interface
# Shows: source, assembly, variables, stack, threads, registers
# Toggle with: dashboard -enabled on/off
# Customize layout: dashboard -layout source assembly stack
source /usr/share/gdb-dashboard/.gdbinit
