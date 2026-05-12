ALTER TABLE `iap_steam` ADD COLUMN `sandbox` TINYINT NOT NULL DEFAULT 1  AFTER `finalize_fail` ;

update iap_steam SET client_approved=1, finalize_ok=1 WHERE finalize_fail = 0 AND finalize_ok = 0 AND client_approved = 0 AND init_fail = 0 AND init_ok = 1;