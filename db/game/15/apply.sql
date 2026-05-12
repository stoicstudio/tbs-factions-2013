
DROP PROCEDURE IF EXISTS `ranking_get_total`;

delimiter $$

CREATE PROCEDURE `ranking_get_total`(IN _id_param VARCHAR(32), IN _start_param INT(4), IN _count_param INT(4))
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
				ORDER BY `value` desc
			) z
		) x 

WHERE x.account_id LIKE _id_param
LIMIT _start_param, _count_param; 

END$$

DELIMITER ;


