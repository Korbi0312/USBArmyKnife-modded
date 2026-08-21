// SPDX-License-Identifier: MIT
// Copyright (c) 2026 Korbi0312
// Copyright (c) 2024 i-am-shodan
using HPPH;
using RemoteViewing.Vnc;
using ScreenCapture.NET;

namespace Agent.VNC
{
    internal class VNCFramebufferSource : IVncFramebufferSource, IDisposable
    {
        public bool SupportsResizing => false;

        public int Width { get; set; } = 200;

        public int Height { get; set; } = 400;

        private readonly IScreenCaptureService screenCaptureService;
        private readonly IEnumerable<GraphicsCard> graphicsCards;
        private readonly IEnumerable<Display> displays;
        private readonly IScreenCapture screenCapture;
        private readonly ICaptureZone fullscreen;
        private readonly int downscale = 2;
        private readonly int targetWidth = 0;
        private readonly int targetHeight = 0;
        private VncFramebuffer? framebuffer = null;
        private bool disposedValue;
        private DateTime lastUpdateTime = DateTime.MinValue;
        private Action onNewFrame;

        public VNCFramebufferSource(Action onNewFrame, int downscale = 2, int targetWidth = 0, int targetHeight = 0)
        {
            this.onNewFrame = onNewFrame;
            this.targetWidth = targetWidth;
            this.targetHeight = targetHeight;

            // Create a screen-capture service
            screenCaptureService = new DX11ScreenCaptureService();

            // Get all available graphics cards
            graphicsCards = screenCaptureService.GetGraphicsCards();

            // Get the displays from the graphics card(s) you are interested in
            displays = screenCaptureService.GetDisplays(graphicsCards.First());

            // Create a screen-capture for all screens you want to capture
            screenCapture = screenCaptureService.GetScreenCapture(displays.First());

            this.downscale = downscale;

            // Register the regions you want to capture on the screen
            // Capture the whole screen
            fullscreen = screenCapture.RegisterCaptureZone(0, 0, screenCapture.Display.Width, screenCapture.Display.Height, downscaleLevel: downscale);

            Width = fullscreen.Width;
            Height = fullscreen.Height;
        }

        public VncFramebuffer Capture()
        {
            onNewFrame();

            // Capture the screen
            // This should be done in a loop on a separate thread as CaptureScreen blocks if the screen is not updated (still image).
            screenCapture.CaptureScreen();

            using (fullscreen.Lock())
            {
                IImage image = fullscreen.Image;

                int outW = image.Width;
                int outH = image.Height;
                if (targetWidth > 0 && targetHeight > 0 && (targetWidth < image.Width || targetHeight < image.Height))
                {
                    // Scale down to the requested resolution (never upscale beyond
                    // the captured size). Proportional fit so the aspect ratio and
                    // the desktop size advertised to the client stay consistent.
                    double scale = Math.Min((double)targetWidth / image.Width, (double)targetHeight / image.Height);
                    if (scale < 1.0)
                    {
                        outW = Math.Max(1, (int)Math.Round(image.Width * scale));
                        outH = Math.Max(1, (int)Math.Round(image.Height * scale));
                    }
                }

                if (this.framebuffer == null || this.framebuffer.Width != outW || this.framebuffer.Height != outH)
                {
                    this.framebuffer = new VncFramebuffer("VNC", outW, outH, new VncPixelFormat());
                }

                RefImage<ColorBGRA> refImage = image.AsRefImage<ColorBGRA>();

                lock (this.framebuffer.SyncRoot)
                {
                    byte[] buf = this.framebuffer.GetBuffer();
                    int stride = this.framebuffer.Stride;

                    if (outW == image.Width && outH == image.Height)
                    {
                        // Direct copy: write BGRA rows straight into the framebuffer buffer
                        for (int row = 0; row < image.Height; row++)
                        {
                            int bufOffset = row * stride;
                            for (int col = 0; col < image.Width; col++)
                            {
                                ColorBGRA px = refImage[col, row];
                                buf[bufOffset]     = px.B;
                                buf[bufOffset + 1] = px.G;
                                buf[bufOffset + 2] = px.R;
                                buf[bufOffset + 3] = px.A;
                                bufOffset += 4;
                            }
                        }
                    }
                    else
                    {
                        // Bilinear downsample directly into the framebuffer buffer
                        float scaleX = (float)image.Width / outW;
                        float scaleY = (float)image.Height / outH;
                        for (int y = 0; y < outH; y++)
                        {
                            float sy = (y + 0.5f) * scaleY - 0.5f;
                            if (sy < 0) sy = 0;
                            int y0 = (int)sy;
                            int y1 = y0 + 1;
                            if (y1 >= image.Height) y1 = image.Height - 1;
                            float fy = sy - y0;
                            float oneMinusFy = 1 - fy;
                            int bufRow = y * stride;
                            for (int x = 0; x < outW; x++)
                            {
                                float sx = (x + 0.5f) * scaleX - 0.5f;
                                if (sx < 0) sx = 0;
                                int x0 = (int)sx;
                                int x1 = x0 + 1;
                                if (x1 >= image.Width) x1 = image.Width - 1;
                                float fx = sx - x0;
                                float oneMinusFx = 1 - fx;

                                ColorBGRA c00 = refImage[x0, y0];
                                ColorBGRA c10 = refImage[x1, y0];
                                ColorBGRA c01 = refImage[x0, y1];
                                ColorBGRA c11 = refImage[x1, y1];

                                int idx = bufRow + x * 4;
                                buf[idx]     = (byte)((c00.B * oneMinusFx + c10.B * fx) * oneMinusFy + (c01.B * oneMinusFx + c11.B * fx) * fy);
                                buf[idx + 1] = (byte)((c00.G * oneMinusFx + c10.G * fx) * oneMinusFy + (c01.G * oneMinusFx + c11.G * fx) * fy);
                                buf[idx + 2] = (byte)((c00.R * oneMinusFx + c10.R * fx) * oneMinusFy + (c01.R * oneMinusFx + c11.R * fx) * fy);
                                buf[idx + 3] = (byte)((c00.A * oneMinusFx + c10.A * fx) * oneMinusFy + (c01.A * oneMinusFx + c11.A * fx) * fy);
                            }
                        }
                    }
                }

                lastUpdateTime = DateTime.UtcNow;

                return this.framebuffer;
            }
        }

        public ExtendedDesktopSizeStatus SetDesktopSize(int width, int height)
        {
            return ExtendedDesktopSizeStatus.Prohibited;
        }

        protected virtual void Dispose(bool disposing)
        {
            if (!disposedValue)
            {
                if (disposing)
                {
                    screenCapture.Dispose();
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

        internal void Reset()
        {
            lastUpdateTime = DateTime.UtcNow;
        }
    }
}
