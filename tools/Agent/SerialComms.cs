// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan
using RJCP.IO.Ports;
using WmiLight;

namespace Agent
{
    public class DeviceNotFoundException : Exception
    {

    }

    internal class SerialComms
    {
        private readonly Executer executer = new();

        private string? GetMatchingSerialPort(string vidToMatch, string pidToMatch)
        {
            vidToMatch = vidToMatch.ToUpperInvariant();
            pidToMatch = pidToMatch.ToUpperInvariant();

            string? firstUsbPort = null;

            using (WmiConnection con = new WmiConnection())
            {
                foreach (WmiObject p in con.CreateQuery("SELECT * FROM WIN32_SerialPort"))
                {
                    var deviceId = p["PNPDeviceID"].ToString();
                    if (!string.IsNullOrWhiteSpace(deviceId) && deviceId.StartsWith("USB"))
                    {
                        string VID = string.Empty;
                        string PID = string.Empty;
                        foreach (var item in deviceId.Split(new string[] { "\\", "&" }, StringSplitOptions.RemoveEmptyEntries))
                        {
                            if (item.StartsWith("VID"))
                            {
                                VID = item.Split("_", StringSplitOptions.RemoveEmptyEntries)[1];
                            }
                            if (item.StartsWith("PID"))
                            {
                                PID = item.Split("_", StringSplitOptions.RemoveEmptyEntries)[1];
                            }
                        }

                        if (VID == vidToMatch && PID == pidToMatch)
                        {
                            return p.GetPropertyValue("DeviceID").ToString();
                        }

                        // Remember the first real USB serial port so we can fall
                        // back to it when the configured VID/PID does not match
                        // (the device may enumerate with a different VID/PID).
                        if (firstUsbPort == null)
                        {
                            firstUsbPort = p.GetPropertyValue("DeviceID").ToString();
                        }
                    }
                }
            }

            return firstUsbPort;
        }

        public void Start(string vid, string pid, int baud = 115200)
        {
            var serialPort = GetMatchingSerialPort(vid, pid);

            if (string.IsNullOrWhiteSpace(serialPort))
            {
                throw new DeviceNotFoundException();
            }

            ReadCommands(baud, serialPort);
        }

        private void ReadCommands(int baud, object serialPortName)
        {
#if DEBUG
            Console.WriteLine($"Opening {serialPortName}");
#endif

            using (var cts = new CancellationTokenSource())
            using (var m_RxPort = new SerialPortStream(serialPortName.ToString())
            {
                BaudRate = 115200,
                DataBits = 8,
                Parity = Parity.None,
                StopBits = StopBits.One,
                ReadTimeout = -1,
                WriteTimeout = -1
            })
            {
                m_RxPort.Open();

                // Announce our LAN IP so the device can hand it to the noVNC page,
                // which then connects to the VNC server on this PC directly.
                executer.SendAgentIp(m_RxPort);

                using (var ipTimer = new System.Threading.Timer(
                    _ => executer.SendAgentIp(m_RxPort),
                    null,
                    TimeSpan.FromSeconds(60),
                    TimeSpan.FromSeconds(60)))
                {
                    while (!cts.IsCancellationRequested)
                    {
                        try
                        {
                            executer.ParseAndExecute(m_RxPort, cts);
                        }
                        catch (Exception)
                        {
                            cts.Cancel();
                            throw;
                        }
                    }
                }
            }

#if DEBUG
            Console.WriteLine("Serial port closed");
#endif
        }
    }
}
