-- Index composite sur datenaiss et lieunaiss:
CREATE INDEX IF NOT EXISTS idx_datenaiss_lieunaiss ON personne_insee(datenaiss, lieunaiss);
-- Index composite sur datedeces et lieudeces:
CREATE INDEX IF NOT EXISTS idx_datedeces_lieudeces ON personne_insee(datedeces, lieudeces);
-- Index sur commnaiss:
CREATE INDEX IF NOT EXISTS idx_commnaiss ON personne_insee(commnaiss);
-- Index sur paysnaiss:
CREATE INDEX IF NOT EXISTS idx_paysnaiss ON personne_insee(paysnaiss);
