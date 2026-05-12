ALTER TABLE `ranking`
CHANGE COLUMN `battle_wins` `battle_wins` INT(4) NOT NULL DEFAULT 0  , 
CHANGE COLUMN `battle_losses` `battle_losses` INT(4) NOT NULL DEFAULT 0  , 
CHANGE COLUMN `battle_elo` `battle_elo` INT(4) NOT NULL DEFAULT 1000  , 
CHANGE COLUMN `best_win_streak` `best_win_streak` INT(4) NOT NULL DEFAULT 0  , 
ADD COLUMN `friend_battles` INT(4) NOT NULL DEFAULT 0  AFTER `best_win_streak` ;
