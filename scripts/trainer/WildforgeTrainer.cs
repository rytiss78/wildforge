// Wildforge trainer (debug tool, not shipped): super jump for a live run.
// 1) Raises the "airJumps" stat entries it can find to 8 (Godot 4 Variant layout:
//    a Dictionary entry is the key Variant followed by the value Variant).
// 2) Raises the jump-speed literal 8.5 (game.gd try_jump) to 21 so each jump goes
//    about 9 m up. Press Enter in its window to put 8.5 back.
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

class WildforgeTrainer {
    [DllImport("kernel32.dll")] static extern IntPtr OpenProcess(int access, bool inherit, int pid);
    [DllImport("kernel32.dll")] static extern bool ReadProcessMemory(IntPtr h, IntPtr addr, byte[] buf, IntPtr size, out IntPtr read);
    [DllImport("kernel32.dll")] static extern bool WriteProcessMemory(IntPtr h, IntPtr addr, byte[] buf, IntPtr size, out IntPtr written);
    [DllImport("kernel32.dll")] static extern int VirtualQueryEx(IntPtr h, IntPtr addr, out MBI info, int len);
    [StructLayout(LayoutKind.Sequential)] struct MBI { public IntPtr Base; public IntPtr AllocBase; public uint AllocProtect; public uint pad1; public IntPtr Size; public uint State; public uint Protect; public uint Type; public uint pad2; }
    const uint MEM_COMMIT = 0x1000, MEM_PRIVATE = 0x20000, PAGE_READWRITE = 0x04;
    const int TARGET = 8;
    const int STRING = 4, INT = 2, FLOAT = 3;

    static IntPtr proc;
    static List<KeyValuePair<long, byte[]>> Regions() {
        var list = new List<KeyValuePair<long, byte[]>>();
        long addr = 0; MBI m;
        while (VirtualQueryEx(proc, new IntPtr(addr), out m, Marshal.SizeOf(typeof(MBI))) != 0) {
            long size = m.Size.ToInt64();
            if (m.State == MEM_COMMIT && m.Type == MEM_PRIVATE && m.Protect == PAGE_READWRITE && size < (1L << 31)) {
                var buf = new byte[size]; IntPtr got;
                if (ReadProcessMemory(proc, m.Base, buf, new IntPtr(size), out got)) list.Add(new KeyValuePair<long, byte[]>(m.Base.ToInt64(), buf));
            }
            addr = m.Base.ToInt64() + size;
            if (addr <= 0 || addr >= 0x7FFFFFFFFFFF) break;
        }
        return list;
    }

    static int Apply(bool verbose) {
        var regions = Regions();
        return Boost(regions, "airJumps", TARGET, verbose);
    }

    static int Boost(List<KeyValuePair<long, byte[]>> regions, string key, int TARGET, bool verbose) {
        byte[] needle = Encoding.UTF32.GetBytes(key + "\0");
        var strings = new HashSet<long>();
        foreach (var r in regions) {
            byte[] b = r.Value;
            for (int i = 0; i <= b.Length - needle.Length; i += 4) {
                if (b[i] != needle[0] || b[i + 4] != needle[4]) continue;
                bool ok = true;
                for (int k = 0; k < needle.Length; k++) if (b[i + k] != needle[k]) { ok = false; break; }
                if (ok) strings.Add(r.Key + i);
            }
        }
        int seen = 0, changed = 0;
        foreach (var r in regions) {
            byte[] b = r.Value;
            for (int i = 0; i + 48 <= b.Length; i += 8) {
                if (BitConverter.ToInt32(b, i) != STRING) continue;
                if (!strings.Contains(BitConverter.ToInt64(b, i + 8))) continue;
                int v = i + 24; int type = BitConverter.ToInt32(b, v);
                long at = r.Key + v + 8; IntPtr w;
                if (type == FLOAT) {
                    double d = BitConverter.ToDouble(b, v + 8);
                    if (d < 0 || d >= 9 || double.IsNaN(d)) continue;
                    seen++;
                    if (false) Console.WriteLine("    " + key + " @" + (r.Key + i).ToString("X") + " = " + d);
                    if (d < TARGET) { var data = BitConverter.GetBytes((double)TARGET); if (WriteProcessMemory(proc, new IntPtr(at), data, new IntPtr(8), out w)) changed++; }
                } else if (type == INT) {
                    long n = BitConverter.ToInt64(b, v + 8);
                    if (n < 0 || n >= 9) continue;
                    seen++;
                    if (false) Console.WriteLine("    " + key + " @" + (r.Key + i).ToString("X") + " = " + n + " (int)");
                    if (n < TARGET) { var data = BitConverter.GetBytes((long)TARGET); if (WriteProcessMemory(proc, new IntPtr(at), data, new IntPtr(8), out w)) changed++; }
                }
            }
        }
        if (verbose) Console.WriteLine("  \"" + key + "\" strings: " + strings.Count + ", stat entries: " + seen + ", raised to " + TARGET + " now: " + changed);
        return seen;
    }

