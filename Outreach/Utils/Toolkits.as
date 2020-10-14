string Base64Encode(string original){
  string base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  string result = "";
  string padding = "";
  if(original.Length() > 0 && original.Length() < 3){
    for(uint i=0; i<(3 - original.Length()); i++){
      original += "\0";
      padding += "=";
    }
  }
  for(uint i=0; i<original.Length(); i+=3){
    if(i>0 && (i/3*4)%76 == 0){
      result += "\n";
    }
    uint32 number = uint32(original[i]) << 16;
    if(i + 1 < original.Length()){
      number += uint32(original[i+1]) << 8;
    }
    if(i + 2 < original.Length()){
      number += uint32(original[i+2]);
    }
    array<int> division = {
      (number >>> 18) & 63,
      (number >>> 12) & 63,
      (number >>> 6) & 63,
      number & 63,
    };
    
    result += string(base64Chars[division[0]]) + string(base64Chars[division[1]]) + string(base64Chars[division[2]]) + string(base64Chars[division[3]]);
  }
  return result.SubString(0, result.Length() - padding.Length()) + padding;
}