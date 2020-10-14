namespace Outreach {
  class Serializer{
    dictionary suffix = {
      {"uuid", "\x01"},
      {"issuer", "\x02"},
      {"resolver", "\x03"},
      {"action", "\x04"},
      {"payload", "\x05"},
      {"time", "\x06"},
      {"timeIssued", "\x07"},
      {"ref", "\x08"}
    };
    dictionary suffixReversed = PrepareReversedSuffix(suffix);

    /* 将 dictionary 序列化为字符串 */
    string Serialize(dictionary@ data){
      string content = "";
      array<string> keys = data.getKeys();
      for(uint i=0; i<keys.length(); i++){
        if(suffix.exists(keys[i])){
          content += string(data[keys[i]]);
          content += string(suffix[keys[i]]);
        }
      }
      return content;
    }

    /* 将字符串反序列化为 dictionary */
    dictionary@ Deserialize(string content){
      dictionary data;
      string lastValue = "";
      for(uint i=0; i<content.Length(); i++){
        char currentPos = content[i];
        if(suffixReversed.exists(currentPos)){
          string key = string(suffixReversed[currentPos]);
          data[key] = lastValue;
          lastValue = "";
        }else{
          lastValue += currentPos;
        }
      }
      return @data;
    }

    private dictionary@ PrepareReversedSuffix(dictionary@ original){
      dictionary reversed;
      array<string> keys = original.getKeys();
      for(uint i=0; i<keys.length(); i++){
        string key = string(keys[i]);
        string value = string(original[key]);
        reversed[value] = key;
      }
      return @reversed;
    }
  }

  Serializer g_Serializer;
}