package game.session
{
	import engine.core.fsm.Fsm;
	import engine.core.http.HttpAction;
	import engine.core.http.HttpCommunicator;
	import engine.core.http.HttpJsonAction;
	import engine.core.util.Enum;
	import engine.session.Chat;
	import engine.session.ChatMsg;
	import engine.session.ChatRoomMsg;
	import engine.session.Credentials;
	import engine.session.ServerStatusData;
	import engine.session.Session;
	import engine.session.TxnGet;

	import game.cfg.GameAmbienceDef;
	import game.cfg.GameConfig;
	import game.gui.IGuiDialog;
	import game.session.actions.GameLocationTxn;
	import game.session.actions.LogoutTxn;
	import game.session.actions.VsType;
	import game.session.states.AccountInfoState;
	import game.session.states.AssembleHeroesState;
	import game.session.states.AuthBuildMismatchState;
	import game.session.states.AuthFailedState;
	import game.session.states.AuthState;
	import game.session.states.FactionsState;
	import game.session.states.FlashState;
	import game.session.states.FriendLobbyState;
	import game.session.states.GreatHallState;
	import game.session.states.HallOfValorState;
	import game.session.states.LoginQueueState;
	import game.session.states.MainMenuState;
	import game.session.states.MapCampLoadState;
	import game.session.states.MapCampState;
	import game.session.states.MeadHouseState;
	import game.session.states.OfflineState;
	import game.session.states.PreAuthState;
	import game.session.states.ProvingGroundsState;
	import game.session.states.ReadyState;
	import game.session.states.SagaState;
	import game.session.states.SceneLoadState;
	import game.session.states.SceneState;
	import game.session.states.SkirmishState;
	import game.session.states.StartState;
	import game.session.states.TownLoadState;
	import game.session.states.TownState;
	import game.session.states.VersusCancelState;
	import game.session.states.VersusFailState;
	import game.session.states.VersusFindMatchState;
	import game.session.states.VersusMatchedState;
	import game.session.states.VideoQueueState;
	import game.session.states.VideoState;
	import game.session.states.VideoTutorial1State;
	import game.session.states.VideoTutorial2State;
	import game.session.states.tutorial.RegisterTutorialStates;

	import tbs.srv.battle.data.BattleNotification;
	import tbs.srv.data.FriendData;
	import tbs.srv.data.FriendOnlineData;
	import tbs.srv.data.GameLocationData;
	import tbs.srv.data.PurchasableUnitsData;
	import tbs.srv.data.VsQueueData;
	import tbs.srv.util.AchievementProgressData;
	import tbs.srv.util.CurrencyData;
	import tbs.srv.util.RenownMsg;
	import tbs.srv.util.SystemMsg;
	import tbs.srv.util.UnitAddData;
	import tbs.srv.util.UnlockData;

	public class GameFsm extends Fsm
	{
		public var config : GameConfig;
		public var _communicator : HttpCommunicator;
		public var credentials : Credentials;
		public var session : Session;
		public var chat : Chat;
		public var playersOnline : int;

		/**
		 *
		 * @param config
		 *
		 */
		public function GameFsm(config : GameConfig)
		{
			super("GameFsm", config.logger);
			this.config = config;
			this.credentials = new Credentials(config.username, config.options.accountChildNumber, config.gameServerUrl, GameConfig.PROTOCOL_VERSION, config.logger);

			useMsgQueue();

			registerState(StartState);
			registerState(PreAuthState);
			registerState(FactionsState);
			registerState(SagaState);
			registerState(AuthState);
			registerState(AuthBuildMismatchState);
			registerState(AuthFailedState);
			registerState(AccountInfoState);
			registerState(OfflineState);

			registerState(ReadyState);

			registerState(MainMenuState);
			registerState(TownState);
			registerState(TownLoadState);
			registerState(MapCampState);
			registerState(MapCampLoadState);
			registerState(SceneState);
			registerState(SceneLoadState);
			registerState(GreatHallState);
			registerState(MeadHouseState);
			registerState(HallOfValorState);
			registerState(LoginQueueState);
			registerState(SkirmishState);
			registerState(VersusFindMatchState);
			registerState(VersusCancelState);
			registerState(VersusMatchedState);
			registerState(ProvingGroundsState);
			registerState(AssembleHeroesState);
			registerState(VersusFailState);
			registerState(FriendLobbyState);
			registerState(VideoQueueState);
			registerState(FlashState);
			registerState(VideoState);
			registerState(VideoTutorial1State);
			registerState(VideoTutorial2State);

			registerTransition(OfflineState, ReadyState, TRANS_COMPLETE);
			registerTransition(StartState, PreAuthState, TRANS_COMPLETE);
			registerTransition(PreAuthState, AuthState, TRANS_COMPLETE);
			registerTransition(AuthBuildMismatchState, AccountInfoState, TRANS_COMPLETE);
			registerTransition(AuthBuildMismatchState, AuthFailedState, TRANS_FAILED);
			registerTransition(AuthState, AccountInfoState, TRANS_COMPLETE);
			registerTransition(AuthState, AuthFailedState, TRANS_FAILED);
			registerTransition(AuthFailedState, PreAuthState, TRANS_COMPLETE);
			registerTransition(AccountInfoState, ReadyState, TRANS_COMPLETE);
			registerTransition(ReadyState, MainMenuState, TRANS_COMPLETE);
			registerTransition(FactionsState, TownLoadState, TRANS_COMPLETE);

			registerTransition(VideoQueueState, VideoState, TRANS_COMPLETE);

//			registerTransition(BattleOfflineState, ScenarioLoadOfflineState, TRANS_COMPLETE);
//			registerTransition(BattleOfflineState, GameSelectState, TRANS_FAILED);

			registerTransition(SceneLoadState, SceneState, TRANS_COMPLETE);

			registerTransition(TownLoadState, TownState, TRANS_COMPLETE);

			registerTransition(MapCampLoadState, MapCampState, TRANS_COMPLETE);

			// this is a worst case fallback.  in genera l, subclasses should define different transitions
			registerTransition(SceneLoadState, TownLoadState, TRANS_FAILED);

//			registerTransition(PartySelectState, BattleState, TRANS_COMPLETE);
//			registerTransition(PartySelectState, BattleState, TRANS_COMPLETE);

			registerTransition(VersusFindMatchState, VersusMatchedState, TRANS_COMPLETE);
			registerTransition(VersusFindMatchState, VersusFailState, TRANS_FAILED);
			registerTransition(VersusMatchedState, SceneLoadState, TRANS_COMPLETE);
			registerTransition(VersusMatchedState, VersusFindMatchState, TRANS_FAILED);

			registerTransition(VideoTutorial1State, TownState, TRANS_COMPLETE);
			registerTransition(VideoTutorial2State, TownState, TRANS_COMPLETE);

			RegisterTutorialStates.register(this);

			initialState = StartState;

			_communicator = new HttpCommunicator(logger, credentials.gameServerUrl, txnProcessedCallback, txnPollCallback);

			session = new Session(_communicator, credentials);

			this.chat = new Chat(session, config.friends, config.logger);

		}

		public function get communicator() : HttpCommunicator
		{
			return session.communicator;
		}

		override protected function cleanup() : void
		{
			config.steamworks.SteamAPI_Shutdown();
			logout();
		}

		public function logout() : void
		{
			if (session.credentials.sessionKey)
			{
				var txn : LogoutTxn = new LogoutTxn(session.credentials, null, logger);
				session.credentials.sessionKey = null;
				txn.send(session.communicator);
				if (session.communicator)
				{
					session.communicator.connected = false;
				}
				session.credentials.offline = true;
			}
		}

		public function get currentGameState() : GameState
		{
			return current as GameState;
		}

		override public function handleOneMessage(msg : Object) : Boolean
		{
			if (!current)
			{
				return false;
			}

			if (config.factions)
			{
				if (config.factions.handleOneMessage(msg))
				{
					return true;
				}
			}

			if (msg["class"] == "tbs.srv.data.VsQueueData")
			{
				if (config.factions)
				{
					var vqd : VsQueueData = new VsQueueData().parseJson(msg, logger);
					var vst : VsType = Enum.parse(VsType, vqd.type, false) as VsType;
					//if (!vqd.account_id || vqd.account_id != credentials.userId)
					{
						config.factions.vsmonitor.updateEntry(vst, vqd.powers, vqd.counts);
					}
				}
				return true;
			}

			if (msg["class"] == "tbs.srv.util.AchievementProgressData")
			{
				const apd : AchievementProgressData = new AchievementProgressData;
				apd.parseJson(msg, logger);

				logger.debug("handleOneMessage: " + apd);
				// TODO update guis and whatnot
				return true;
			}

			if (msg["class"] == "tbs.srv.data.GameLocationData")
			{
				const gld : GameLocationData = new GameLocationData;
				gld.parseJson(msg, logger);
				config.friends.updateLocation(gld);
				return true;
			}
			else if (msg["class"] == "tbs.srv.data.FriendOnlineData")
			{
				const fod : FriendOnlineData = new FriendOnlineData;
				fod.parseJson(msg, logger);
				const onlineFriend : FriendData = config.friends.updateOnline(fod);
				if (onlineFriend)
				{
					const chatOnline : ChatMsg = new ChatMsg;
//					chatOnline.room = Chat.FRIEND_NOTIFICATION_ROOM;
					chatOnline.room = Chat.GLOBAL_ROOM;
					chatOnline.username = "FRIEND";
					if (fod.online)
					{
						chatOnline.msg = onlineFriend.display_name + " has logged in.";
					}
					else
					{
						chatOnline.msg = onlineFriend.display_name + " has logged out.";
					}
					chat.handleChatMsg(chatOnline);
				}
				return true;
			}
			else if (msg["class"] == "tbs.srv.data.FriendData")
			{
				const fd : FriendData = new FriendData;
				fd.parseJson(msg, logger);
				config.friends.addFriendData(fd);
				return true;
			}
			if (msg["class"] == "tbs.srv.data.FriendsData")
			{
				config.friends.parseJson(msg, logger);
				return true;
			}
			if (msg["class"] == "tbs.srv.data.PurchasableUnitsData")
			{
				const pusd : PurchasableUnitsData = new PurchasableUnitsData;
				pusd.parseJson(msg, logger);
				config.purchasableUnits.update(pusd);
				return true;
			}
			else if (msg["class"] == "tbs.srv.data.ServerStatusData")
			{
				var ssd : ServerStatusData = ServerStatusData.parse(msg);
				logger.debug("ServerStatusData: " + ssd);
				this.playersOnline = ssd.session_count;
				dispatchEvent(new GameFsmEvent(GameFsmEvent.PLAYERS_ONLINE));
				return true;
			}
			else if (msg["class"] == "tbs.srv.chat.ChatMsg")
			{
				var cm : ChatMsg = ChatMsg.parse(msg);
				chat.handleChatMsg(cm);
				return true;
			}
			else if (msg["class"] == "tbs.srv.chat.ChatRoomMsg")
			{
				const crm : ChatRoomMsg = new ChatRoomMsg;
				crm.parseJson(msg, logger);
				chat.handleChatRoomMsg(crm);
				return true;
			}
			else if (msg["class"] == "tbs.srv.util.SystemMsg")
			{
				var sm : SystemMsg = new SystemMsg;
				sm.parseJson(msg, logger);
				config.systemMessage.msg = sm.msg;
				return true;
			}
			else if (msg["class"] == "tbs.srv.battle.data.BattleNotification")
			{
				var bn : BattleNotification = new BattleNotification;
				bn.parseJson(msg, logger);
				// for now don't mention the battle stuff
				//					chat.handleChatMsg(bn.generateChatMsg());
				return true;
			}
			else if (msg["class"] == "tbs.srv.util.RenownMsg")
			{
				var rm : RenownMsg = new RenownMsg();
				rm.parseJson(msg, logger);

				if (rm.timestamp > lastRenownMsgTimestamp)
				{
					lastRenownMsgTimestamp = rm.timestamp;
					logger.debug("RenownMsg: " + rm);

					if (config.accountInfo)
					{
						config.accountInfo.legend.renown = rm.total;
					}

					if (config.factions)
					{
						config.factions.legend.renown = rm.total;
					}
				}
				else
				{
					logger.debug("RenownMsg IGNORE OLD: " + rm);
				}
				return true;
			}
			else if (msg["class"] == "tbs.srv.util.UnlockData")
			{
				var unlockData : UnlockData = new UnlockData();
				unlockData.parseJson(msg, logger);

				config.accountInfo.handleUnlock(unlockData);
				return true;
			}
			else if (msg["class"] == "tbs.srv.util.UnitAddData")
			{
				var unitAddData : UnitAddData = new UnitAddData();
				unitAddData.parseJson(msg, logger);

				config.legend.handleUnitAdd(unitAddData);
				return true;
			}
			else if (msg["class"] == "tbs.srv.util.CurrencyData")
			{
				var currencyData : CurrencyData = new CurrencyData();
				currencyData.parseJson(msg, logger);

				if (config.accountInfo)
				{
					config.accountInfo.handleCurrencyData(currencyData);
				}
				return true;
			}

			if (!super.handleOneMessage(msg))
			{
				if (msg.error_msg != undefined)
				{
					// nothing worth doing
					return true;
				}

				return false;
			}

			return true;
		}

		private var lastRenownMsgTimestamp : int;

		override public function startFsm(data : Object) : void
		{
			super.startFsm(data);
		}

		private function disconnectedDialogCallback(button : String) : void
		{
			disconnectingDialog = null;
			transitionTo(PreAuthState, current ? current.data : null);
		}

		private function maintenanceDialogCallback(button : String) : void
		{
			disconnectingDialog = null;
			config.context.appInfo.exitGame("Server Maintenance");
		}

		private var disconnectingDialog : IGuiDialog;

		private function txnProcessedCallback(txn : HttpAction) : void
		{
			// unauthorized
			if (txn.responseCode == 401)
			{
				if (currentClass != PreAuthState && currentClass != AuthState && currentClass != AuthFailedState)
				{
					txn.abort();
					if (!disconnectingDialog)
					{
						// drop back to the auth screen
						communicator.connected = false;
						session.credentials.offline = true;

						disconnectingDialog = config.gameGuiContext.createDialog();
						disconnectingDialog.openDialog("Disconnected", "Disconnected From Server", "OK", disconnectedDialogCallback);
					}
					return;
				}
			}
			else if (txn.isMaintenance)
			{
				// hacky, but i don't think Heroku offers anything more than this

				var maintenance : Boolean = txn.response.indexOf("Offline for Maintenance") >= 0;
				var rebooting : Boolean = txn.response.indexOf("game_rebooting") >= 0;

				if (maintenance || rebooting)
				{
					txn.abort();
					if (!disconnectingDialog)
					{
						// drop back to the auth screen
						communicator.connected = false;
						session.credentials.offline = true;

						disconnectingDialog = config.gameGuiContext.createDialog();

						if (maintenance)
						{
							disconnectingDialog.openDialog("Server Offline", "The Banner Saga is currently enjoying maintenance.\nCheck back in 5 minutes!", "OK", maintenanceDialogCallback);
						}
						else
						{
							disconnectingDialog.openDialog("Server Rebooting", "The Banner Saga is currently rebooting.\nCheck back in 5 minutes!", "OK", maintenanceDialogCallback);
						}
					}
					return;
				}
			}

			if (txn is HttpJsonAction)
			{
				var jtxn : HttpJsonAction = txn as HttpJsonAction;
				if (jtxn.jsonObject)
				{
					logger.debug("GameFsm INCOMING MSG " + current + ": " + jtxn.response);
					handleMessage(jtxn.jsonObject);
				}
			}

		}

		private function txnPollCallback() : HttpJsonAction
		{
			if (session.credentials.sessionKey && !session.credentials.offline)
			{
				return new TxnGet(session.credentials, null, logger);
			}

			return null;
		}

		public function updateGameLocation(location : String) : void
		{
			if (session.credentials.sessionKey && !session.credentials.offline)
			{
				const txn : GameLocationTxn = new GameLocationTxn(session.credentials, location, logger);
				txn.send(session.communicator);
			}

			const loc : Number = config.ambienceDef.getLocation(location);
			const rev : String = config.ambienceDef.getReverb(location);

			if (loc != GameAmbienceDef.INVALID_LOCATION)
			{
				config.soundSystem.ambience = loc;
				config.soundSystem.ambienceEnabled = config.globalPrefs.getPref(GameConfig.PREF_OPTION_SFX);
			}

			if (rev)
			{
				config.soundSystem.driver.reverbAmbientPreset(rev);
			}
		}
	}
}

