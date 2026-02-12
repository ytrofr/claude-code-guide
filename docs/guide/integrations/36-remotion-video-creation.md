# Chapter 36: Remotion Video Creation

**Purpose**: Create programmatic videos with React using Remotion framework
**Source**: Remotion docs + LIMOR AI mobile demo implementation (Feb 2026)
**ROI**: 8-10 hours saved per demo video vs manual editing

---

## What is Remotion?

Remotion is a React framework for creating videos programmatically. Instead of using video editing software, you write React components that render frame-by-frame into video files.

**Use Cases**:

- Demo videos for software products
- Mobile app mockups with animations
- Marketing content with typing effects
- Personalized videos at scale (Spotify Wrapped style)
- Social media content (TikTok, Reels, YouTube Shorts)

---

## Quick Setup

### 1. Create New Project

```bash
npx create-video@latest my-video
cd my-video
npm install
npm run dev  # Opens Remotion Studio
```

### 2. Install Remotion Skills

```bash
# Add official Remotion best practices to Claude Code
npx skills add remotion-dev/skills
```

### 3. Configure MCP Server

Add to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "remotion-documentation": {
      "command": "npx",
      "args": ["@remotion/mcp@latest"]
    }
  }
}
```

This enables Claude Code to query Remotion documentation via vector search.

---

## Core Concepts

### Compositions

Compositions are the entry points for videos:

```tsx
import { Composition } from "remotion";
import { MyVideo } from "./MyVideo";

export const RemotionRoot: React.FC = () => (
  <Composition
    id="MyVideo"
    component={MyVideo}
    durationInFrames={300} // 10 seconds at 30fps
    fps={30}
    width={1920}
    height={1080}
  />
);
```

### Frame-Based Animation

{% raw %}

```tsx
import { useCurrentFrame, interpolate, spring } from "remotion";

export const FadeIn: React.FC = () => {
  const frame = useCurrentFrame();

  // Linear fade (0-30 frames)
  const opacity = interpolate(frame, [0, 30], [0, 1], {
    extrapolateRight: "clamp",
  });

  // Bouncy scale with spring physics
  const scale = spring({
    frame,
    fps: 30,
    config: { damping: 12, stiffness: 100 },
  });

  return (
    <div style={{ opacity, transform: `scale(${scale})` }}>Hello World</div>
  );
};
```

{% endraw %}

---

## Mobile Video Patterns

### 9:16 Vertical Format

For TikTok, Instagram Reels, YouTube Shorts:

```tsx
<Composition
  id="MobileDemo"
  component={MobileDemo}
  width={1080}
  height={1920} // 9:16 aspect ratio
  fps={30}
  durationInFrames={300}
/>
```

### Phone Mockup Component

{% raw %}

```tsx
export const PhoneMockup: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => (
  <div
    style={{
      width: 390,
      height: 844,
      borderRadius: 40,
      border: "8px solid #1a1a1a",
      overflow: "hidden",
      backgroundColor: "#000",
      boxShadow: "0 25px 50px rgba(0,0,0,0.5)",
    }}
  >
    {children}
  </div>
);
```

{% endraw %}

### Touch Animation (Ripple Effect)

{% raw %}

```tsx
export const TouchAnimation: React.FC<{ x: number; y: number }> = ({
  x,
  y,
}) => {
  const frame = useCurrentFrame();
  const scale = spring({ frame, fps: 30, config: { damping: 15 } });
  const opacity = interpolate(frame, [0, 20], [0.8, 0], {
    extrapolateRight: "clamp",
  });

  return (
    <div
      style={{
        position: "absolute",
        left: x - 30,
        top: y - 30,
        width: 60,
        height: 60,
        borderRadius: "50%",
        backgroundColor: "rgba(255,255,255,0.3)",
        transform: `scale(${scale})`,
        opacity,
      }}
    />
  );
};
```

{% endraw %}

---

## Screenshot-Based Animation

For typing effects or UI state changes, capture screenshots with Playwright:

### Playwright Capture Script

```typescript
// scripts/capture-sequence.ts
import { chromium } from "playwright";

async function captureTyping(message: string) {
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2, // Retina
    isMobile: true,
    hasTouch: true,
  });

  const page = await context.newPage();
  await page.goto("http://localhost:3000");

  // Letter-by-letter capture
  for (let i = 1; i <= message.length; i++) {
    await page.fill("input", message.substring(0, i));
    await page.screenshot({
      path: `public/screenshots/typing-${i.toString().padStart(3, "0")}.png`,
    });
  }

  await browser.close();
}
```

### Use Screenshots in Composition

{% raw %}

```tsx
import { Img, staticFile } from "remotion";

