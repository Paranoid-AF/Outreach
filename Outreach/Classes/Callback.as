#include "CallbackResult"
namespace Outreach {
  class Callback {
    string uuid = "";
    Reflection::Function@ func = null;
    Reflection::Arguments@ args = null;
    CallbackResult@ result = null;
    
    Callback(string funcName, Reflection::Arguments@ args, CallbackResult@ result = null){
      @this.func = Reflection::g_Reflection.Module.FindGlobalFunction(funcName);;
      @this.args = @args;
      @this.result = @result;
    }

    void Execute(dictionary@ returnInfo){
      if(@result != null){
        result.Set(returnInfo);
      }
      this.func.Call(args);
    }
  }
}