# Release checklist — <component> v<X.Y.Z>

Used by the `release` skill. Claude prepares; a human pushes tags and approves production (CORE-06).

## Before the release PR
- [ ] Version computed from Conventional Commits since `<component>/v<previous>` (GIT-06); reasoning recorded
- [ ] CHANGELOG updated; breaking changes called out with migration notes
- [ ] DLC release only: `docs/ai-dlc/VERSION` bumped and each changelog entry has an upgrade action ([upgrading.md](../docs/ai-dlc/upgrading.md))
- [ ] Production readiness review done if first release or major version

## Release commit
- [ ] Required checks green on the commit to tag (CICD-06)
- [ ] No open Critical/High findings (CR-03); no High/Critical vulnerable dependency without a dated exception (SEC-15)
- [ ] Migrations in this release are backward compatible (DB-09)
- [ ] Terraform plan for staging/prod reviewed; no unexpected destroys; cost note present (AWS-13)

## Tag and deploy (human)
- [ ] Tag created and pushed by a human: `git tag -a <component>/vX.Y.Z -m "<component> vX.Y.Z" <sha>`, `git push origin <component>/vX.Y.Z`
- [ ] Staging deployment green, smoke tests passed (CICD-11)
- [ ] Production approval given in the `prod` environment by a reviewer (CICD-08)
- [ ] Production smoke tests passed; dashboards normal for 30 minutes

## After
- [ ] Release recorded in `docs/ai-dlc/audit.md`; `state.md` updated (CORE-02)
- [ ] Catalog status updated if this was the first production release
