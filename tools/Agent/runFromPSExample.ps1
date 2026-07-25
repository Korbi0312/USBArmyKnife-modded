# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Korbi0312
# Copyright (c) 2024 i-am-shodan

Add-Type @”
    using System;
    using System.Text;
    using System.Runtime.InteropServices;

    public class Posh
    {
        [DllImport("FULL_PATH_TO\\PortableApp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
        static extern void Open(string str);

        public static void OpenMe()
        {
            Open("vid=cafe pid=1001");
        }
    }
“@
[Posh]::OpenMe()