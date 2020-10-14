# Outreach
This piece of experimental bloatware is an event-driven utility that allows you to make **your** magic happen asynchronously, and communicate across plugins or even external programs. But it's based on file I/O so it's meant to be unstable.

In general, it sucks.
## Configuration
Clone this repo, and copy both `Outreach` and `store` folder to your Sven Co-op's plugin folder.
Then, in your plugin, include this utility with:. 
```angelscript
#include "Outreach/main"
```
## Service
In fact, the actual role of communication is `Service`.  
To define a service, initialize it with:
```angelscript
Outreach::Service@ myService = Outreach::Service("myGloriousService");
```

If you are trying to initialize it globally, declare the Service reference globally with a `null` value instead:
```angelscript
Outreach::Service@ myService = null;
```
Then, initialize it in `PluginInit()`:
```angelscript
@myService = Outreach::Service("myGloriousService");
```

## Action
To enable the service to solve your real-world problem, you need to register actions for other services to call.

### Define an Action Function
First, you'll need to define a **global** function (due to some glitch of Sven Co-op, methods within objects are not supported), with an argument receiving a dictionary:
```angelscript
string myActionFunc(dictionary@ data){
  g_Game.AlertMessage(at_console, string(data["payload"]) + "\n");
  return "I have taken over the world!";
}
```
> (Based on your need, the return value could be `string` or `void`, but anything else is not allowed.)

The dictionary is going to contain the following information:
```angelscript
{"uuid", string},   // The unique call ID used by Outreach internally, not really useful here.
{"issuer", string}, // The name of the service which called this action.
{"action", string}, // Current action name, we'll be registering this later.
{"time", string},   // Timestamp when current action is actually called.
{"payload", string} // Value passed to call this action.
```

As you may have recognized, the actual value that's passed by the call is `payload`.

So, the `myActionFunc` that we declared previously will print out the passed value, then return "I have taken over the world!" back to the caller.

### Register Your Action
Now that you have made an action function, it's time to bind it to your service.
```angelscript
myService.RegisterAction("myAction", "myActionFunc");
```
Yep, it's that simple. The first argument is the name of the action, the latter is the action function name.

Now it could be called by other services. And you surely could register multiple actions on one service.

## Calling an Action
Actions must be called by services. So let's assume that you have already defined another service called `anotherService`. It could be defined within the same plugin, but could also be in another plugin.

### Call without Callback
You don't need a callback if you don't want to anything after the action has done its work, you could simply call it like this:
```angelscript
anotherService.Dispatch("myGloriousService", "myAction", "Paranoid_AF is a moron.");
```

### Call with Callback
If you need callback, you'll need to declare it first.

Here let's assume that you don't need the results returned by the action and your callback function does not have arguments.

Your callback function should look like this:
```angelscript
void myCallbackFunc(){
  g_Game.AlertMessage(at_console, "Hello world!\n");
}
```

Then declare a `Outreach::Callback` object:

```angelscript
Outreach::Callback@ callback = Outreach::Callback("myCallbackFunc");
// The argument in constructor is your callback function's name.
```

Then append its reference as the last argument in `Dispatch`:
```angelscript
anotherService.Dispatch("myGloriousService", "myAction", "Freeman you fool!", @callback);
```

### Call with Callback that Has Arguments
If you need to pass arguments to your callback function:
```angelscript
void myCallbackFunc(string quote, int quoteId){
  g_Game.AlertMessage(at_console, "Hello world!\n");
  g_Game.AlertMessage(at_console, "[Quote #" + string(quoteId) + "] " + quote + "\n");
}
```
Then declare a `Reflection::Arguments` object first:
```angelscript
Reflection::Arguments@ myArg = Reflection::Arguments("We are nothing.", 1337);
```
And append its reference to `Outreach::Callback` constructor:
```angelscript
Outreach::Callback@ callback = Outreach::Callback("myCallbackFunc", @myArg);
```

### Call with Callback that Receives Results
If you need the result from the action, you'll need to initialize a `Outreach::CallbackResult` object first:
```angelscript
Outreach::CallbackResult@ result = Outreach::CallbackResult();
```
In order to make use of it, your callback function should also contain a argument that receives a `Outreach::CallbackResult` reference:
```angelscript
void myCallbackFunc(Outreach::CallbackResult@ resultReceived){
  dictionary@ obeyTheServer = resultReceived.Get(); // You need to use Get() method to fetch the result dictionary.
  g_Game.AlertMessage(at_console, "[PlayerInfo] It's time to " + obeyTheServer["payload"] + "\n");
}
```
Please note that you need to use `Get()` method of `Outreach::CallbackResult` to get the actual result **dictionary**, and it looks like this:
```angelscript
{ "uuid", string},       // The unique call ID used by Outreach internally, not really useful here.
{ "resolver", string},   // The service name where the called action is located. 
{ "action", string},     // Original action name that was called.
{ "time", string},       // Timestamp when the action function has finished execution.
{ "timeIssued", string}, // Timestamp when the action was called.
{ "payload", string},    // The return value from the action function.
{ "ref", string}         // The original payload when calling the action.
```
> If the ***action*** function has a `void` return type, then **payload** here will be an empty string - "".

Just append your `Outreach::CallbackResult` object's reference to `Reflection::Arguments` and you're ready to go:
```angelscript
Reflection::Arguments@ myArg = Reflection::Arguments(@result);
```

## Conclusion
Yes, this utility is very annoying to use, but that's the only solution I have here.
There are many drawbacks:
- It's based on file I/O, so the performance could be questionable - and I haven't tested it yet.
- Again, as it's based on file I/O, there could be some conflicts, which will result in loss of action call.

In order to make it more "atomic", you should create one `Service` for every single actual feature in your script when calling actions from other services.

Still, this is experimental, use it at your own risk.

## Expansions
So as we've talked above, you could even communicate with external programs. See [Outreach-Ext](https://github.com/Paranoid-AF/Outreach-Ext) for further information.
