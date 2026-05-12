ALTER TABLE `ranking` ADD COLUMN `ranking_group` INT(4) NOT NULL DEFAULT 0  AFTER `friend_battles`
, ADD INDEX `ranking_group` (`ranking_group` ASC) ;

ALTER TABLE `battle_party` ADD COLUMN `ranking_group` INT(4) NOT NULL DEFAULT 0  AFTER `elo_result` ;

DROP PROCEDURE IF EXISTS ranking_get_best_win_streak;
DROP PROCEDURE IF EXISTS ranking_get_elo;
DROP PROCEDURE IF EXISTS ranking_get_losses;
DROP PROCEDURE IF EXISTS ranking_get_total;
DROP PROCEDURE IF EXISTS ranking_get_win_streak;
DROP PROCEDURE IF EXISTS ranking_get_winloss;
DROP PROCEDURE IF EXISTS ranking_get_wins;

DELIMITER $$

CREATE PROCEDURE `ranking_get_elo`(IN _id_param VARCHAR(32), IN _group_param VARCHAR(32), IN _start_param INT(4), IN _count_param INT(4))
BEGIN

SELECT x.display_name, x.account_id, x.rank, x.`value`

	FROM (
		SELECT 
			*, 
			@rank:=@rank+1 rank
			FROM 
				(SELECT @rank:=0) r, 
			(
				SELECT 
					t1.account_id,
					t1.battle_elo `value`,
					t2.display_name 
				FROM 
					ranking t1 
				JOIN
					auth_account as t2 
						ON t1.account_id = t2.account_id 
				WHERE
					ranking_group = _group_param
				ORDER BY `value` desc
			) z
		) x 

WHERE x.account_id LIKE _id_param
LIMIT _start_param, _count_param; 

END$$

CREATE PROCEDURE `ranking_get_losses`(IN _id_param VARCHAR(32), IN _group_param VARCHAR(32), IN _start_param INT(4), IN _count_param INT(4))
BEGIN

SELECT x.display_name, x.account_id, x.rank, x.`value`

	FROM (
		SELECT 
			*, 
			@rank:=@rank+1 rank
			FROM 
				(SELECT @rank:=0) r, 
			(
				SELECT 
					t1.account_id,
					t1.battle_losses `value`,
					t2.display_name 
				FROM 
					ranking t1 
				JOIN
					auth_account as t2 
						ON t1.account_id = t2.account_id 
				WHERE
					ranking_group = _group_param
				ORDER BY `value` desc
			) z
		) x 

WHERE x.account_id LIKE _id_param
LIMIT _start_param, _count_param; 

END$$

CREATE PROCEDURE `ranking_get_total`(IN _id_param VARCHAR(32), IN _group_param VARCHAR(32), IN _start_param INT(4), IN _count_param INT(4))
BEGIN
 
SELECT x.display_name, x.account_id, x.rank, x.`value`

	FROM (
		SELECT 
			*, 
			@rank:=@rank+1 rank
			FROM 
				(SELECT @rank:=0) r, 
			(
				SELECT 
					t1.account_id,
					(t1.battle_losses + t1.battle_wins) `value`,
					t2.display_name 
				FROM 
					ranking t1 
				JOIN
					auth_account as t2 
						ON t1.account_id = t2.account_id 
				WHERE
					ranking_group = _group_param
				ORDER BY `value` desc
			) z
		) x 

WHERE x.account_id LIKE _id_param
LIMIT _start_param, _count_param; 

END$$

CREATE PROCEDURE `ranking_get_win_streak`(IN _id_param VARCHAR(32), IN _group_param VARCHAR(32), IN _start_param INT(4), IN _count_param INT(4))
BEGIN

SELECT x.display_name, x.account_id, x.rank, x.`value`

	FROM (
		SELECT 
			*, 
			@rank:=@rank+1 rank
			FROM 
				(SELECT @rank:=0) r, 
			(
				SELECT 
					t1.account_id,
					t1.win_streak `value`,
					t2.display_name 
				FROM 
					ranking t1 
				JOIN
					auth_account as t2 
						ON t1.account_id = t2.account_id 
				WHERE
					ranking_group = _group_param
				ORDER BY `value` desc
			) z
		) x 

WHERE x.account_id LIKE _id_param
LIMIT _start_param, _count_param; 

END$$

CREATE PROCEDURE `ranking_get_winloss`(IN _id_param VARCHAR(32), IN _group_param VARCHAR(32), IN _start_param INT(4), IN _count_param INT(4))
BEGIN
 
SELECT x.display_name, x.account_id, x.rank, x.`value`

	FROM (
		SELECT 
			*, 
			@rank:=@rank+1 rank
			FROM 
				(SELECT @rank:=0) r, 
			(
				SELECT 
					t1.account_id,
					ROUND(IF(t1.battle_losses > 0,(t1.battle_wins / t1.battle_losses),1), 2) `value`,
					t2.display_name 
				FROM 
					ranking t1 
				JOIN
					auth_account as t2 
						ON t1.account_id = t2.account_id 
				WHERE
					ranking_group = _group_param
				ORDER BY CAST(`value` as DECIMAL(5,2)) desc
			) z
		) x 

WHERE x.account_id LIKE _id_param
LIMIT _start_param, _count_param; 

END$$

CREATE PROCEDURE `ranking_get_wins`(IN _id_param VARCHAR(32), IN _group_param VARCHAR(32), IN _start_param INT(4), IN _count_param INT(4))
BEGIN

SELECT x.display_name, x.account_id, x.rank, x.`value`

	FROM (
		SELECT 
			*, 
			@rank:=@rank+1 rank
			FROM 
				(SELECT @rank:=0) r, 
			(
				SELECT 
					t1.account_id,
					t1.battle_wins `value`,
					t2.display_name 
				FROM 
					ranking t1 
				JOIN
					auth_account as t2 
						ON t1.account_id = t2.account_id 
				WHERE
					ranking_group = _group_param
				ORDER BY `value` desc
			) z
		) x 

WHERE x.account_id LIKE _id_param
LIMIT _start_param, _count_param; 

END$$

CREATE PROCEDURE `ranking_get_best_win_streak`(IN _id_param VARCHAR(32), IN _group_param VARCHAR(32), IN _start_param INT(4), IN _count_param INT(4))
BEGIN

SELECT x.display_name, x.account_id, x.rank, x.`value`

	FROM (
		SELECT 
			*, 
			@rank:=@rank+1 rank
			FROM 
				(SELECT @rank:=0) r, 
			(
				SELECT 
					t1.account_id,
					t1.best_win_streak `value`,
					t2.display_name 
				FROM 
					ranking t1 
				JOIN
					auth_account as t2 
						ON t1.account_id = t2.account_id 
				WHERE
					ranking_group = _group_param
				ORDER BY CAST(`value` as SIGNED) desc
			) z
		) x 

WHERE x.account_id LIKE _id_param
LIMIT _start_param, _count_param; 

END$$

DELIMITER ;