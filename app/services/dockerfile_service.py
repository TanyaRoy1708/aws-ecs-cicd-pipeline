"""
Dockerfile linter service.

Checks the following rules:
  DF001: FROM uses 'latest' tag (unpinned base image)
  DF002: No USER instruction (container runs as root)
  DF003: apt-get install without -y (interactive prompts)
  DF004: ADD used instead of COPY
  DF005: No HEALTHCHECK instruction
  DF006: Multiple RUN apt-get install calls
  DF007: pip install without --no-cache-dir
  DF008: EXPOSE not present
  DF009: apt-get install without prior apt-get update
"""

import re
from typing import Any


def lint_dockerfile(dockerfile_content: str) -> dict[str, Any]:
    lines = dockerfile_content.split("\n")
    warnings: list[str] = []

    # Preprocess physical lines to form logical lines (handling backslash continuations)
    logical_lines: list[tuple[int, str]] = []
    current_line = ""
    start_line_num = 1

    for i, raw_line in enumerate(lines, start=1):
        stripped = raw_line.strip()
        # Ignore empty lines and comments (unless in the middle of a continuation)
        if not current_line and (not stripped or stripped.startswith("#")):
            continue
            
        if not current_line:
            start_line_num = i

        if stripped.endswith("\\"):
            current_line += " " + stripped[:-1].strip()
        else:
            current_line += " " + stripped
            logical_lines.append((start_line_num, current_line.strip()))
            current_line = ""

    if current_line:
        logical_lines.append((start_line_num, current_line.strip()))

    has_from = False
    has_user = False
    has_healthcheck = False
    has_expose = False
    apt_install_count = 0

    for start_line, line in logical_lines:
        line_lower = line.lower()
        words = line.split(maxsplit=1)
        if not words:
            continue
        instruction = words[0].upper()

        # DF001: FROM uses 'latest' tag or unpinned
        if instruction == "FROM":
            has_from = True
            # Reset stage-specific checks since a new FROM starts a fresh stage
            has_user = False
            has_healthcheck = False
            has_expose = False
            apt_install_count = 0

            # Parse image name
            parts = line.split()
            image = None
            for part in parts[1:]:
                if not part.startswith("--"):
                    image = part
                    break
            if image:
                # Remove alias details e.g., AS builder
                image = image.split()[0]
                if image.lower() != "scratch":
                    if "@" in image:
                        # Digest is pinned
                        pass
                    elif ":" in image:
                        tag = image.split(":")[-1]
                        if tag.lower() == "latest":
                            warnings.append(
                                f"[DF001] Line {start_line}: Avoid 'latest' tag in FROM: pin to a specific "
                                "version for reproducible builds (e.g. python:3.11-slim)."
                            )
                    else:
                        # No tag and no digest defaults to latest
                        warnings.append(
                            f"[DF001] Line {start_line}: Base image does not specify a tag or digest: "
                            "it will default to 'latest'. Pin to a specific version for reproducible builds."
                        )

        # DF004: ADD instead of COPY
        if instruction == "ADD":
            warnings.append(
                f"[DF004] Line {start_line}: Prefer COPY over ADD unless you need automatic "
                "tar-extraction or URL fetching: ADD has implicit side-effects."
            )

        # DF003: apt-get install without -y
        if "apt-get install" in line_lower:
            # Check for -y or --yes
            if not any(opt in line_lower for opt in ["-y", "--yes"]):
                warnings.append(
                    f"[DF003] Line {start_line}: 'apt-get install' should include '-y' (or '--yes') to prevent "
                    "interactive prompts blocking CI builds."
                )

        # DF006: multiple separate apt-get install layers
        if "apt-get install" in line_lower:
            apt_install_count += 1

        # DF009: apt-get install without prior apt-get update in same RUN instruction
        if instruction == "RUN":
            if "apt-get install" in line_lower and "apt-get update" not in line_lower:
                warnings.append(
                    f"[DF009] Line {start_line}: 'apt-get install' used without 'apt-get update' in the same RUN instruction. "
                    "Combine them (e.g., 'RUN apt-get update && apt-get install -y <packages>') to avoid layer caching issues."
                )

        # DF007: pip install without --no-cache-dir
        if re.search(r"\bpip\d*\s+install\b", line_lower):
            if "--no-cache-dir" not in line_lower:
                warnings.append(
                    f"[DF007] Line {start_line}: Add '--no-cache-dir' to pip install to avoid "
                    "storing the pip cache inside the image layer."
                )

        # Track presence of key instructions in the current stage
        if instruction == "USER":
            has_user = True
        if instruction == "HEALTHCHECK":
            has_healthcheck = True
        if instruction == "EXPOSE":
            has_expose = True

    # Only perform final-stage specific checks if at least one FROM was present
    if has_from:
        # DF002: no USER instruction
        if not has_user:
            warnings.append(
                "[DF002] No USER instruction found in the final stage: container will run as root. "
                "Add a non-root user (e.g. RUN adduser --system appuser && USER appuser)."
            )

        # DF005: no HEALTHCHECK
        if not has_healthcheck:
            warnings.append(
                "[DF005] No HEALTHCHECK instruction found in the final stage: Docker and ECS cannot detect "
                "unhealthy containers without one. "
                "Example: HEALTHCHECK CMD curl -f http://localhost:8000/health || exit 1"
            )

        # DF006: multiple apt-get install RUN commands in the final stage
        if apt_install_count > 1:
            warnings.append(
                f"[DF006] Found {apt_install_count} separate 'apt-get install' calls in the final stage: "
                "combine them into a single RUN command to minimise image layers."
            )

        # DF008: no EXPOSE
        if not has_expose:
            warnings.append(
                "[DF008] No EXPOSE instruction found in the final stage: document the port your service listens on "
                "(e.g. EXPOSE 8000). This is informational but important for clarity."
            )

    return {
        "success": True,
        "warnings": warnings,
        "passed": len(warnings) == 0,
        "rule_count": 9,
    }
