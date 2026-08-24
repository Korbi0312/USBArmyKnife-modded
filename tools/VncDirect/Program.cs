// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312

using Agent.VncDirect;

class Program
{
    private static string LogFile = "vnc.log";

    static void Main(string[] args)
    {
        int port = 7002;
        double fps = 15;
        int downscale = 2;
        string? root = null;

        foreach (var arg in args)
        {
            if (arg.StartsWith("port=")) int.TryParse(arg.Remove(0, 5), out port);
            else if (arg.StartsWith("fps=")) double.TryParse(arg.Remove(0, 4), out fps);
            else if (arg.StartsWith("scale=")) int.TryParse(arg.Remove(0, 6), out downscale);
            else if (arg.StartsWith("cwd=")) root = arg.Remove(0, 4);
            else if (arg.StartsWith("log=")) LogFile = arg.Remove(0, 4);
        }

        if (string.IsNullOrWhiteSpace(root) || !Directory.Exists(root))
        {
            root = Environment.CurrentDirectory;
        }
        else
        {
            Environment.CurrentDirectory = root;
        }

        AppDomain.CurrentDomain.UnhandledException += (s, e) =>
        {
            Log("Unhandled exception: " + e.ExceptionObject);
        };

        while (true)
        {
            try
            {
                var server = new VncDirectServer(port, root, fps, downscale);
                server.Start();
                Log($"VncDirect listening on port {port}, web root {root}, {fps} fps max, downscale {downscale}");
                Thread.Sleep(Timeout.Infinite);
            }
            catch (Exception ex)
            {
                Log("Server error: " + ex);
                Thread.Sleep(2000);
            }
        }
    }

    private static void Log(string message)
    {
        try
        {
            File.AppendAllText(LogFile, $"{DateTime.Now:yyyy-MM-dd HH:mm:ss} {message}{Environment.NewLine}");
        }
        catch
        {
        }
    }
}
