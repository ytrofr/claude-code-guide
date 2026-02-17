# Universal Versioning Standards

**Scope**: ALL projects
**Purpose**: Consistent versioning, timestamping, and supersession tracking

---

## Version Format

`v{MAJOR}.{MINOR}.{PATCH}`

| Type  | When                                        |
| ----- | ------------------------------------------- |
| MAJOR | Breaking changes, architecture shifts       |
| MINOR | Feature additions, significant enhancements |
| PATCH | Bug fixes, clarifications, minor updates    |

---

## Timestamp Format

**Standard**: ISO 8601 (`YYYY-MM-DD`)

- Documentation dates, achievements, deployments
- Full timestamps (`YYYY-MM-DDTHH:MM:SS UTC`) for events

---

## Supersession Tracking

| Element         | Format                                                       |
| --------------- | ------------------------------------------------------------ |
| Header          | `**Superseded By**: {file} (Date: YYYY-MM-DD)`               |
| Archive Trigger | 30-90 days after patterns extracted + zero active references |
| Verification    | `grep -r 'filename' returns 0 results`                       |

---

## Changelog Maintenance

**Format**: `## [VERSION] - YYYY-MM-DD`

**Sections**: Added, Changed, Deprecated, Removed, Fixed, Security
