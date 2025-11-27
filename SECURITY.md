# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

We take security seriously. If you discover a security vulnerability in Munition,
please report it responsibly.

### Reporting Channel

**Email**: security@hyperpolymath.dev (or open a confidential issue)

**Do NOT**:
- Open a public GitHub/GitLab issue for security vulnerabilities
- Disclose the vulnerability publicly before we've had a chance to address it

### Response SLA

| Action | Timeline |
|--------|----------|
| Initial acknowledgement | Within 24 hours |
| Initial assessment | Within 72 hours |
| Status update | Weekly until resolved |
| Fix development | Based on severity |
| Public disclosure | After fix is released |

### Severity Classification

| Severity | Description | Target Resolution |
|----------|-------------|-------------------|
| Critical | Remote code execution, sandbox escape | 24-48 hours |
| High | Privilege escalation, data exposure | 7 days |
| Medium | Denial of service, information disclosure | 30 days |
| Low | Minor issues, hardening improvements | Next release |

### What to Include

When reporting a vulnerability, please include:

1. **Description**: Clear explanation of the vulnerability
2. **Impact**: What an attacker could achieve
3. **Reproduction**: Step-by-step instructions to reproduce
4. **Environment**: OS, Elixir/Erlang versions, Wasmex version
5. **Proof of Concept**: If available (please don't test on production systems)

### Safe Harbor

We consider security research conducted in good faith to be authorized.
We will not pursue legal action against researchers who:

- Make a good faith effort to avoid privacy violations and data destruction
- Report vulnerabilities promptly
- Give us reasonable time to address the issue before public disclosure
- Do not exploit the vulnerability beyond what's necessary for proof

### Security Design

Munition is designed with security as a core principle:

1. **Capability Attenuation**: Untrusted code runs with minimal privileges
2. **Memory Isolation**: Each execution gets fresh, isolated memory
3. **Fuel Bounding**: Guaranteed termination prevents resource exhaustion
4. **Forensic Capture**: All failures are captured for analysis

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed security architecture.

### Known Security Considerations

1. **Host Functions**: Custom host functions must be implemented securely
2. **Timing Attacks**: Side-channel attacks via timing are theoretically possible
3. **Resource Limits**: Memory allocation before instantiation is not bounded
4. **WASM Vulnerabilities**: We depend on Wasmtime's security; monitor their advisories

### Dependencies

We monitor security advisories for:

- Wasmex / Wasmtime
- Erlang/OTP
- Elixir

Run `mix deps.audit` to check for known vulnerabilities.

## Security Updates

Security updates are announced via:

1. GitLab releases (with security label)
2. CHANGELOG.md entries
3. Direct notification to affected users (if contact available)

## Acknowledgments

We maintain a list of security researchers who have responsibly disclosed
vulnerabilities in [SECURITY-ACKNOWLEDGMENTS.md](SECURITY-ACKNOWLEDGMENTS.md)
(created after first disclosure).
