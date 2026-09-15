# Firmware Reverse Engineering — Guided Investigation

Use this guide only after making an independent attempt with `hints.md`. It explains a repeatable analysis workflow but does not identify the final credential files or values.

## 1. Preserve the Original

Work from the provided image and keep notes in `workspace/`.

```bash
cd /path/to/student
mkdir -p workspace
sha256sum Firmware.bin | tee workspace/firmware.sha256
file Firmware.bin | tee workspace/file-type.txt
```

Record the size, file type, and hash. This gives your findings a clear evidence trail.

## 2. Identify Embedded Data

Run a signature scan before extracting anything:

```bash
binwalk Firmware.bin | tee workspace/binwalk-scan.txt
strings -n 8 Firmware.bin | head -100 | tee workspace/strings-sample.txt
xxd -l 256 Firmware.bin | tee workspace/header-hex.txt
```

In the scan output, look for file-system signatures, compression formats, offsets, and architecture clues. An offset marks where embedded content begins; it is a lead, not automatically the answer.

## 3. Extract the Image

Use Binwalk extraction from the directory containing `Firmware.bin`:

```bash
binwalk -e Firmware.bin
```

If an embedded archive or file system remains unexpanded, use recursive extraction:

```bash
binwalk -e -M Firmware.bin
```

Inspect the extraction results rather than assuming one particular directory name:

```bash
find . -maxdepth 2 -type d | sort
find . -maxdepth 2 -type f | sort | head -100
```

Choose the extracted directory that looks like a Linux root file system. Typical indicators are directories such as `etc`, `bin`, `sbin`, `usr`, `var`, or `www`.

## 4. Inventory the Extracted File System

Set `ROOT` to the root of the extracted file system you found:

```bash
ROOT="_Firmware.bin.extracted/squashfs-root"
test -d "$ROOT" && find "$ROOT" -maxdepth 2 -type d | sort | tee workspace/directory-tree.txt
find "$ROOT" -type f -printf '%s %p\n' | sort -n | tee workspace/file-inventory.txt
```

If that path does not exist, replace it with the directory discovered in the previous step. Do not guess: use `find` output to select it.

Review the inventory for:

- service and boot configuration
- scripts run during startup
- device-specific configuration
- account, key, certificate, and network settings
- unusually small files whose names imply configuration or provisioning

## 5. Triage Candidate Files

Start broad, then narrow based on what the image contains:

```bash
find "$ROOT" -type f \( -name '*.conf' -o -name '*.cfg' -o -name '*.ini' -o -name '*.sh' \) -print | sort
grep -RInE 'pass(word)?|user(name)?|auth|login|token|secret|key' "$ROOT" 2>/dev/null | tee workspace/keyword-hits.txt
```

Search results are leads. Inspect each candidate in context:

```bash
sed -n '1,220p' "path/to/candidate-file"
stat "path/to/candidate-file"
```

Ask these questions for each result:

1. Is this value active configuration, an example, or a comment?
2. Which process or service consumes it?
3. Does a related script reference another file or value?
4. Is it a username, secret, cryptographic key, or merely a label?

## 6. Trace Service Configuration

Identify service-launching scripts and configuration references without assuming a service name:

```bash
find "$ROOT" -type f -path '*/init*/*' -o -path '*/scripts/*' | sort
grep -RInE 'start|daemon|listen|port|auth|login' "$ROOT" 2>/dev/null | tee workspace/service-hits.txt
```

When you find a service script, read it top to bottom. Record command-line arguments, configuration paths, environment variables, and any referenced helper files. Repeat this process for each referenced file until you can explain how the service obtains its authentication data.

## 7. Record a Defensible Finding

For each sensitive finding, write the following in `workspace/findings.md`:

```markdown
## Finding: <short title>

- Evidence path: `<path inside extracted image>`
- Evidence: `<relevant value or redacted excerpt>`
- Why it matters: <how the value could affect device access or trust>
- Relationship: <script/service/configuration that uses it>
- Mitigation: <specific secure-storage, provisioning, or access-control improvement>
```

Your goal is not simply to find a suspicious string. It is to demonstrate where it came from, what uses it, and why it represents a security risk.

## Troubleshooting

| Problem | Next check |
|---|---|
| Binwalk finds signatures but extraction is incomplete | Try `binwalk -e -M Firmware.bin`, then inspect the extracted files with `file`. |
| No root file system is obvious | Search for directories containing `etc`, `bin`, or `sbin`; inspect archive and file-system signatures reported by Binwalk. |
| Keyword search produces too much output | Limit the search to configuration and startup-script directories, then inspect results in context. |
| A candidate value looks plausible but unproven | Trace which process reads the file and distinguish active configuration from comments or examples. |