// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312

using System.Collections.Concurrent;
using System.Net;
using Agent.VNC;
using Microsoft.Extensions.Logging;
using WebSocketSharp;
using WebSocketSharp.Server;

namespace Agent.VncDirect
{
    internal class VncDirectServer
    {
        private static readonly Dictionary<string, string> MimeTypes = new(StringComparer.OrdinalIgnoreCase)
        {
            [".html"] = "text/html",
            [".js"] = "application/javascript",
            [".css"] = "text/css",
            [".png"] = "image/png",
            [".jpg"] = "image/jpeg",
            [".jpeg"] = "image/jpeg",
            [".gif"] = "image/gif",
            [".svg"] = "image/svg+xml",
            [".ico"] = "image/x-icon",
            [".txt"] = "text/plain",
            [".json"] = "application/json",
            [".woff"] = "font/woff",
            [".woff2"] = "font/woff2"
        };

        private readonly int port;
        private readonly string rootPath;
        private readonly double maxUpdateRate;
        private readonly int downscale;
        private double defaultFps;
        private int defaultWidth;
        private int defaultHeight;
        private string vncPassword = "";
        private HttpServer? httpServer;

        private static readonly string SettingsPath = Path.Combine(AppContext.BaseDirectory, "vnc-settings.json");

        public VncDirectServer(int port, string rootPath, double maxUpdateRate = 15, int downscale = 2)
        {
            this.port = port;
            this.rootPath = rootPath;
            this.maxUpdateRate = maxUpdateRate;
            this.downscale = downscale;
            this.defaultFps = maxUpdateRate;
            this.defaultWidth = 0;
            this.defaultHeight = 0;
            LoadSettingsFromFile();
        }

        private void LoadSettingsFromFile()
        {
            try
            {
                if (File.Exists(SettingsPath))
                {
                    var json = System.Text.Json.JsonDocument.Parse(File.ReadAllText(SettingsPath));
                    if (json.RootElement.TryGetProperty("width", out var w)) { if (w.TryGetInt32(out var wi)) defaultWidth = wi; }
                    if (json.RootElement.TryGetProperty("height", out var h)) { if (h.TryGetInt32(out var hi)) defaultHeight = hi; }
                    if (json.RootElement.TryGetProperty("fps", out var f)) { if (f.TryGetDouble(out var fd) && fd > 0) defaultFps = fd; }
                    if (json.RootElement.TryGetProperty("password", out var p)) { vncPassword = p.GetString() ?? ""; }
                    Log($"Loaded settings from {SettingsPath}: {defaultWidth}x{defaultHeight} @ {defaultFps} fps");
                }
            }
            catch (Exception ex)
            {
                Log("Could not load settings file: " + ex.Message);
            }
        }

        private static Dictionary<string, string> ParseQuery(string query)
        {
            var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            if (string.IsNullOrEmpty(query)) return result;
            query = query.TrimStart('?', '#');
            foreach (var part in query.Split('&', StringSplitOptions.RemoveEmptyEntries))
            {
                var idx = part.IndexOf('=');
                if (idx < 0) continue;
                var key = Uri.UnescapeDataString(part.Substring(0, idx));
                var value = Uri.UnescapeDataString(part.Substring(idx + 1));
                result[key] = value;
            }
            return result;
        }

        public void Start()
        {
            var bindIp = GetLanIpAddress();
            httpServer = new HttpServer(bindIp, port);
            httpServer.OnGet += OnGet;
            httpServer.OnPost += OnPost;
            httpServer.AddWebSocketService<VncBehavior>("/websockify", () => new VncBehavior(this));
            httpServer.Start();
        }

        private static IPAddress GetLanIpAddress()
        {
            IPAddress? fallback = null;
            try
            {
                foreach (var ni in System.Net.NetworkInformation.NetworkInterface.GetAllNetworkInterfaces())
                {
                    if (ni.OperationalStatus != System.Net.NetworkInformation.OperationalStatus.Up) continue;
                    if (ni.NetworkInterfaceType == System.Net.NetworkInformation.NetworkInterfaceType.Loopback) continue;
                    if (ni.NetworkInterfaceType == System.Net.NetworkInformation.NetworkInterfaceType.Tunnel) continue;
                    var name = ni.Name.ToLowerInvariant();
                    if (name.Contains("virtualbox") || name.Contains("vmware") || name.Contains("hyper-v")) continue;
                    foreach (var addr in ni.GetIPProperties().UnicastAddresses)
                    {
                        if (addr.Address.AddressFamily != System.Net.Sockets.AddressFamily.InterNetwork) continue;
                        var ip = addr.Address.ToString();
                        if (ip.StartsWith("192.168.56.")) continue;
                        if (ip.StartsWith("10.0.") || ip.StartsWith("172.16.") || ip.StartsWith("172.17.")) continue;
                        if (ip.StartsWith("192.168.") || ip.StartsWith("10.") || ip.StartsWith("172."))
                        {
                            if (fallback == null) fallback = addr.Address;
                            if (ni.GetIPProperties().GatewayAddresses.Count > 0)
                                return addr.Address;
                        }
                    }
                }
            }
            catch { }
            return fallback ?? System.Net.IPAddress.Any;
        }

