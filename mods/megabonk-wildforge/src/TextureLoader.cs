using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Bindings;

namespace Wildforge.Megabonk;

internal static class TextureLoader
{
    // Bypass the reconstructed generic IL2CPP Span<byte> constructor. The native
    // Unity binding accepts this blittable pointer/length wrapper directly.
    internal static unsafe Texture2D Load(string file)
    {
        var texture = new Texture2D(2, 2);
        var bytes = File.ReadAllBytes(file);
        var pin = GCHandle.Alloc(bytes, GCHandleType.Pinned);
        try
        {
            var span = new ManagedSpanWrapper((void*)pin.AddrOfPinnedObject(), bytes.Length);
            if (!ImageConversion.LoadImage_Injected(texture.m_CachedPtr, ref span, false))
                throw new InvalidDataException($"Cannot load texture {Path.GetFileName(file)}");
        }
        finally { pin.Free(); }
        UnityEngine.Object.DontDestroyOnLoad(texture);
        return texture;
    }
}
