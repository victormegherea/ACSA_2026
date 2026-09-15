# Hints — Firmware Reverse Engineering

Try the investigation before opening `stepbystepguide.md`. Reveal one hint at a time, record what it changes in your understanding, then return to the image.

---

## Level 1 — Establish Facts

<details>
<summary>Reveal</summary>

Do not start by searching for a password. First determine the file type, embedded formats, and whether a file system is present.

</details>

---

## Level 2 — Get a Navigable View

<details>
<summary>Reveal</summary>

Use an extraction tool when the scan identifies an embedded file system. Your goal is a directory tree you can inspect, not a successful-looking command alone.

</details>

---

## Level 3 — Build a Search Strategy

<details>
<summary>Reveal</summary>

Prioritize files that influence boot, services, authentication, or device configuration. Compare filenames, permissions, and contents before deciding a value is sensitive.

</details>

---

## Level 4 — Follow Relationships

<details>
<summary>Reveal</summary>

When a script launches a service, trace the files and values it reads. A username and its corresponding secret may not be stored together.

</details>

---

## Level 5 — Validate the Finding

<details>
<summary>Reveal</summary>

Document the path, the exact evidence, and why the value is a credential or secret. Then identify one realistic mitigation for the exposure.

</details>

---

*For command-by-command guidance after attempting the investigation, open `stepbystepguide.md`.*
