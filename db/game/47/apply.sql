update
battle_party as t1
join
(select vs_find.session_key, vs_find.vs_battle_id as battle_id, vs_find.account_id from vs_find where vs_find.vs_battle_id is not null) tx
on tx.battle_id = t1.battle_id and tx.account_id = tx.account_id
set
t1.session_key=tx.session_key
where t1.session_key is null;

