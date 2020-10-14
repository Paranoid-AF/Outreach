#include "../Constants/FilePaths"
#include "../Constants/Common"
#include "../Utils/File"
#include "../Utils/Toolkits"
#include "Serializer"
#include "Callback"
namespace Outreach {
  class Service {
    private string serviceName = "";
    private dictionary actionHandlers; // stores action-functions
    
    private dictionary callbackStack; // stores the Callback class

    private CScheduledFunction@ taskReader = null;

    private double detectionInterval = CONF_DETECTION_INTERVAL;
    private int requestCounter = 0;

    Service(string serviceName){
      bool isNameLegal = true;

      /* 检查服务名是否已经存在 */
      File@ file = g_FileSystem.OpenFile(CONF_STORAGE_ROOT_PATH + "/" + CONF_SERVICE_LIST_NAME, OpenFile::READ);
      if(file !is null && file.IsOpen()){
        while(!file.EOFReached()){
          string sLine;
          file.ReadLine(sLine);
          if(sLine == serviceName){
            isNameLegal = false;
          }
        }
        file.Close();
      }
      
      if(isNameLegal){
        /* 向 services.list 写入服务名 */
        @file = g_FileSystem.OpenFile(CONF_STORAGE_ROOT_PATH + "/" + CONF_SERVICE_LIST_NAME, OpenFile::APPEND);
        if(file !is null && file.IsOpen()){
          file.Write(serviceName + "\n");
          file.Close();
        }
      }
      this.serviceName = serviceName;
      /* 清理队列文件 */
      g_FileSystem.RemoveFile(CONF_SERVICES_PATH + ".task");
      g_FileSystem.RemoveFile(CONF_SERVICES_PATH + ".rslt");
      CreateEmptyFile(CONF_SERVICES_PATH + "/" + serviceName + ".task");
      CreateEmptyFile(CONF_SERVICES_PATH + "/" + serviceName + ".rslt");
      @taskReader = g_Scheduler.SetInterval(@this, "Detection", detectionInterval, g_Scheduler.REPEAT_INFINITE_TIMES);
    }

    private void Detection(){
      bool timerRemoved = false;
      if(ProcessTask()){
        CreateEmptyFile(CONF_SERVICES_PATH + "/" + serviceName + ".task");
      }
      if(ProcessResult()){
        CreateEmptyFile(CONF_SERVICES_PATH + "/" + serviceName + ".rslt");
      }
      if(@taskReader is null){
        @taskReader = g_Scheduler.SetInterval(@this, "Detection", detectionInterval, g_Scheduler.REPEAT_INFINITE_TIMES);
      }
    }

    private bool ProcessTask(){
      bool operated = false;
      // 读取 task
      File@ file = g_FileSystem.OpenFile(CONF_SERVICES_PATH + "/" + serviceName + ".task", OpenFile::READ);
      if(file !is null && file.IsOpen()){
        while(!file.EOFReached()){
          // 解析 task
          string sLine;
          file.ReadLine(sLine);
          dictionary taskInfo = g_Serializer.Deserialize(sLine);
          // 处理 task
          if(sLine != "" && DictionaryKeyIntegrityCheck(taskInfo, { "uuid", "issuer", "action", "time", "payload" })){
            StopTimer();
            // 执行 task
            Reflection::ReturnValue@ result = ExecuteAction(string(taskInfo["action"]), @taskInfo);
            if(@result != null){
              string payload = "";
              if(result.HasReturnValue()){
                result.ToAny().retrieve(payload);
              }
              dictionary output = {
                { "uuid", string(taskInfo["uuid"])},
                { "resolver", serviceName},
                { "action", string(taskInfo["action"])},
                { "time", string(UnixTimestamp())},
                { "timeIssued", string(taskInfo["time"])},
                { "payload", payload},
                { "ref", string(taskInfo["payload"])}
              };
              AppendLine(CONF_SERVICES_PATH + "/" + string(taskInfo["issuer"]) + ".rslt", g_Serializer.Serialize(output));
              operated = true;
            }
          }
        }
        file.Close();
      }
      return operated;
    }

