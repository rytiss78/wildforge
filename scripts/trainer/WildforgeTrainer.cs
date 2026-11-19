// Wildforge trainer: gives the running hero 8 extra air jumps (the game cap; triple jump only reaches 4.5 m, the pit cliffs are 8 m)
// by finding the "airJumps" entries of the game's stats dictionaries in memory
// (Godot 4 Variant: int32 type, pad, 16-byte payload; a Dictionary entry is the
// key Variant followed by the value Variant) and raising values below 8 to 8.
// Re-applies every 5 seconds until you close this window.
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
        byte[] needle = Encoding.UTF32.GetBytes("airJumps\0");
        var strings = new HashSet<long>();
        foreach (var r in regions) {
            byte[] b = r.Value;
            for (int i = 0; i <= b.Length - needle.Length; i += 4) {
                if (b[i] != (byte)'a' || b[i + 4] != (byte)'i') continue;
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
                    if (d < TARGET) { var data = BitConverter.GetBytes((double)TARGET); if (WriteProcessMemory(proc, new IntPtr(at), data, new IntPtr(8), out w)) changed++; }
                } else if (type == INT) {
                    long n = BitConverter.ToInt64(b, v + 8);
                    if (n < 0 || n >= 9) continue;
                    seen++;
                    if (n < TARGET) { var data = BitConverter.GetBytes((long)TARGET); if (WriteProcessMemory(proc, new IntPtr(at), data, new IntPtr(8), out w)) changed++; }
                }
            }
        }
        if (verbose) Console.WriteLine("  \"airJumps\" strings: " + strings.Count + ", stat entries: " + seen + ", raised to " + TARGET + " now: " + changed);
        return seen;
    }

    static void Main() {
        Console.Title = "Wildforge trainer - extra jumps";
        Process[] ps = Process.GetProcessesByName("Wildforge");
        if (ps.Length == 0) foreach (var p in Process.GetProcesses()) if (p.ProcessName.StartsWith("Wildforge", StringComparison.OrdinalIgnoreCase)) { ps = new[] { p }; break; }
        if (ps.Length == 0) { Console.WriteLine("Wildforge is not running. Start your run first."); Console.ReadLine(); return; }
        proc = OpenProcess(0x0010 | 0x0020 | 0x0008 | 0x0400, false, ps[0].Id);
        if (proc == IntPtr.Zero) { Console.WriteLine("Could not open the game (try Run as administrator)."); Console.ReadLine(); return; }
        Console.WriteLine("Attached to " + ps[0].ProcessName + " (pid " + ps[0].Id + "). Giving the hero 8 extra air jumps...");
        int found = Apply(true);
        if (found == 0) Console.WriteLine("Found no jump stat. The trainer could not hook this build.");
        else Console.WriteLine("Extra jumps ON (9 jumps in a row, enough to climb out of the pit). Keep this window open; close it to stop.");
        while (!ps[0].HasExited) { Thread.Sleep(5000); Apply(false); }
    }
}