        public void Stop()
        {
            httpServer?.Stop();
        }

        private static bool IsLocalhost(WebSocketSharp.Net.HttpListenerRequest request)
        {
            var urlHost = request.Url?.Host ?? "";
            var userHost = request.UserHostName ?? "";
            var headerHost = request.Headers["Host"] ?? "";
            var remoteIp = request.RemoteEndPoint?.Address?.ToString() ?? "";

            return urlHost == "localhost" || urlHost == "127.0.0.1" || urlHost == "::1"
                || userHost == "localhost" || userHost.StartsWith("127.0.0.1") || userHost.StartsWith("[::1]")
                || headerHost.StartsWith("localhost") || headerHost.StartsWith("127.0.0.1")
                || remoteIp == "127.0.0.1" || remoteIp == "::1";
        }

        private void BlockLocalhost(WebSocketSharp.Net.HttpListenerResponse response)
        {
            response.StatusCode = 403;
            var msg = System.Text.Encoding.UTF8.GetBytes("Access denied");
            response.ContentLength64 = msg.Length;
            response.OutputStream.Write(msg, 0, msg.Length);
            response.Close();
        }

        private void OnGet(object? sender, HttpRequestEventArgs e)
        {
            var request = e.Request;
            var response = e.Response;
            var path = request.Url?.AbsolutePath ?? "/";

            if (path == "/api/settings")
            {
                var tailscaleIp = DetectTailscaleIp();
                var hasPw = vncPassword.Length > 0 ? "true" : "false";
                var json = "{\"width\":" + defaultWidth + ",\"height\":" + defaultHeight + ",\"fps\":" + defaultFps.ToString(System.Globalization.CultureInfo.InvariantCulture) + ",\"tailscaleIp\":\"" + (tailscaleIp ?? "") + "\",\"hasPassword\":" + hasPw + "}";
                response.ContentType = "application/json";
                var bytes = System.Text.Encoding.UTF8.GetBytes(json);
                response.ContentLength64 = bytes.Length;
                response.OutputStream.Write(bytes, 0, bytes.Length);
                response.Close();
                return;
            }

            if (path == "/api/verify-password")
            {
                var query = ParseQuery(request.Url?.Query ?? "");
                var ok = false;
                if (query.TryGetValue("pw", out var input))
                {
                    ok = string.Equals(input, vncPassword, StringComparison.Ordinal);
                }
                var resBytes = System.Text.Encoding.UTF8.GetBytes(ok ? "{\"ok\":true}" : "{\"ok\":false}");
                response.ContentType = "application/json";
                response.ContentLength64 = resBytes.Length;
                response.OutputStream.Write(resBytes, 0, resBytes.Length);
                response.Close();
                return;
            }

            if (path == "/" || path.Length == 0)
            {
                path = "/index.html";
            }

            var file = Path.Combine(rootPath, path.TrimStart('/'));
            if (!File.Exists(file))
            {
                response.StatusCode = (int)HttpStatusCode.NotFound;
                response.Close();
                return;
            }

            response.ContentType = MimeTypes.TryGetValue(Path.GetExtension(file), out var mime) ? mime : "application/octet-stream";

            var data = File.ReadAllBytes(file);
            response.ContentLength64 = data.Length;
            response.OutputStream.Write(data, 0, data.Length);
            response.Close();
        }

