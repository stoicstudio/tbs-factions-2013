DROP  PROCEDURE IF EXISTS `leaderboard_update_tourney`;

DELIMITER $$

CREATE PROCEDURE `leaderboard_update_tourney`(IN _tourney_id_param INT(4), IN _leaderboard_type_param INT(4), IN _rank_limit INT(4))
BEGIN

delete from leaderboard where tourney_id=_tourney_id_param AND leaderboard_type=_leaderboard_type_param;

set @rank=0;

CASE  _leaderboard_type_param
WHEN 1 THEN
replace into leaderboard
(
SELECT _tourney_id_param tourney_id, account_id, 1 leaderboard_type, @rank:=@rank+1 rank, NULL, 
	battle_elo `value`
FROM  ranking
WHERE tourney_id = _tourney_id_param
ORDER BY `value` desc, battle_wins desc, battle_losses asc limit _rank_limit
);

WHEN 2 THEN
replace into leaderboard
(
SELECT _tourney_id_param tourney_id, account_id, 2 leaderboard_type, @rank:=@rank+1 rank, NULL, 
	battle_wins `value`
FROM ranking
WHERE tourney_id = _tourney_id_param and battle_wins > 0
ORDER BY `value` desc limit _rank_limit
);

WHEN 3 THEN
replace into leaderboard
(
SELECT _tourney_id_param tourney_id, account_id, 3 leaderboard_type, @rank:=@rank+1 rank, NULL, 
	battle_losses `value`
FROM ranking
WHERE tourney_id = _tourney_id_param
ORDER BY `value` desc limit _rank_limit
);

WHEN 4 THEN
replace into leaderboard
(
SELECT _tourney_id_param tourney_id, account_id, 4 leaderboard_type, @rank:=@rank+1 rank, NULL, 
	win_streak `value`
FROM ranking
WHERE tourney_id = _tourney_id_param
ORDER BY `value` desc limit _rank_limit
);

WHEN 5 THEN
replace into leaderboard
(
SELECT _tourney_id_param tourney_id, account_id, 5 leaderboard_type, @rank:=@rank+1 rank, NULL, 
	best_win_streak `value`
FROM ranking
WHERE tourney_id = _tourney_id_param
ORDER BY `value` desc limit _rank_limit
);

WHEN 6 THEN
replace into leaderboard
(
SELECT _tourney_id_param tourney_id, account_id, 6 leaderboard_type, @rank:=@rank+1 rank, NULL, 
	ROUND(IF(battle_losses > 0, (battle_wins / battle_losses), battle_wins), 2) `value`
FROM ranking
WHERE tourney_id = _tourney_id_param
ORDER BY `value` desc limit _rank_limit
);

WHEN 7 THEN
replace into leaderboard
(
SELECT _tourney_id_param tourney_id, account_id, 7 leaderboard_type, @rank:=@rank+1 rank, NULL, 
	(battle_wins+battle_losses) `value`
FROM ranking
WHERE tourney_id = _tourney_id_param
ORDER BY `value` desc limit _rank_limit
);
END CASE;

update leaderboard join auth_account using (account_id) set leaderboard.display_name=auth_account.display_name 
WHERE 
	tourney_id = _tourney_id_param 
	and leaderboard_type=_leaderboard_type_param;

END $$

DELIMITER ;