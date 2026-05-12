DROP PROCEDURE IF EXISTS ranking_get_elo;

DELIMITER $$

CREATE PROCEDURE `ranking_get_elo`(IN _id_param VARCHAR(32), IN _tourney_id_param VARCHAR(32), IN _start_param INT(4), IN _count_param INT(4))
BEGIN

SELECT x.display_name, x.account_id, x.rank, x.`value`, x.battle_wins, x.battle_losses

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
					t1.battle_wins `battle_wins`,
					t1.battle_losses `battle_losses`,
					t2.display_name 
				FROM 
					ranking t1 
				JOIN
					auth_account as t2 
						ON t1.account_id = t2.account_id 
				WHERE
					tourney_id = _tourney_id_param
				ORDER BY `value` desc, battle_wins desc, battle_losses asc
			) z
		) x 

WHERE x.account_id LIKE _id_param
LIMIT _start_param, _count_param; 

END$$

DELIMITER ;