        private void OnPost(object? sender, HttpRequestEventArgs e)
        {
            var request = e.Request;
            var response = e.Response;
            var path = request.Url?.AbsolutePath ?? "/";

            if (path == "/api/settings")
            {
                // Try query params first, fall back to POST body (key=value or JSON)
                var query = ParseQuery(request.Url?.Query ?? "");
                string body = "";
                using (var reader = new StreamReader(request.InputStream, request.ContentEncoding))
                    body = reader.ReadToEnd();
                if (!string.IsNullOrWhiteSpace(body))
                {
                    foreach (var part in body.Split('&', StringSplitOptions.RemoveEmptyEntries))
                    {
                        var idx = part.IndexOf('=');
                        if (idx < 0) continue;
                        var key = Uri.UnescapeDataString(part.Substring(0, idx));
                        var val = Uri.UnescapeDataString(part.Substring(idx + 1));
                        query[key] = val;
                    }
                }

                if (query.TryGetValue("width", out var ws) && int.TryParse(ws, out var wv) && wv > 0) defaultWidth = wv;
                if (query.TryGetValue("height", out var hs) && int.TryParse(hs, out var hv) && hv > 0) defaultHeight = hv;
                if (query.TryGetValue("fps", out var fs) && double.TryParse(fs, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var fv) && fv > 0) defaultFps = fv;
                if (query.TryGetValue("password", out var pw)) vncPassword = Uri.UnescapeDataString(pw);

                try
                {
                    var json = "{\"width\":" + defaultWidth + ",\"height\":" + defaultHeight + ",\"fps\":" + defaultFps.ToString(System.Globalization.CultureInfo.InvariantCulture) + ",\"password\":\"" + vncPassword.Replace("\\", "\\\\").Replace("\"", "\\\"") + "\"}";
                    File.WriteAllText(SettingsPath, json);
                    Log($"Settings saved: {defaultWidth}x{defaultHeight} @ {defaultFps} fps, password {(vncPassword.Length > 0 ? "set" : "cleared")}");
                }
                catch (Exception ex)
                {
                    Log("Could not save settings: " + ex.Message);
                }

                response.StatusCode = (int)HttpStatusCode.OK;
                response.Close();
                return;
            }

            response.StatusCode = (int)HttpStatusCode.NotFound;
            response.Close();
        }

        private static string? DetectTailscaleIp()
        {
            try
            {
                foreach (var iface in System.Net.NetworkInformation.NetworkInterface.GetAllNetworkInterfaces())
                {
                    if (iface.OperationalStatus != System.Net.NetworkInformation.OperationalStatus.Up) continue;
                    foreach (var addr in iface.GetIPProperties().UnicastAddresses)
                    {
                        if (addr.Address.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
                        {
                            var ip = addr.Address.ToString();
                            if (ip.StartsWith("100.")) return ip;
                        }
                    }
                }
            }
            catch { }
            return null;
        }

internal void HandleOpen(VncBehavior behavior)
        {
            var thread = new Thread(() =>
            {
                try
                {
                    // Per-connection settings: query parameters on the WebSocket
                    // URL win over the persisted file values, which win over the
                    // command line defaults.
                    int tWidth = defaultWidth;
                    int tHeight = defaultHeight;
                    double tFps = defaultFps;

                    var query = ParseQuery(behavior.Context?.RequestUri?.Query ?? "");
                    if (query.TryGetValue("w", out var ws) && int.TryParse(ws, out var wv) && wv > 0) tWidth = wv;
                    if (query.TryGetValue("h", out var hs) && int.TryParse(hs, out var hv) && hv > 0) tHeight = hv;
                    if (query.TryGetValue("fps", out var fs) && double.TryParse(fs, out var fv) && fv > 0) tFps = fv;

                    Log($"VNC session settings: {tWidth}x{tHeight} @ {tFps} fps (query: {behavior.Context?.RequestUri?.Query})");

                    var stream = new VncWsStream(behavior);
                    behavior.AttachStream(stream);

                    var vnc = new VNCServer(() => { }, tFps, 0, FileLoggerFactory, tWidth, tHeight);
                    behavior.AttachVnc(vnc);

                    Log("VNC session started");
                    vnc.Start(stream);
                    Log("VNC session ended");
                }
                catch (Exception ex)
                {
                    Log("VNC session error: " + ex);
                    try
                    {
                        behavior.CloseStream();
                        behavior.DisposeVnc();
                    }
                    catch
                    {
                    }
                }
            })
            {
                IsBackground = true,
                Name = "VncDirectSession"
            };
            thread.Start();
        }

        internal void HandleMessage(VncBehavior behavior, byte[] data)
        {
            behavior.PushData(data);
        }

        internal void HandleClose(VncBehavior behavior)
        {
            Log("WS closed");
            behavior.CloseStream();
            behavior.DisposeVnc();
        }

        private static readonly string LogPath = Path.Combine(AppContext.BaseDirectory, "vnc.log");

        private static readonly ILoggerFactory FileLoggerFactory = CreateLoggerFactory();

        private static ILoggerFactory CreateLoggerFactory()
        {
            var factory = new LoggerFactory();
            factory.AddProvider(new FileLoggerProvider());
            return factory;
        }

        internal static void Log(string message)
        {
            try
            {
                File.AppendAllText(LogPath, $"{DateTime.Now:HH:mm:ss} {message}{Environment.NewLine}");
            }
            catch
            {
            }
        }
    }

