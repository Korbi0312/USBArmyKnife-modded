# USB Army Knife project media

This folder contains the project presentation and explainer media.

## Final filenames

Upload the original binary files with these names:

- `usb-army-knife-project-presentation.pdf` — 13-slide project presentation
- `usb-army-knife-project-explainer.mp4` — project explainer video

The current GitHub connector can commit text files, but it cannot safely upload binary PDF or MP4 content. Do not paste either file into a text editor or commit it as plain text; upload both files through GitHub's web interface or a local Git client instead.

## Where each presentation slide belongs

| Slide | Title | Suggested project section |
| ---: | --- | --- |
| 01 | Project overview | README introduction and project positioning |
| 02 | Physical access dilemma | README introduction: limitations of individual attack vectors |
| 03 | Unified solution | README feature overview |
| 04 | Hardware anatomy | Supported hardware: LILYGO T-Dongle S3 |
| 05 | Multi-vector arsenal | Features: USB, storage, network and wireless capabilities |
| 06 | Modded evolution | Modded features and comparison with upstream |
| 07 | Global command center | Web UI, internationalisation, SD dashboard and file browser |
| 08 | Reliable storage | Byte-exact saving, disk-full detection and streaming reads |
| 09 | VncDirect architecture | VNC / remote screen viewing and Tailscale access |
| 10 | Stealth, feedback and expansion | Crash LED, microphone support and PNG display |
| 11 | PC agent lifecycle | Agent installation, persistence, password protection and removal |
| 12 | Deployment pipeline | Getting started: flash firmware, deploy agent, access the UI |
| 13 | Complete tactical stack | Final project architecture summary |

## Recommended README media order

1. Place `usb-army-knife-project-explainer.mp4` directly at the start of the project presentation section.
2. Place `usb-army-knife-project-presentation.pdf` immediately after the video as the complete visual deep dive.
3. Use the slide mapping above when adding individual slide previews to the relevant README sections.

## Binary upload checklist

1. Create or open `docs/media/` on the `master` branch.
2. Upload the PDF as `usb-army-knife-project-presentation.pdf`.
3. Upload the MP4 as `usb-army-knife-project-explainer.mp4`.
4. Confirm that GitHub shows both files with their expected file sizes before committing.
5. Keep the original files unchanged so the presentation remains readable and the video remains playable.
