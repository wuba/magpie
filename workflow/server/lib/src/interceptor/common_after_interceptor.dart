import 'package:jaguar/jaguar.dart';

import '../utils/logger.dart';

class CommonAfterInterceptor implements Interceptor{

  @override
  call(Context ctx) {
    LoggerUtil.i('Response => Url: ${ctx.uri} Response:${ctx.response.value}');
    ctx.response.headers.add('Access-Control-Allow-Origin', '*'); //添加跨域支持
  }
}

