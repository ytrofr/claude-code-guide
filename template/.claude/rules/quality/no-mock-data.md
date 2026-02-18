# ABSOLUTE: No Mock Data - System-Wide Rule

**Scope**: ALL code in ALL projects - Backend, Frontend, APIs, Services, Tests
**Authority**: SUPREME - Overrides all other considerations
**Enforcement**: MANDATORY - No exceptions

---

## Core Rule

**NEVER use mock, fake, stub, placeholder, hardcoded, or synthetic data anywhere in the system.**

ALL data MUST come from:

- Real APIs
- Real databases
- Real services
- Real user input

---

## Forbidden Patterns

```python
# FORBIDDEN - Never write these patterns:
return {"status": "in_progress", "progress": 50}  # Hardcoded response
return {"files": [{"name": "test.txt"}]}           # Fake data
MOCK_DATA = {...}                                   # Mock constants
if USE_MOCK: return mock_response                   # Mock mode flags
```

```javascript
// FORBIDDEN:
const mockFiles = [{ id: "1", name: "test" }]; // Mock data
if (import.meta.env.DEV) return fakeData; // Dev-only mocks
// TODO: Replace with real API                  // Placeholder comments
```

---

## Required Patterns

### When Data is Unavailable

```python
# CORRECT - Return honest error, not fake data:
if not data:
    raise HTTPException(status_code=404, detail="No data found")
    # OR
    return {"status": "empty", "message": "No data available. Please sync first."}
```

### When Service is Not Connected

```python
# CORRECT - Require real connection:
if not credentials:
    raise HTTPException(status_code=401, detail="Not connected. Please authorize first.")
```

### When Feature is Not Implemented

```python
# CORRECT - Be honest:
raise HTTPException(status_code=501, detail="Feature not yet implemented")
# NOT: return fake_placeholder_data
```

---

## Applies To

| Layer         | Rule                                          |
| ------------- | --------------------------------------------- |
| API Endpoints | Must return real data from real sources       |
| Services      | Must call real external APIs                  |
| Database      | Must query real database                      |
| Frontend      | Must fetch from real API                      |
| Tests         | Use real test data or clearly marked fixtures |
| Development   | Same as production - real data only           |

---

## Chain-of-Verification (CoVe)

Before ANY data processing code, complete this verification chain:

1. "According to [specific API endpoint], this data exists in [exact field]"
2. "I have verified the API response structure contains [field]"
3. "Real extraction method: `await extractFrom[API]([params])`"
4. "Failure handling: `'not available'` (never synthetic)"

---

## Why This Matters

1. **User Trust**: Users expect real data, not fabrications
2. **Bug Detection**: Mocks hide real integration issues
3. **Production Parity**: Dev should match prod behavior
4. **Data Integrity**: Fake data pollutes understanding
5. **Security**: Mock modes can leak to production

---

## Violation Response

If you find yourself wanting to write mock data:

1. STOP
2. Implement the real integration
3. Or return an honest error/empty state
4. Document what is not yet implemented

**Mock data is NEVER acceptable, even temporarily.**
