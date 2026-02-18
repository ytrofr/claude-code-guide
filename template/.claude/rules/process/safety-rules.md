# Process Safety Rules - WSL & VS Code Protection

**Impact**: Prevents 3-5 system crashes per week, saves 15-30 min recovery each

---

## CRITICAL RULE

**NEVER kill all processes** - it crashes WSL, VS Code, and Claude Code sessions!

---

## Forbidden Commands

| Command            | Why Forbidden                 |
| ------------------ | ----------------------------- |
| `killall node`     | Kills WSL/VS Code/Claude      |
| `pkill -f node`    | Kills ALL node processes      |
| `pkill node`       | Crashes dev environment       |
| `kill -9 -1`       | Kills all user processes      |
| `killall -9 <any>` | Forceful kill of all matching |

---

## Safe Alternatives

| Command                                 | Usage                       |
| --------------------------------------- | --------------------------- |
| `kill <PID>`                            | Kill specific process by ID |
| `pkill -f 'index.js'`                   | Kill specific script only   |
| `pkill -f 'npm start'`                  | Kill specific npm command   |
| `ps aux \| grep node` then `kill <PID>` | Check then kill             |

---

## Why This Matters

- WSL processes run as node -> kills WSL subsystem
- VS Code extensions run as node -> kills editor
- Claude Code runs in VS Code -> kills active session
- Generic kills = **total system crash**

---

## Docker Safety

| Command                          | Why Dangerous                                |
| -------------------------------- | -------------------------------------------- |
| `sudo service docker stop`       | Stops ALL containers                         |
| `docker system prune -a`         | Removes ALL unused images/containers/volumes |
| `docker volume rm <volume_name>` | Destroys database data!                      |

**Safe Docker Commands**:

| Command                           | Usage                           |
| --------------------------------- | ------------------------------- |
| `docker restart <container_name>` | Restart specific container only |
| `docker stop <container_name>`    | Stop specific container only    |
| `docker container prune -f`       | Remove only stopped containers  |
| `docker image prune -f`           | Remove only dangling images     |

---

## Enforcement

1. ALWAYS get specific PID before killing
2. ALWAYS use targeted kill commands
3. NEVER use blanket kill commands
4. NEVER stop Docker service without saving work first
5. NEVER remove Docker volumes without backup
6. When in doubt, ask user for confirmation
