void CreateEmptyFile(string path){
  File@ file = g_FileSystem.OpenFile(path, OpenFile::WRITE);
  if(file !is null && file.IsOpen()){
    file.Write("");
    file.Close();
  }
}

bool DictionaryKeyIntegrityCheck(dictionary@ dict, array<string>@ targetKeys){
  bool check = true;
  for(uint i=0; i<targetKeys.length(); i++){
    if(!dict.exists(targetKeys[i])){
      check = false;
    }
  }
  return check;
}

void AppendLine(string path, string content){
  File@ file = g_FileSystem.OpenFile(path, OpenFile::APPEND);
  if(file !is null && file.IsOpen()){
    file.Write(content + "\n");
    file.Close();
  }
}
