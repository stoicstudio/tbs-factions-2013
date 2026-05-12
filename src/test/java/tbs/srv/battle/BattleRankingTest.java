package tbs.srv.battle;

import org.junit.Assert;
import org.junit.Test;

public class BattleRankingTest {

	@Test
	public void test() {
		Assert.assertEquals(1016, BattleRanking.calculateNewElo(1000, 1000, 1));
		Assert.assertEquals(984, BattleRanking.calculateNewElo(1000, 1000, 0));

		Assert.assertEquals(2332, BattleRanking.calculateNewElo(2332, 1032, 1));
		Assert.assertEquals(1032, BattleRanking.calculateNewElo(1032, 2332, 0));

		
		// tirean tests
		Assert.assertEquals(1031, BattleRanking.calculateNewElo(1016, 1000, 1));
		Assert.assertEquals(1045, BattleRanking.calculateNewElo(1032, 984, 1));
		
		Assert.assertEquals(1335, BattleRanking.calculateNewElo(1364, 930, 0));
		Assert.assertEquals(1339, BattleRanking.calculateNewElo(1335, 1010, 1));
		Assert.assertEquals(1323, BattleRanking.calculateNewElo(1351, 994, 0));
		Assert.assertEquals(1308, BattleRanking.calculateNewElo(1335, 1010, 0));

	}

	@Test
	public void testK() {
		Assert.assertEquals(32, BattleRanking.getEloKFactor(1000), 0.0001);
		Assert.assertEquals(32, BattleRanking.getEloKFactor(1500), 0.0001);
		Assert.assertEquals(32, BattleRanking.getEloKFactor(2000), 0.0001);
		Assert.assertEquals(32, BattleRanking.getEloKFactor(2100), 0.0001);
		Assert.assertEquals(32 - (0.333333 * 16), BattleRanking.getEloKFactor(2200), 0.0001);
		Assert.assertEquals(32 - (0.666666 * 16), BattleRanking.getEloKFactor(2300), 0.0001);
		Assert.assertEquals(16, BattleRanking.getEloKFactor(2400), 0.0001);
		Assert.assertEquals(16, BattleRanking.getEloKFactor(2500), 0.0001);
	}

}
