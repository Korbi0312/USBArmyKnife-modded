// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan
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
