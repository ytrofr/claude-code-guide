/**
 * Changelog Module - Fetch Claude Code releases and docs changes
 */

const BaseModule = require("./base-module");

class ChangelogModule extends BaseModule {
  async fetch() {
    const mode = this.config.mode || "releases";
    if (mode === "releases") return this.fetchReleases();
    if (mode === "docs") return this.fetchDocs();
    return [];
  }

  /**
   * Mode: releases - GitHub Releases API
   */
  async fetchReleases() {
    const maxItems = this.config.max_items || 30;
    const url = `${this.url}?per_page=${maxItems}`;

    const res = await fetch(url, {
      headers: {
        Accept: "application/vnd.github.v3+json",
        "User-Agent": "AI-Intelligence-Hub/1.0",
      },
    });

    if (!res.ok) {
      console.error(`Changelog releases fetch error: ${res.status}`);
      return [];
    }

    const releases = await res.json();
    return releases.map((release) => {
      const body = release.body || "";
      const changes = this.parseChanges(body);
      const plainText = this.stripMarkdown(body);

      return this.normalize({
        id: release.tag_name || release.id.toString(),
        title: `Claude Code ${release.tag_name || release.name}`,
        url: release.html_url,
        description: plainText.substring(0, 500),
        author: "anthropic",
        published_at: release.published_at,
        score: this.recencyScore(release.published_at),
        metadata: {
          version: (release.tag_name || "").replace(/^v/, ""),
          type: "release",
          change_count: changes.length,
          changes: changes.slice(0, 10),
          prerelease: release.prerelease,
        },
      });
    });
  }

  /**
   * Mode: docs - Fetch and parse CHANGELOG.md from GitHub
   */
  async fetchDocs() {
    const res = await fetch(this.url, {
      headers: { "User-Agent": "AI-Intelligence-Hub/1.0" },
    });

    if (!res.ok) {
      console.error(`Changelog docs fetch error: ${res.status}`);
      return [];
    }

    const markdown = await res.text();
    return this.parseChangelogMd(markdown);
  }

  /**
   * Parse CHANGELOG.md into version sections
   */
  parseChangelogMd(markdown) {
    const items = [];
    const maxItems = this.config.max_items || 30;
    // Match ## version headings (e.g. "## 2.1.39" or "## [2.1.39]")
    const sections = markdown.split(/^## /m).slice(1);

    for (const section of sections.slice(0, maxItems)) {
      const firstLine = section.split("\n")[0];
      const versionMatch = firstLine.match(/\[?(\d+\.\d+\.\d+)\]?/);
      if (!versionMatch) continue;

      const version = versionMatch[1];
      const rest = section.substring(firstLine.length);
      const changes = this.parseChanges(rest);
      const plainText = this.stripMarkdown(rest);

      // Try to extract date from heading line (e.g. "## 2.1.39 (2026-02-10)")
      const dateMatch = firstLine.match(/(\d{4}-\d{2}-\d{2})/);
      const published_at = dateMatch
        ? new Date(dateMatch[1]).toISOString()
        : null;

      items.push(
        this.normalize({
          id: `changelog-${version}`,
          title: `Claude Code Changelog: v${version}`,
          url: `https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md`,
          description: plainText.substring(0, 500),
          author: "anthropic",
          published_at,
          score: this.recencyScore(published_at),
          metadata: {
            version,
            type: "changelog",
            change_count: changes.length,
            changes: changes.slice(0, 10),
          },
        }),
      );
    }

    return items;
  }

  /**
   * Extract bullet points from markdown release body
   */
  parseChanges(markdown) {
    return markdown
      .split("\n")
      .filter((line) => /^\s*[-*]\s+/.test(line))
      .map((line) => line.replace(/^\s*[-*]\s+/, "").trim())
      .filter((line) => line.length > 0);
  }

  /**
   * Strip markdown formatting to plain text
   */
  stripMarkdown(md) {
    return md
      .replace(/#{1,6}\s+/g, "")
      .replace(/\*\*([^*]+)\*\*/g, "$1")
      .replace(/\*([^*]+)\*/g, "$1")
      .replace(/`([^`]+)`/g, "$1")
      .replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
      .replace(/\n{2,}/g, " ")
      .replace(/\n/g, " ")
      .trim();
  }

  /**
   * Score based on recency (newer = higher)
   */
  recencyScore(dateStr) {
    if (!dateStr) return 50;
    const days =
      (Date.now() - new Date(dateStr).getTime()) / (1000 * 60 * 60 * 24);
    if (days < 1) return 200;
    if (days < 7) return 150;
    if (days < 30) return 100;
    if (days < 90) return 70;
    return 50;
  }
}

module.exports = ChangelogModule;