export const TypingAnimation: React.FC<{ screenshots: string[] }> = ({
  screenshots,
}) => {
  const frame = useCurrentFrame();
  const framesPerScreenshot = 3; // 3 frames per character

  const currentIndex = Math.min(
    Math.floor(frame / framesPerScreenshot),
    screenshots.length - 1,
  );

  return (
    <Img
      src={staticFile(`screenshots/${screenshots[currentIndex]}`)}
      style={{ width: "100%", height: "100%", objectFit: "cover" }}
    />
  );
};
```

{% endraw %}

---

## Critical Rules

### Determinism (MANDATORY)

Remotion renders videos by running your code multiple times for each frame. Non-deterministic code breaks rendering:

```tsx
// WRONG - Different value each render
const badValue = Math.random();

// CORRECT - Use Remotion's seeded random
import { random } from "remotion";
const goodValue = random("my-seed");
```

### Asset Loading

Always use `staticFile()` for assets in `/public`:

```tsx
import { staticFile, Img, Audio } from 'remotion';

<Img src={staticFile('logo.png')} />
<Audio src={staticFile('background.mp3')} />
```

### Frame Calculations

```tsx
const fps = 30;
const frame = useCurrentFrame();

// Convert frame to seconds
const timeInSeconds = frame / fps;

// Start animation at 1 second
const delayedOpacity = interpolate(
  frame,
  [30, 60], // 1-2 seconds
  [0, 1],
  { extrapolateLeft: "clamp", extrapolateRight: "clamp" },
);
```

---

## Rendering

### Basic Render

```bash
npx remotion render MyVideo out/video.mp4
```

### Options

```bash
# Lower resolution (faster)
npx remotion render MyVideo out/preview.mp4 --scale=0.5

# Custom dimensions
npx remotion render MyVideo out/vertical.mp4 --width=1080 --height=1920

# Specific frame range
npx remotion render MyVideo out/clip.mp4 --frames=0-90
```

---

## TailwindCSS Integration

Tailwind works out of the box:

```tsx
<div
  className="bg-gradient-to-r from-blue-500 to-purple-600
                text-white text-6xl font-bold p-8 rounded-xl"
>
  Animated Title
</div>
```

---

## Prompt Engineering Tips

When asking Claude Code to create Remotion compositions:

| Pattern        | Example Prompt                                                                               |
| -------------- | -------------------------------------------------------------------------------------------- |
| Structured     | "Create a 10-sec explainer: typing effect, intro card, outro. Blue accent, 1920x1080, 30fps" |
| Iterative      | "Change the accent color to purple and slow down the typing"                                 |
| Start simple   | "Create a text reveal animation that fades in word by word"                                  |
| Reference docs | "Use the Remotion documentation to show me how to add audio"                                 |

---

## Project Structure

```
my-video/
├── src/
│   ├── Root.tsx           # Composition registry
│   ├── compositions/      # Video entry points
│   └── components/        # Reusable elements
├── scripts/
│   └── capture.ts         # Playwright screenshots
├── public/
│   └── screenshots/       # Captured frames
└── package.json
```

---

## Advanced: Lambda Rendering

For production/batch rendering:

```bash
# Deploy to AWS Lambda
npx remotion lambda sites create --site-name=my-videos

# Render on Lambda
npx remotion lambda render my-videos MyVideo
```

---

## Resources

- **Docs**: [remotion.dev/docs](https://www.remotion.dev/docs)
- **AI Guide**: [remotion.dev/docs/ai/claude-code](https://www.remotion.dev/docs/ai/claude-code)
- **Skills**: `npx skills add remotion-dev/skills`
- **MCP**: `@remotion/mcp` for documentation queries

---

## Common Patterns

| Effect       | Implementation                                       |
| ------------ | ---------------------------------------------------- |
| Fade in      | `interpolate(frame, [0, 30], [0, 1])`                |
| Scale bounce | `spring({ frame, fps, config: { damping: 8 }})`      |
| Slide up     | `interpolate(frame, [0, 20], [100, 0])` (translateY) |
| Stagger      | `<Sequence from={0}>`, `<Sequence from={15}>`        |
| Typing       | Screenshot cycling with frame math                   |

---

**Previous**: [35: Skill Optimization Maintenance](35-skill-optimization-maintenance.md)
**Index**: [Quick Start Guide](../quick-start.md)
