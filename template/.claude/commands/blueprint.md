# /blueprint - Feature Documentation Generator

**Purpose**: Generate comprehensive feature documentation for complex features
**Usage**: `/blueprint [feature-name] [type] [scope]`

## Command Syntax

```bash
/blueprint [feature-name] [type] [scope]
```

### Parameters:

- **feature-name**: Feature or component name (e.g., `auth`, `payment`, `dashboard`)
- **type**: Template type (`feature`, `api`, `component`)
- **scope**: Completeness level (`full`, `basic`)

## Blueprint Template (Full)

Generate a comprehensive blueprint covering:

1. **Overview**: Mission, requirements
2. **API Endpoints**: Complete endpoint documentation
3. **Frontend Implementation**: HTML/JS/CSS structure
4. **Database Schema**: Table structure and operations
5. **Architecture**: File structure and dependencies
6. **Testing**: Test commands and expected results
7. **Deployment**: Deployment procedures
8. **Recreation Instructions**: Step-by-step rebuilding guide

### Output Location:

- **File**: `docs/blueprints/[feature-name]-blueprint.md`

## Quick Example

```bash
/blueprint auth feature full
```

**Output**: Complete blueprint with all auth endpoints, database tables, frontend pages, and test commands.

---

**Command Authority**: Feature documentation generation
**Usage**: Generate complete working state preservation for any feature or component
