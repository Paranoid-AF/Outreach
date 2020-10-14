namespace Outreach {
  class CallbackResult {
    dictionary@ result;
    void Set(dictionary@ result){
      @this.result = @result;
    }
    dictionary@ Get(){  
      return result;
    }
  }
}