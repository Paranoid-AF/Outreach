#include "Outreach/main"
Outreach::Service@ serviceHub = null;
void PluginInit(){
  g_Module.ScriptInfo.SetAuthor("Paranoid_AF");
  g_Module.ScriptInfo.SetContactInfo("https://github.com/Paranoid-AF");
  @serviceHub = Outreach::Service("AnotherService");
  serviceHub.RegisterAction("kill", "killPlayer");
  serviceHub.Dispatch("quantum", "setname", "szPlayerName");
  g_Hooks.RegisterHook(Hooks::Player::ClientConnected, @onJoin);
}

string killPlayer(dictionary@ data){
  string targetName = string(data["payload"]);
	CBasePlayer@ findPlayer = null;
	for(int i = 0; i < g_Engine.maxClients; i++) {
		@findPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
    if(@findPlayer !is null){
      g_Game.AlertMessage(at_console, "[Outreach::ALERT] " + findPlayer.pev.netname + "\n");
      g_Game.AlertMessage(at_console, "[Outreach::ALERT] " + targetName + "\n");
      if(findPlayer.pev.netname == targetName){
        findPlayer.TakeDamage(findPlayer.edict().vars, findPlayer.edict().vars, 200, DMG_BULLET);
        break;
      }
    }
  }
  if(@findPlayer is null){
    return "mission failed";
  }else{
    return "eliminated";
  }
}

HookReturnCode onJoin(edict_t@ pEntity, const string& in szPlayerName, const string& in szIPAddress, bool& out bDisallowJoin, string& out szRejectReason){
  serviceHub.Dispatch("quantum", "setname", szPlayerName);
  g_Scheduler.SetTimeout("broadcast", 10);
  return HOOK_HANDLED;
}

void broadcast(){
  g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "Hi there, why don't you go to our website: http://localhost:8080");
}