    private bool ProcessResult(){
      bool operated = false;
      // 读取 result
      File@ file = g_FileSystem.OpenFile(CONF_SERVICES_PATH + "/" + serviceName + ".rslt", OpenFile::READ);
      if(file !is null && file.IsOpen()){
        while(!file.EOFReached()){
          // 解析 result
          string sLine;
          file.ReadLine(sLine);
          dictionary resultInfo = g_Serializer.Deserialize(sLine);
          // 处理 result
          if(sLine != "" && DictionaryKeyIntegrityCheck(resultInfo, { "uuid", "resolver", "action", "time", "timeIssued", "payload", "ref" })){
            StopTimer();
            // 执行 result 对应的回调
            string uuid = string(resultInfo["uuid"]);
            if(callbackStack.exists(uuid)){
              Callback@ callback = cast<Callback@>(callbackStack[uuid]);
              if(@callback !is null){
                callback.Execute(resultInfo);
              }
              callbackStack.delete(uuid);
              operated = true;
            }
          }
        }
        file.Close();
      }
      return operated;
    }

    string GetServiceName(){
      return serviceName;
    }

    bool Dispatch(string resolver, string action, string payload, Callback@ callback = null){
      bool resolverExists = false;
      File@ file = g_FileSystem.OpenFile(CONF_STORAGE_ROOT_PATH + "/" + CONF_SERVICE_LIST_NAME, OpenFile::READ);
      if(file !is null && file.IsOpen()){
        while(!file.EOFReached()){
          string sLine;
          file.ReadLine(sLine);
          if(sLine == resolver){
            resolverExists = true;
          }
        }
        file.Close();
      }

      if(!resolverExists){
        return false;
      }

      string uuid = GenerateUuid(resolver);
      dictionary content = {
        {"uuid", uuid},
        {"issuer", serviceName},
        {"action", action},
        {"time", string(UnixTimestamp())},
        {"payload", payload}
      };

      callbackStack[uuid] = @callback;

      string writtenContent = g_Serializer.Serialize(content);
      AppendLine(CONF_SERVICES_PATH + "/" + resolver + ".task", writtenContent);

      return true;
    }

    private void StopTimer(){
      if(@taskReader != null){
        g_Scheduler.RemoveTimer(@taskReader);
        @taskReader = null;
      }
    }

    /* 获取 Action 列表 */
    array<string> GetActions(){
      return actionHandlers.getKeys();
    }

    /* 注册 Action */
    bool RegisterAction(string actionName, string functionName){
      if(actionHandlers.exists(actionName)){
        return false;
      }else{
        Reflection::Function@ actionFunc = Reflection::g_Reflection.Module.FindGlobalFunction(functionName);
        if(@actionFunc is null){
          return false;
        }
        @actionHandlers[actionName] = @actionFunc;
        return true;
      }
    }

    /* 修改 Action */
    bool OverrideAction(string actionName, string functionName){
      if(actionHandlers.exists(actionName)){
        Reflection::Function@ actionFunc = Reflection::g_Reflection.Module.FindGlobalFunction(functionName);
        if(@actionFunc is null){
          return false;
        }
        @actionHandlers[actionName] = @actionFunc;
        return true;
      }else{
        return false;
      }
    }

    /* 移除 Action */
    bool RemoveAction(string actionName){
      return actionHandlers.delete(actionName);
    }

    /* 执行 Action */  
    private Reflection::ReturnValue@ ExecuteAction(string actionName, dictionary@ data){
      if(actionHandlers.exists(actionName)){
        Reflection::Function@ actionFunc = cast<Reflection::Function@>(actionHandlers[actionName]);

        if(@actionFunc is null){
          return null;
        }

        Reflection::Arguments@ args = Reflection::Arguments(data);
        return actionFunc.Call(args);
        
      }else{
        return null;
      }
    }
    
    private string GenerateUuid(string targetService){
      string timeStamp = string(UnixTimestamp());
      string result = string(requestCounter) + "-" + serviceName + "-" + targetService + "-" + string(timeStamp);
      requestCounter++;
      return Base64Encode(result);
    }
  }
}