    internal class FileLoggerProvider : ILoggerProvider
    {
        public ILogger CreateLogger(string categoryName) => new FileLogger();

        public void Dispose()
        {
        }
    }

    internal class FileLogger : ILogger
    {
        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

        public bool IsEnabled(Microsoft.Extensions.Logging.LogLevel logLevel) => logLevel >= Microsoft.Extensions.Logging.LogLevel.Warning;

        public void Log<TState>(Microsoft.Extensions.Logging.LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
        {
            if (logLevel < Microsoft.Extensions.Logging.LogLevel.Warning)
            {
                return;
            }

            var message = formatter(state, exception);
            VncDirectServer.Log($"[{logLevel}] {message}" + (exception != null ? $" :: {exception}" : ""));
        }
    }

    internal class VncBehavior : WebSocketBehavior
    {
        private readonly VncDirectServer owner;
        private VncWsStream? stream;
        private VNCServer? vnc;

        public VncBehavior(VncDirectServer owner)
        {
            this.owner = owner;
        }

        internal void AttachStream(VncWsStream stream)
        {
            this.stream = stream;
        }

        internal void AttachVnc(VNCServer vnc)
        {
            this.vnc = vnc;
        }

        internal void PushData(byte[] data)
        {
            stream?.Push(data);
        }

        internal void CloseStream()
        {
            stream?.CloseIncoming();
        }

        internal void DisposeVnc()
        {
            try
            {
                vnc?.Dispose();
            }
            catch
            {
            }
            vnc = null;
        }

        protected override void OnOpen()
        {
            owner.HandleOpen(this);
        }

        protected override void OnMessage(MessageEventArgs e)
        {
            owner.HandleMessage(this, e.RawData);
        }

        protected override void OnClose(CloseEventArgs e)
        {
            owner.HandleClose(this);
        }

        protected override void OnError(WebSocketSharp.ErrorEventArgs e)
        {
            owner.HandleClose(this);
        }
    }

    // Stream that bridges a WebSocket connection to the VNC server session.
    // Read blocks until the next binary WebSocket frame arrives, Write sends a frame.
    internal class VncWsStream : Stream
    {
        private readonly WebSocketBehavior behavior;
        private readonly BlockingCollection<byte[]> incoming = new();
        private byte[]? currentBlock;
        private int currentOffset;

        public VncWsStream(WebSocketBehavior behavior)
        {
            this.behavior = behavior;
        }

        public void Push(byte[] data)
        {
            incoming.Add(data);
        }

        public void CloseIncoming()
        {
            try
            {
                incoming.Add(Array.Empty<byte>());
            }
            catch (ObjectDisposedException)
            {
            }
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            while (currentBlock == null || currentOffset >= currentBlock.Length)
            {
                byte[] block;
                try
                {
                    block = incoming.Take();
                }
                catch (ObjectDisposedException)
                {
                    return 0;
                }

                if (block.Length == 0)
                {
                    return 0;
                }

                currentBlock = block;
                currentOffset = 0;
            }

            var toCopy = Math.Min(count, currentBlock.Length - currentOffset);
            Array.Copy(currentBlock, currentOffset, buffer, offset, toCopy);
            currentOffset += toCopy;
            return toCopy;
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            using (var ms = new MemoryStream(buffer, offset, count))
            {
                behavior.Context.WebSocket.Send(ms, count);
            }
        }

        public override bool CanRead => true;
        public override bool CanWrite => true;
        public override bool CanSeek => false;
        public override long Length => throw new NotSupportedException();
        public override long Position { get => throw new NotSupportedException(); set => throw new NotSupportedException(); }
        public override void Flush() { }
        public override long Seek(long offset, SeekOrigin origin) => throw new NotSupportedException();
        public override void SetLength(long value) => throw new NotSupportedException();
    }
}