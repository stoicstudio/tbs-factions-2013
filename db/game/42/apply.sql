ALTER TABLE `battle_party` ADD COLUMN `elo_result` INT(4) NULL  AFTER `timer` ;

ALTER TABLE `account_info` ADD COLUMN `login_count` INT(4) NOT NULL  AFTER `renown_boost_expiry` ;

ALTER TABLE `session` ADD COLUMN `login_count` INT(4) NOT NULL  AFTER `keepalive_date` ;

ALTER TABLE `session_history` ADD COLUMN `login_count` INT(4) NOT NULL AFTER `session_timeout` ;

UPDATE account_info SET account_info.login_count=(SELECT COUNT(session_key) FROM session_history WHERE session_history.user_id = account_info.account_id);

update session_history
join 
(select t1.session_key as session_key, COUNT(distinct t2.session_key) as login_count
FROM session_history as t1
join session_history as t2
ON (t1.session_start >= t2.session_start AND t1.user_id = t2.user_id)
group by t1.session_key) tmp_session_login_counts
on session_history.session_key=tmp_session_login_counts.session_key
SET session_history.login_count=tmp_session_login_counts.login_count;

