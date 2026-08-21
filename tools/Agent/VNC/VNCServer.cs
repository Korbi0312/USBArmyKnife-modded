// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan

using System.Runtime.InteropServices;
using RemoteViewing.Vnc.Server;
using RemoteViewing.Vnc;
using Microsoft.Extensions.Logging;

namespace Agent.VNC
{
    internal class VNCServer : IVncPasswordChallenge, IDisposable
    {
        private readonly Action OnError;
        private readonly VncServerSession session;
        private readonly VNCFramebufferSource framebuffer;
        private readonly double maxUpdateRate;
        private bool disposedValue;

        #region Win32 Input Injection
        private const uint INPUT_MOUSE = 0;
        private const uint INPUT_KEYBOARD = 1;
        private const uint MOUSEEVENTF_MOVE = 0x0001;
        private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
        private const uint MOUSEEVENTF_LEFTUP = 0x0004;
        private const uint MOUSEEVENTF_RIGHTDOWN = 0x0008;
        private const uint MOUSEEVENTF_RIGHTUP = 0x0010;
        private const uint MOUSEEVENTF_MIDDLEDOWN = 0x0020;
        private const uint MOUSEEVENTF_MIDDLEUP = 0x0040;
        private const uint MOUSEEVENTF_WHEEL = 0x0800;
        private const uint MOUSEEVENTF_ABSOLUTE = 0x8000;
        private const uint MOUSEEVENTF_VIRTUALDESK = 0x4000;
        private const uint KEYEVENTF_KEYUP = 0x0002;
        private const int WHEEL_DELTA = 120;

        [StructLayout(LayoutKind.Sequential)]
        private struct INPUT
        {
            public uint type;
            public InputUnion u;
        }

