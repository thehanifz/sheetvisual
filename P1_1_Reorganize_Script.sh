#!/bin/bash

# P1.1 Repository Reorganization Script
# This script reorganizes existing files into proper Phase 1 structure
# and renames CODEOWNERS_ to CODEOWNERS

set -e  # Exit on error

echo "=== P1.1 Repository Reorganization ==="
echo "Current directory: $(pwd)"
echo ""

# Step 1: Create directory structure
echo "Step 1: Creating directory structure..."
mkdir -p backend
mkdir -p worker
mkdir -p frontend
mkdir -p shared
mkdir -p infra
mkdir -p docs/architecture
mkdir -p docs/implementation
mkdir -p .github

echo "✓ Directories created"
echo ""

# Step 2: Move architecture documents to docs/architecture/
echo "Step 2: Moving architecture documents to docs/architecture/..."
mv -f SheetViz_ArchSpec_Bagian1_ERD_ControlledRevision_v3_1.md docs/architecture/ 2>/dev/null || true
mv -f ArchitectureSpec_SheetViz_Bagian2_SyncArchitecture_v2.md docs/architecture/ 2>/dev/null || true
mv -f SheetViz_ArchSpec_Bagian3_Meta_Final.md docs/architecture/ 2>/dev/null || true
mv -f SheetViz_ArchSpec_Bagian4_APIContract_ControlledRevision_v3_1.md docs/architecture/ 2>/dev/null || true
mv -f SheetViz_ArchSpec_Bagian5_Entitlement_v2.md docs/architecture/ 2>/dev/null || true
mv -f SheetViz_ArchSpec_Bagian6_SecurityModel_v1_1.md docs/architecture/ 2>/dev/null || true
echo "✓ Architecture documents moved"
echo ""

# Step 3: Move implementation documents to docs/implementation/
echo "Step 3: Moving implementation documents to docs/implementation/..."
mv -f SheetViz_Implementation_MasterPlan_Traceability_v1_FinalReview.md docs/implementation/ 2>/dev/null || true
mv -f SheetViz_Phase1_Authorization_v1.md docs/implementation/ 2>/dev/null || true
mv -f SheetViz_Phase1_ExecutionPlan_v1_1.md docs/implementation/ 2>/dev/null || true
mv -f P1_1_Execution_Checklist.md docs/implementation/ 2>/dev/null || true
mv -f P1_1_Setup_Instructions.md docs/implementation/ 2>/dev/null || true
echo "✓ Implementation documents moved"
echo ""

# Step 4: Move PRD to docs/implementation/
echo "Step 4: Moving PRD to docs/implementation/..."
mv -f "PRD_SheetViz_Dashboard (4).md" docs/implementation/PRD_SheetViz_Dashboard.md 2>/dev/null || true
echo "✓ PRD moved"
echo ""

# Step 5: Rename CODEOWNERS_ to CODEOWNERS and move to root
echo "Step 5: Renaming CODEOWNERS_ to CODEOWNERS..."
mv -f CODEOWNERS_ CODEOWNERS
echo "✓ CODEOWNERS renamed"
echo ""

# Step 6: Move templates to .github/
echo "Step 6: Moving templates to .github/..."
mv -f PULL_REQUEST_TEMPLATE.md .github/ 2>/dev/null || true
mv -f ISSUE_TEMPLATE.md .github/ 2>/dev/null || true
echo "✓ Templates moved to .github/"
echo ""

# Step 7: Create .gitkeep files in empty directories
echo "Step 7: Creating .gitkeep files..."
touch backend/.gitkeep 2>/dev/null || true
touch worker/.gitkeep 2>/dev/null || true
touch frontend/.gitkeep 2>/dev/null || true
touch shared/.gitkeep 2>/dev/null || true
touch infra/.gitkeep 2>/dev/null || true
touch docs/architecture/.gitkeep 2>/dev/null || true
touch docs/implementation/.gitkeep 2>/dev/null || true
echo "✓ .gitkeep files created"
echo ""

# Step 8: Show final structure
echo "Step 8: Final repository structure:"
echo ""
tree -L 2 2>/dev/null || find . -maxdepth 2 -type f -o -type d | head -30
echo ""

# Step 9: Git status
echo "Step 9: Git status:"
git status --short
echo ""

echo "=== Reorganization Complete ==="
echo ""
echo "Next steps:"
echo "1. Review git status above"
echo "2. git add -A"
echo "3. git commit -m \"P1.1: Repository foundation (REPO-STRUCT-01) — Proper structure, CODEOWNERS, PR/issue templates\""
echo "4. git push"
echo ""
echo "Then configure branch protection in GitHub Settings → Branches"