    // The jump itself: game.gd sets velocity.y = 8.5*sqrt(jumpHeight). GDScript keeps
    // the literal 8.5 as a FLOAT Variant in the function's constants, so raising
    // every FLOAT Variant equal to 8.5 makes every jump much higher. Restored on Enter.
    static List<long> patched = new List<long>();
    static void PatchJump(double from, double to) {
        var regions = Regions();
        byte[] want = BitConverter.GetBytes(from); IntPtr w;
        foreach (var r in regions) {
            byte[] b = r.Value;
            for (int i = 0; i + 16 <= b.Length; i += 8) {
                if (BitConverter.ToInt32(b, i) != FLOAT) continue;
                bool ok = true;
                for (int k = 0; k < 8; k++) if (b[i + 8 + k] != want[k]) { ok = false; break; }
                if (!ok) continue;
                long at = r.Key + i + 8;
                if (WriteProcessMemory(proc, new IntPtr(at), BitConverter.GetBytes(to), new IntPtr(8), out w)) patched.Add(at);
            }
        }
    }

    static void Main() {
        Console.Title = "Wildforge trainer - super jump";
        Process[] ps = Process.GetProcessesByName("Wildforge");
        if (ps.Length == 0) foreach (var p in Process.GetProcesses()) if (p.ProcessName.StartsWith("Wildforge", StringComparison.OrdinalIgnoreCase)) { ps = new[] { p }; break; }
        if (ps.Length == 0) { Console.WriteLine("Wildforge is not running. Start your run first."); Console.ReadLine(); return; }
        proc = OpenProcess(0x0010 | 0x0020 | 0x0008 | 0x0400, false, ps[0].Id);
        if (proc == IntPtr.Zero) { Console.WriteLine("Could not open the game (try Run as administrator)."); Console.ReadLine(); return; }
        Console.WriteLine("Attached to " + ps[0].ProcessName + " (pid " + ps[0].Id + ").");
        Apply(true);
        PatchJump(8.5, 21.0);
        Console.WriteLine("Super jump: changed " + patched.Count + " jump-speed values (8.5 -> 21).");
        Console.WriteLine("SUPER JUMP ON. Every jump now goes about 9 m up. Climb out of the pit,");
        Console.WriteLine("then come back here and press Enter to turn it off (keeps your run normal).");
        while (!ps[0].HasExited) {
            if (Console.KeyAvailable && Console.ReadKey(true).Key == ConsoleKey.Enter) break;
            Thread.Sleep(250);
        }
        IntPtr w; int back = 0;
        if (!ps[0].HasExited) foreach (long at in patched) if (WriteProcessMemory(proc, new IntPtr(at), BitConverter.GetBytes(8.5), new IntPtr(8), out w)) back++;
        Console.WriteLine("Super jump OFF (" + back + " values restored). You can close this window.");
        Console.ReadLine();
    }
}
