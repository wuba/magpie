import 'package:jaguar/jaguar.dart';

class StaticAssetsInterceptor implements Interceptor{

  @override
  call(Context ctx) {
    if(ctx.uri.path.startsWith('/assets/data/')){
      ctx.response.headers.add('content-type', 'application/octet-stream');
    }
  }
}

