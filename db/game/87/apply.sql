create table battle_party_history LIKE battle_party;
INSERT INTO battle_party_history select * from battle_party;
delete from battle_party;