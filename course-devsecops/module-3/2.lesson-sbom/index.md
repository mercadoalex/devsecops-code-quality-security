---
kind: lesson

title: Software Bill of Materials (SBOM)
description: |
  What an SBOM is, why regulators and customers now ask for one, how to generate
  CycloneDX and SPDX SBOMs with Trivy, and how to scan an existing SBOM for new
  vulnerabilities without rebuilding the image.

name: software-bill-of-materials
slug: software-bill-of-materials

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- containers

tagz:
- sbom
- trivy
- supply-chain
- cyclonedx

playground:
  name: devsecops-base-0d12f62a

challenges:
  sbom-generate-63de728a: {}

tasks:
  verify_sbom_generated:
    machine: dev-machine
    user: laborant
    run: |
      FILE=/home/laborant/sbom.cdx.json
      if [ ! -f "${FILE}" ]; then
        echo "sbom.cdx.json not found"
        exit 1
      fi
      if ! grep -qi "bomFormat\|CycloneDX\|components" "${FILE}"; then
        echo "sbom.cdx.json does not look like a CycloneDX SBOM"
        exit 1
      fi
      echo "SBOM present"
    hintcheck: |
      echo "Generate it:  trivy image --format cyclonedx -o /home/laborant/sbom.cdx.json python:3.12-slim"

  verify_sbom_scanned:
    machine: dev-machine
    user: laborant
    needs:
      - verify_sbom_generated
    run: |
      FILE=/home/laborant/sbom-scan.txt
      if [ ! -f "${FILE}" ]; then
        echo "sbom-scan.txt not found"
        exit 1
      fi
      echo "SBOM scan output present"
    hintcheck: |
      echo "Scan the SBOM:  trivy sbom /home/laborant/sbom.cdx.json > /home/laborant/sbom-scan.txt"

  verify_component_count:
    machine: dev-machine
    user: laborant
    needs:
      - verify_sbom_generated
    run: |
      FILE=/home/laborant/component-count.txt
      if [ ! -f "${FILE}" ]; then
        echo "component-count.txt not found"
        exit 1
      fi
      if ! grep -qE "[0-9]+" "${FILE}"; then
        echo "component-count.txt should contain the number of components"
        exit 1
      fi
      echo "component count recorded"
    hintcheck: |
      echo "Count components from the SBOM and write the number to component-count.txt."

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_sbom_scanned
      - verify_component_count
    run: |
      echo "Lesson complete — well done!"
---
