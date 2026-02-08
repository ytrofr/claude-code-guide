# TrendRadar Local Dashboard

Simple local dashboard for viewing TrendRadar trend insights.

## Quick Start

```bash
cd ~/claude-code-guide/tools/trendradar-dashboard
npm install
npm start
# Open http://localhost:4444
```

## Architecture

- **Port**: 4444 (isolated, never conflicts)
- **Data Source**: `~/TrendRadar/output/` (JSON files)
- **Auto-refresh**: Every 5 minutes

## Auto-Start on Login

Add to `~/.bashrc`:

```bash
source ~/claude-code-guide/tools/trendradar-dashboard/start.sh
```

## API Endpoints

| Endpoint          | Description          |
| ----------------- | -------------------- |
| `GET /`           | Dashboard UI         |
| `GET /api/trends` | Latest trend data    |
| `GET /api/files`  | List available files |
| `GET /api/health` | Health check         |

## Dependencies

- Node.js 18+
- TrendRadar installed at `~/TrendRadar`

## Generating Trend Data

```bash
cd ~/TrendRadar
source venv/bin/activate
python -m trendradar
# JSON files appear in ~/TrendRadar/output/
```

## Customization

Edit `public/app.js` to adjust rendering based on TrendRadar's JSON structure.

## Related

- [TrendRadar GitHub](https://github.com/sansan0/TrendRadar)
- [MCP Market - TrendRadar](https://mcpmarket.com/server/trendradar)
