import 'package:jaguar/http/context/context.dart';

abstract class BaseController{

  route(String path,Context context);

  bool match(String path,String action){
    return path.endsWith(action);
  }
}
