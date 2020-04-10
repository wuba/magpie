import 'package:jaguar/jaguar.dart';

import '../utils/logger.dart';

class CommonBeforeInterceptor implements Interceptor{

  @override
  call(Context ctx) {
    LoggerUtil.i(
        'Req => Method: ${ctx.method} Url: ${ctx.uri} Param:${ctx.query}');
  }
}

