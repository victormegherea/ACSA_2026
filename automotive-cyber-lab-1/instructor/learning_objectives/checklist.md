# Learning Objectives Checklist

Use this checklist to observe team progress during the lab. This is **not for grading** — it's a guide to help you identify which teams might need support and to ensure key learning moments happen.

---

## 🟢 Track A — Easy (Analyst)

### Core Learning Objectives
- [ ] Team can explain what a CAN frame looks like (ID, DLC, data)
- [ ] Team identified at least 2 signal IDs by observing traffic
- [ ] Team understands the relationship between raw bytes and physical values (scaling)
- [ ] Team successfully sent a crafted CAN frame with `cansend`
- [ ] Team can explain why CAN injection is possible (no authentication)

### Deeper Understanding (bonus — not required)
- [ ] Team found the RPM signal in addition to speed/doors
- [ ] Team discussed what a replay attack is
- [ ] Team proposed at least one defense mechanism
- [ ] Team experimented with the Python CAN monitor

### Discussion Prompts for This Team
- "How did you figure out which ID was speed?"
- "What happened when you injected a frame — did it stick?"
- "If you were an attacker, what would you do with this?"

---

## 🟡 Track B — Medium (Attacker–Defender)

### Core Learning Objectives
- [ ] Team identified all 4 attack types in the attack trace
- [ ] Team executed a replay attack and observed its effect
- [ ] Team understands why replay attacks work on CAN
- [ ] Team ran the IDS against attack traffic and saw alerts
- [ ] Team tested the IDS against normal traffic (false positive awareness)

### Deeper Understanding (bonus — not required)
- [ ] Team tuned IDS thresholds and discussed the tradeoff
- [ ] Team added or modified a detection heuristic
- [ ] Team proposed specific defenses for each attack type
- [ ] Team discussed real-world IDS challenges (latency, resources)

### Discussion Prompts for This Team
- "Which attack was hardest to detect? Why?"
- "What happens if you make your thresholds too tight?"
- "How would a real car manufacturer implement an IDS?"

---

## 🔴 Track C — Hard (UDS/ECU Security)

### Core Learning Objectives
- [ ] Team understands UDS session management (0x10)
- [ ] Team successfully requested a seed and computed the key
- [ ] Team can explain why the weak algorithm is vulnerable
- [ ] Team accessed protected data after unlocking the ECU
- [ ] Team identified at least 3 vulnerabilities in the ECU security

### Deeper Understanding (bonus — not required)
- [ ] Team compared weak vs strong seed-key algorithms
- [ ] Team drew a UDS sequence diagram (even rough)
- [ ] Team proposed multi-layered defense (not just "use better crypto")
- [ ] Team discussed real-world standards (ISO 14229, SecOC)

### Discussion Prompts for This Team
- "How long would it take to brute-force the weak algorithm?"
- "What's the difference between detection and prevention?"
- "If you had to secure this ECU for production, where would you start?"

---

## 🎯 Overall Lab — Did the Group Learn?

After the sharing session, check if these themes emerged:

- [ ] **CAN is inherently insecure** — no auth, broadcast, no encryption
- [ ] **Attacks are easy** — replay, injection, spoofing require minimal knowledge
- [ ] **Detection is possible but imperfect** — IDS can catch anomalies but has tradeoffs
- [ ] **Defense requires layers** — MACs, gateways, IDS, secure boot, monitoring
- [ ] **This is a real industry challenge** — not just academic; cars are being secured today
- [ ] **Ethical responsibility** — knowing how to attack means knowing how to defend

---

## 📝 Notes for Next Time

Use this space to jot down what worked and what to improve:

**What went well:**


**What to change:**


**Student feedback / questions to address next time:**