        [StructLayout(LayoutKind.Explicit)]
        private struct InputUnion
        {
            [FieldOffset(0)] public MOUSEINPUT mi;
            [FieldOffset(0)] public KEYBDINPUT ki;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct MOUSEINPUT
        {
            public int dx;
            public int dy;
            public uint mouseData;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct KEYBDINPUT
        {
            public ushort wVk;
            public ushort wScan;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [DllImport("user32.dll", SetLastError = true)]
        private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

        [DllImport("user32.dll")]
        private static extern int GetSystemMetrics(int nIndex);

        private const int SM_CXSCREEN = 0;
        private const int SM_CYSCREEN = 1;
        private const int SM_CXVSCREEN = 76;
        private const int SM_CYVSCREEN = 77;

        [DllImport("user32.dll")]
        private static extern ushort MapVirtualKeyW(uint uCode, uint uMapType);

        private const uint MAPVK_VK_TO_VSC = 0;

        private static readonly Dictionary<uint, ushort> KeysymToVk = new()
        {
            // ASCII
            [0x0020] = 0x20, // space
            [0x0021] = 0x21, // !
            [0x0022] = 0xDE, // "
            [0x0023] = 0x23, // #
            [0x0024] = 0x24, // $
            [0x0025] = 0x25, // %
            [0x0026] = 0x26, // &
            [0x0027] = 0xDE, // '
            [0x0028] = 0x28, // (
            [0x0029] = 0x29, // )
            [0x002A] = 0x6A, // *
            [0x002B] = 0x6B, // +
            [0x002C] = 0xBC, // ,
            [0x002D] = 0xBD, // -
            [0x002E] = 0xBE, // .
            [0x002F] = 0xBF, // /
            [0x0030] = 0x30, // 0
            [0x0031] = 0x31, // 1
            [0x0032] = 0x32, // 2
            [0x0033] = 0x33, // 3
            [0x0034] = 0x34, // 4
            [0x0035] = 0x35, // 5
            [0x0036] = 0x36, // 6
            [0x0037] = 0x37, // 7
            [0x0038] = 0x38, // 8
            [0x0039] = 0x39, // 9
            [0x003A] = 0xBA, // :
            [0x003B] = 0xBA, // ;
            [0x003C] = 0xE2, // <
            [0x003D] = 0xBB, // =
            [0x003E] = 0xE2, // >
            [0x003F] = 0xBF, // ?
            [0x0040] = 0xC0, // @
            // Uppercase A-Z
            [0x0041] = 0x41, // A
            [0x0042] = 0x42, // B
            [0x0043] = 0x43, // C
            [0x0044] = 0x44, // D
            [0x0045] = 0x45, // E
            [0x0046] = 0x46, // F
            [0x0047] = 0x47, // G
            [0x0048] = 0x48, // H
            [0x0049] = 0x49, // I
            [0x004A] = 0x4A, // J
            [0x004B] = 0x4B, // K
            [0x004C] = 0x4C, // L
            [0x004D] = 0x4D, // M
            [0x004E] = 0x4E, // N
            [0x004F] = 0x4F, // O
            [0x0050] = 0x50, // P
            [0x0051] = 0x51, // Q
            [0x0052] = 0x52, // R
            [0x0053] = 0x53, // S
            [0x0054] = 0x54, // T
            [0x0055] = 0x55, // U
            [0x0056] = 0x56, // V
            [0x0057] = 0x57, // W
            [0x0058] = 0x58, // X
            [0x0059] = 0x59, // Y
            [0x005A] = 0x5A, // Z
            // Lowercase a-z (VNC sends lowercase, Windows VK are uppercase)
            [0x0061] = 0x41, // a -> A
            [0x0062] = 0x42,
            [0x0063] = 0x43,
            [0x0064] = 0x44,
            [0x0065] = 0x45,
            [0x0066] = 0x46,
            [0x0067] = 0x47,
            [0x0068] = 0x48,
            [0x0069] = 0x49,
            [0x006A] = 0x4A,
            [0x006B] = 0x4B,
            [0x006C] = 0x4C,
            [0x006D] = 0x4D,
            [0x006E] = 0x4E,
            [0x006F] = 0x4F,
            [0x0070] = 0x50,
            [0x0071] = 0x51,
            [0x0072] = 0x52,
            [0x0073] = 0x53,
            [0x0074] = 0x54,
            [0x0075] = 0x55,
            [0x0076] = 0x56,
            [0x0077] = 0x57,
            [0x0078] = 0x58,
            [0x0079] = 0x59,
            [0x007A] = 0x5A,
            // Symbols
            [0x007B] = 0xDB, // {
            [0x007C] = 0xDC, // |
            [0x007D] = 0xDD, // }
            [0x007E] = 0xC0, // ~
            [0x00A0] = 0x20, // nbsp -> space
            // Special keys (X11 keysyms)
            [0xFF08] = 0x08, // BackSpace
            [0xFF09] = 0x09, // Tab
            [0xFF0B] = 0x0D, // Return (Linefeed maps to Enter)
            [0xFF0D] = 0x0D, // Return
            [0xFF13] = 0x13, // Pause
            [0xFF14] = 0x2C, // Scroll_Lock
            [0xFF1B] = 0x1B, // Escape
            [0xFFFF] = 0x2E, // Delete
            [0xFF50] = 0x24, // Home
            [0xFF51] = 0x25, // Left
            [0xFF52] = 0x26, // Up
            [0xFF53] = 0x27, // Right
            [0xFF54] = 0x28, // Down
            [0xFF55] = 0x21, // Prior (Page_Up)
            [0xFF56] = 0x22, // Next (Page_Down)
            [0xFF57] = 0x23, // End
            [0xFF58] = 0x2D, // Insert
            [0xFF67] = 0x5D, // Menu
            // Function keys
            [0xFFBE] = 0x70, // F1
            [0xFFBF] = 0x71, // F2
            [0xFFC0] = 0x72, // F3
            [0xFFC1] = 0x73, // F4
            [0xFFC2] = 0x74, // F5
            [0xFFC3] = 0x75, // F6
            [0xFFC4] = 0x76, // F7
            [0xFFC5] = 0x77, // F8
            [0xFFC6] = 0x78, // F9
            [0xFFC7] = 0x79, // F10
            [0xFFC8] = 0x7A, // F11
            [0xFFC9] = 0x7B, // F12
            // Modifier keys
            [0xFFE1] = 0xA0, // Shift_L
            [0xFFE2] = 0xA1, // Shift_R
            [0xFFE3] = 0xA2, // Control_L
            [0xFFE4] = 0xA3, // Control_R
            [0xFFE5] = 0x14, // Caps_Lock
            [0xFFE7] = 0xA4, // Alt_L
            [0xFFE8] = 0xA5, // Alt_R
            [0xFFE9] = 0xA4, // Super_L -> Left Menu (Alt)
            [0xFFEA] = 0xA5, // Super_R -> Right Alt
            // Numpad
            [0xFFB0] = 0x60, // KP_0
            [0xFFB1] = 0x61, // KP_1
            [0xFFB2] = 0x62, // KP_2
            [0xFFB3] = 0x63, // KP_3
            [0xFFB4] = 0x64, // KP_4
            [0xFFB5] = 0x65, // KP_5
            [0xFFB6] = 0x66, // KP_6
            [0xFFB7] = 0x67, // KP_7
            [0xFFB8] = 0x68, // KP_8
            [0xFFB9] = 0x69, // KP_9
            [0xFFAA] = 0x6A, // KP_Multiply
            [0xFFAB] = 0x6B, // KP_Add
            [0xFFAC] = 0x6C, // KP_Separator
            [0xFFAD] = 0x6D, // KP_Subtract
            [0xFFAE] = 0x6E, // KP_Decimal
            [0xFFAF] = 0x6F, // KP_Divide
        };

        private static ushort KeysymToVirtualKey(uint keysym)
        {
            // For ASCII range (0x0020-0x007E), the keysym often equals the character code
            if (keysym >= 0x0020 && keysym <= 0x007E)
            {
                if (KeysymToVk.TryGetValue(keysym, out var mapped))
                    return mapped;
                // Direct mapping for printable ASCII
                return (ushort)keysym;
            }

            // For X11 keysyms (0xFF00+), look up in table
            if (KeysymToVk.TryGetValue(keysym, out var vk))
                return vk;

            return 0;
        }

        private static void SendMouseInput(uint flags, int x, int y, int data = 0)
        {
            int screenW = GetSystemMetrics(SM_CXSCREEN);
            int screenH = GetSystemMetrics(SM_CYSCREEN);
            if (screenW == 0 || screenH == 0) return;

            var input = new INPUT
            {
                type = INPUT_MOUSE,
                u = new InputUnion
                {
                    mi = new MOUSEINPUT
                    {
                        dx = (int)((long)x * 65535 / screenW),
                        dy = (int)((long)y * 65535 / screenH),
                        mouseData = (uint)data,
                        dwFlags = flags | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK,
                        time = 0,
                        dwExtraInfo = IntPtr.Zero
                    }
                }
            };
            SendInput(1, new INPUT[] { input }, Marshal.SizeOf<INPUT>());
        }

        private static void SendKeyboardInput(ushort vk, bool keyDown)
        {
            ushort scan = MapVirtualKeyW(vk, MAPVK_VK_TO_VSC);
            var input = new INPUT
            {
                type = INPUT_KEYBOARD,
                u = new InputUnion
                {
                    ki = new KEYBDINPUT
                    {
                        wVk = vk,
                        wScan = scan,
                        dwFlags = keyDown ? 0u : KEYEVENTF_KEYUP,
                        time = 0,
                        dwExtraInfo = IntPtr.Zero
                    }
                }
            };
            SendInput(1, new INPUT[] { input }, Marshal.SizeOf<INPUT>());
        }
        #endregion

        public VNCServer(Action onerr, double maxUpdateRate = 0.3, int downscale = 1, ILoggerFactory? loggerFactory = null, int targetWidth = 0, int targetHeight = 0)
        {
            this.OnError = onerr;
            this.maxUpdateRate = maxUpdateRate;

            // When run over serial we are only able to transmit around 1kb/s 
            framebuffer = new VNCFramebufferSource(OnFrameUpdate, downscale, targetWidth, targetHeight);

            loggerFactory ??= new LoggerFactory();
            var log = loggerFactory.CreateLogger("vnc");

            // Create a session.
            session = new VncServerSession(this, log);
            session.SetFramebufferSource(framebuffer);
#pragma warning disable CS8622 // Nullability of reference types in type of parameter doesn't match the target delegate (possibly because of nullability attributes).
            session.ConnectionFailed += HandleConnectionFailed;
            session.Closed += HandleClosed;
            session.KeyChanged += HandleKeyChanged;
            session.PointerChanged += HandlePointerChanged;
#pragma warning restore CS8622 // Nullability of reference types in type of parameter doesn't match the target delegate (possibly because of nullability attributes).

            // The library only picks the JPEG path when the client sends a Tight quality hint in the range
            // -32..-23 (Quamotion fork numbering). noVNC sends -256+level, which never matches, so the
            // encoder would always fall back to zlib (~225 KB per full frame instead of ~30 KB JPEG).
            // Force the JPEG path with a dedicated encoder subclass.
            var encoder = new JpegTightEncoder(session);
            session.Encoders.Clear();
            session.Encoders.Add(encoder);
            session.Encoder = encoder;
        }

        private void HandleKeyChanged(object? sender, KeyChangedEventArgs e)
        {
            try
            {
                ushort vk = KeysymToVirtualKey((uint)e.Keysym);
                if (vk != 0)
                {
                    SendKeyboardInput(vk, e.Pressed);
                }
            }
            catch { }
        }

        private int lastButtonMask = 0;

        private void HandlePointerChanged(object? sender, PointerChangedEventArgs e)
        {
            try
            {
                // VNC coordinates are relative to the framebuffer; map to screen coordinates
                int fbW = framebuffer.Width;
                int fbH = framebuffer.Height;
                int screenW = GetSystemMetrics(SM_CXSCREEN);
                int screenH = GetSystemMetrics(SM_CYSCREEN);
                if (fbW <= 0 || fbH <= 0 || screenW <= 0 || screenH <= 0) return;

                int screenX = (int)((long)e.X * screenW / fbW);
                int screenY = (int)((long)e.Y * screenH / fbH);

                int buttonMask = e.PressedButtons;
                int changed = buttonMask ^ lastButtonMask;
                lastButtonMask = buttonMask;

                // Mouse wheel (X11: 8=scroll up, 16=scroll down)
                if ((buttonMask & 8) != 0)
                {
                    SendMouseInput(MOUSEEVENTF_MOVE | MOUSEEVENTF_WHEEL, screenX, screenY, WHEEL_DELTA);
                    return;
                }
                if ((buttonMask & 16) != 0)
                {
                    SendMouseInput(MOUSEEVENTF_MOVE | MOUSEEVENTF_WHEEL, screenX, screenY, -WHEEL_DELTA);
                    return;
                }

                // Only send move + button events when something actually changed
                if (changed != 0)
                {
                    uint flags = MOUSEEVENTF_MOVE;
                    if ((changed & 1) != 0)
                        flags |= (buttonMask & 1) != 0 ? MOUSEEVENTF_LEFTDOWN : MOUSEEVENTF_LEFTUP;
                    if ((changed & 2) != 0)
                        flags |= (buttonMask & 2) != 0 ? MOUSEEVENTF_MIDDLEDOWN : MOUSEEVENTF_MIDDLEUP;
                    if ((changed & 4) != 0)
                        flags |= (buttonMask & 4) != 0 ? MOUSEEVENTF_RIGHTDOWN : MOUSEEVENTF_RIGHTUP;
                    SendMouseInput(flags, screenX, screenY);
                }
                else
                {
                    // Movement only — no button change
                    SendMouseInput(MOUSEEVENTF_MOVE, screenX, screenY);
                }
            }
            catch { }
        }

        private void OnFrameUpdate()
        {
            // There seems to be a bug in either the RemoteViewing.Vnc library or NoVNC
            // Basically the pixel format that is passed from NoVNC results in JPEGs that are black
            // Apart from some colour shift values being different the format is the same as the default
            // So to mitigate I force the default here every time we want to make a frame
            session.ClientPixelFormat = VncPixelFormat.RGB32;
            session.MaxUpdateRate = maxUpdateRate;
        }

        // TightEncoder subclass that always uses the JPEG path for large rectangles,
        // bypassing the library's quality-hint lookup (which never matches noVNC's hints).
        private sealed class JpegTightEncoder : TightEncoder
        {
            public JpegTightEncoder(VncServerSession session) : base(session)
            {
                Compression = TightCompression.Jpeg;
            }

            public override int Send(Stream stream, VncPixelFormat pixelFormat, VncRectangle region, byte[] contents)
            {
                if (!region.IsEmpty && contents.Length >= 256)
                {
                    return SendWithJpegCompression(stream, pixelFormat, region, contents, 50);
                }

                return SendWithBasicCompression(stream, pixelFormat, region, contents);
            }
        }

        public void Start(Stream stream)
        {
            // Set up a framebuffer and options.
            var options = new VncServerSessionOptions
            {
                AuthenticationMethod = AuthenticationMethod.None
            };

            framebuffer.Reset();

            // wait for client and server to set up connection
            session.Connect(stream, options);
        }

        private void HandleConnectionFailed(object sender, EventArgs e)
        {
            OnError();
        }

        private void HandleClosed(object sender, EventArgs e)
        {
            OnError();
        }

        protected virtual void Dispose(bool disposing)
        {
            if (!disposedValue)
            {
                if (disposing)
                {
                    OnError();
                    framebuffer.Dispose();
                }
                disposedValue = true;
            }
        }

        public void Dispose()
        {
            // Do not change this code. Put cleanup code in 'Dispose(bool disposing)' method
            Dispose(disposing: true);
            GC.SuppressFinalize(this);
        }

        public byte[] GenerateChallenge()
        {
            throw new NotImplementedException();
        }

        public void GetChallengeResponse(byte[] challenge, char[] password, byte[] response)
        {
            throw new NotImplementedException();
        }

        public void GetChallengeResponse(byte[] challenge, byte[] password, byte[] response)
        {
            throw new NotImplementedException();
        }
    }
}
